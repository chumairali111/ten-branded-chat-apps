from ._shared import auth, bp, g, jsonify, member, one, preference, run

@bp.post('/api/chats/<int:cid>/read')
@auth
def read(cid):
    member(cid);preference(cid);last=one('SELECT MAX(id) id FROM messages WHERE chat_id=?',(cid,))['id'] or 0
    run('UPDATE preferences SET last_read=? WHERE chat_id=? AND user_id=?',(last,cid,g.uid));return jsonify(ok=True)
