from ._shared import auth, bp, g, jsonify, member, preference, run, time

@bp.post('/api/chats/<int:cid>/clear')
@auth
def clear(cid):
    member(cid);preference(cid);run('UPDATE preferences SET cleared=? WHERE chat_id=? AND user_id=?',(time.time(),cid,g.uid));return jsonify(ok=True)
