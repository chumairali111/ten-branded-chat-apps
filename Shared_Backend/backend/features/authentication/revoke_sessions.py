from ._shared import auth, bp, g, jsonify, run

@bp.delete('/api/sessions')
@auth
def revoke_sessions():
    run('DELETE FROM sessions WHERE user_id=? AND token<>?',(g.uid,g.session_token))
    return jsonify(ok=True)

@bp.delete('/api/sessions/<session_id>')
@auth
def revoke_session(session_id):
    run('DELETE FROM sessions WHERE user_id=? AND id=?',(g.uid,session_id))
    return jsonify(ok=True)
