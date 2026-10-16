from ._shared import auth, bp, db, event, g, group, jsonify, secrets, time

@bp.post('/api/groups/<int:cid>/similar')
@auth
def similar(cid):
    c,_=group(cid);cx=db()
    with cx:
        new=cx.execute("INSERT INTO chats(kind,title,description,created_by,created,invite) VALUES('group',?,?,?,?,?)",(c['title']+' copy',c['description'],g.uid,time.time(),secrets.token_urlsafe(24))).lastrowid
        for m in cx.execute('SELECT user_id FROM members WHERE chat_id=?',(cid,)).fetchall():cx.execute('INSERT INTO members(chat_id,user_id,role) VALUES(?,?,?)',(new,m['user_id'],'admin' if m['user_id']==g.uid else 'member'))
    event(new,'Similar group created');return jsonify(id=new)
