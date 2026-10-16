from ._shared import abort, auth, bp, g, jsonify, member, one, request, run, time

@bp.post('/api/chats/<int:cid>/calls')
@auth
def start(cid):
    member(cid);c=one("SELECT * FROM chats WHERE id=? AND kind='direct'",(cid,))
    if not c:abort(400,description='Only one-to-one calls are implemented')
    peer=one('SELECT user_id FROM members WHERE chat_id=? AND user_id<>?',(cid,g.uid))
    if not peer:abort(400)
    if one('SELECT 1 FROM blocks WHERE (user_id=? AND blocked_id=?) OR (user_id=? AND blocked_id=?)',(g.uid,peer['user_id'],peer['user_id'],g.uid)):abort(403)
    if one("SELECT id FROM calls WHERE state IN ('ringing','active') AND updated>? AND (caller IN (?,?) OR callee IN (?,?))",(time.time()-60,g.uid,peer['user_id'],g.uid,peer['user_id'])):abort(409,description='A participant is already in a call')
    now=time.time();cid2=run('INSERT INTO calls(chat_id,caller,callee,video,created,updated) VALUES(?,?,?,?,?,?)',(cid,g.uid,peer['user_id'],int(bool(request.get_json().get('video'))),now,now))
    return jsonify(id=cid2)
