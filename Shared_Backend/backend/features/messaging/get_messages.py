from ._shared import auth, bp, g, jsonify, member, one, preference, rows, time

@bp.get('/api/chats/<int:cid>/messages')
@auth
def get_messages(cid):
    member(cid);p=preference(cid)
    msgs=rows('SELECT m.*,u.name sender_name,f.name file_name,f.mime,f.size FROM messages m JOIN users u ON u.id=m.sender LEFT JOIN files f ON f.id=m.file_id WHERE m.chat_id=? AND m.created>? AND (m.expires IS NULL OR m.expires>?) AND m.id NOT IN (SELECT message_id FROM hidden_messages WHERE user_id=?) ORDER BY m.id DESC LIMIT 500',(cid,p['cleared'],time.time(),g.uid))[::-1]
    for m in msgs:
        if m['deleted']:m.update(body='This message was deleted',file_id=None)
        m['reactions']=rows('SELECT user_id,emoji FROM reactions WHERE message_id=?',(m['id'],))
        m['starred']=bool(one('SELECT 1 FROM stars WHERE message_id=? AND user_id=?',(m['id'],g.uid)))
        m['read_by']=rows('SELECT user_id FROM preferences WHERE chat_id=? AND last_read>=? AND user_id<>?',(cid,m['id'],m['sender']))
        if m['reply_id']:
            reply=one('SELECT body,deleted FROM messages WHERE id=? AND chat_id=? AND created>? AND (expires IS NULL OR expires>?) AND id NOT IN (SELECT message_id FROM hidden_messages WHERE user_id=?)',(m['reply_id'],cid,p['cleared'],time.time(),g.uid));m['reply']=reply['body'][:120] if reply and not reply['deleted'] else 'Unavailable message'
    typing=rows('SELECT u.name FROM typing t JOIN users u ON u.id=t.user_id JOIN members mm ON mm.chat_id=t.chat_id AND mm.user_id=t.user_id WHERE t.chat_id=? AND t.user_id<>? AND t.until>?',(cid,g.uid,time.time()))
    return jsonify(messages=msgs,typing=typing)
