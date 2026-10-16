from ._shared import auth, bp, g, jsonify, one, preference, rows, time

@bp.get('/api/chats')
@auth
def get_chats():
    result=[]
    for c in rows('SELECT c.*,m.role FROM chats c JOIN members m ON c.id=m.chat_id WHERE m.user_id=?',(g.uid,)):
        p=preference(c['id']);c.update(p)
        if c['kind']=='direct':
            u=one('SELECT u.id,u.name,u.about,u.avatar,u.last_seen FROM users u JOIN members m ON u.id=m.user_id WHERE m.chat_id=? AND u.id<>?',(c['id'],g.uid))
            if u: c['title']=u['name'];c['peer']=u
        c['last']=one('SELECT body,kind,created FROM messages WHERE chat_id=? AND created>? AND (expires IS NULL OR expires>?) AND id NOT IN (SELECT message_id FROM hidden_messages WHERE user_id=?) ORDER BY id DESC LIMIT 1',(c['id'],p['cleared'],time.time(),g.uid))
        c['unread']=one('SELECT COUNT(*) n FROM messages WHERE chat_id=? AND id>? AND sender<>? AND created>? AND deleted=0 AND (expires IS NULL OR expires>?) AND id NOT IN (SELECT message_id FROM hidden_messages WHERE user_id=?)',(c['id'],p['last_read'],g.uid,p['cleared'],time.time(),g.uid))['n']
        if p['locked']:
            c['last']=None;c['unread']=0;c['title']='Locked chat';c.pop('peer',None)
        result.append(c)
    result.sort(key=lambda c:c['last']['created'] if c['last'] else c['created'],reverse=True)
    return jsonify(chats=result)
