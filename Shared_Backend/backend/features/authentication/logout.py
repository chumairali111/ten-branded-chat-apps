from ._shared import auth, bp, g, jsonify, request, run

@bp.post('/api/logout')
@auth
def logout():
    run('DELETE FROM sessions WHERE token=?',(g.session_token,))
    r=jsonify(ok=True);r.delete_cookie('chat_session');return r
