from ._shared import abort, accessible, auth, bp, g, jsonify, member, one, request, run, time

@bp.post('/api/chats/<int:cid>/messages')
@auth
def send(cid):
    m=member(cid);c=one('SELECT * FROM chats WHERE id=?',(cid,));d=request.get_json();body=str(d.get('body','')).strip();kind=d.get('kind','text');fid=d.get('file_id');reply=d.get('reply_id')
    if kind not in ['text','image','video','audio','document','location','contact']:abort(400)
    if c['admin_only'] and m['role']!='admin':abort(403,description='Only admins can send messages')
    if len(body)>10000 or (not body and not fid):abort(400,description='Empty message or message too long')
    if fid and not one('SELECT id FROM files WHERE id=? AND owner=? AND chat_id=?',(fid,g.uid,cid)):abort(400)
    if reply:
        target=accessible(reply)
        if target['chat_id']!=cid or target['deleted']:abort(400)
    if c['kind']=='direct':
        peer=one('SELECT user_id FROM members WHERE chat_id=? AND user_id<>?',(cid,g.uid))
        if peer and one('SELECT 1 FROM blocks WHERE (user_id=? AND blocked_id=?) OR (user_id=? AND blocked_id=?)',(g.uid,peer['user_id'],peer['user_id'],g.uid)):abort(403,description='Contact is blocked')
    created=time.time();mid=run('INSERT INTO messages(chat_id,sender,body,kind,file_id,reply_id,created,expires) VALUES(?,?,?,?,?,?,?,?)',(cid,g.uid,body,kind,fid,reply,created,created+c['disappear'] if c['disappear'] else None))
    run('DELETE FROM typing WHERE chat_id=? AND user_id=?',(cid,g.uid));return jsonify(id=mid),201
