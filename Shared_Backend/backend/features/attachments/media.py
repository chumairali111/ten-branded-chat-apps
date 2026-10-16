from ._shared import auth, bp, g, jsonify, member, preference, rows

@bp.get('/api/chats/<int:cid>/media')
@auth
def media(cid):
    member(cid);p=preference(cid);import time
    result=rows('SELECT f.id,f.name,f.mime,f.size,m.id message_id FROM files f JOIN messages m ON m.file_id=f.id WHERE f.chat_id=? AND m.deleted=0 AND m.created>? AND (m.expires IS NULL OR m.expires>?) AND m.id NOT IN (SELECT message_id FROM hidden_messages WHERE user_id=?)',(cid,p['cleared'],time.time(),g.uid))
    return jsonify(files=result,total_bytes=sum(f['size'] for f in result))
