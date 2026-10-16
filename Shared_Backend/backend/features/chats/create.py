from ._shared import abort, auth, bp, db, event, g, jsonify, one, request, secrets, time

@bp.post('/api/chats')
@auth
def create():
    d=request.get_json();kind=d.get('kind','direct');ids=d.get('members',[])
    if kind not in ['direct','group'] or not isinstance(ids,list) or len(ids)>100: abort(400)
    try: ids=set(int(x) for x in ids)|{g.uid}
    except (ValueError,TypeError): abort(400)
    if kind=='direct' and len(ids)!=2: abort(400,description='Select exactly one contact')
    for uid in ids:
        if not one('SELECT id FROM users WHERE id=?',(uid,)): abort(400)
    if kind=='direct':
        peer=next(x for x in ids if x!=g.uid)
        if one('SELECT 1 FROM blocks WHERE (user_id=? AND blocked_id=?) OR (user_id=? AND blocked_id=?)',(g.uid,peer,peer,g.uid)): abort(403,description='Contact is blocked')
        existing=one("SELECT c.id FROM chats c JOIN members a ON c.id=a.chat_id JOIN members b ON c.id=b.chat_id WHERE c.kind='direct' AND a.user_id=? AND b.user_id=?",(g.uid,peer))
        if existing:return jsonify(id=existing['id'])
    title=str(d.get('title','New group')).strip()[:80]
    if not title:abort(400)
    cx=db()
    with cx:
        cid=cx.execute('INSERT INTO chats(kind,title,created_by,created,invite) VALUES(?,?,?,?,?)',(kind,title,g.uid,time.time(),secrets.token_urlsafe(24))).lastrowid
        for uid in ids: cx.execute('INSERT INTO members(chat_id,user_id,role) VALUES(?,?,?)',(cid,uid,'admin' if uid==g.uid else 'member'))
    event(cid,'Chat created');return jsonify(id=cid),201
