from ._shared import abort, accessible, auth, bp, g, jsonify, member, one, request, run, time

@bp.post('/api/messages/<int:mid>/forward')
@auth
def forward(mid):
    m=accessible(mid);dest=int(request.get_json().get('chat_id',0));role=member(dest);c=one('SELECT * FROM chats WHERE id=?',(dest,))
    source=one('SELECT advanced_privacy FROM chats WHERE id=?',(m['chat_id'],))
    if m['deleted'] or m['file_id']:abort(400,description='Only text forwarding is currently supported')
    if source['advanced_privacy']:abort(403,description='Forwarding disabled by advanced privacy')
    if c['admin_only'] and role['role']!='admin':abort(403)
    if c['kind']=='direct':
        peer=one('SELECT user_id FROM members WHERE chat_id=? AND user_id<>?',(dest,g.uid))
        if peer and one('SELECT 1 FROM blocks WHERE (user_id=? AND blocked_id=?) OR (user_id=? AND blocked_id=?)',(g.uid,peer['user_id'],peer['user_id'],g.uid)):abort(403)
    now=time.time();new=run('INSERT INTO messages(chat_id,sender,body,kind,created,expires) VALUES(?,?,?,?,?,?)',(dest,g.uid,'Forwarded: '+m['body'],m['kind'],now,now+c['disappear'] if c['disappear'] else None));return jsonify(id=new)
