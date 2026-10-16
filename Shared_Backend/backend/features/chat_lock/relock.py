from ._shared import auth,bp,g,jsonify,member,run

@bp.post('/api/chats/<int:cid>/relock')
@auth
def relock(cid):
    member(cid,allow_locked=True)
    run('DELETE FROM lock_grants WHERE token=? AND chat_id=?',(g.session_token,cid))
    return jsonify(ok=True)
