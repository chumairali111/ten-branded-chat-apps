from ._shared import abort, auth, bp, check_password_hash, g, jsonify, member, one, preference, request, run, time

@bp.post('/api/chats/<int:cid>/lock')
@auth
def lock(cid):
    member(cid,allow_locked=True);d=request.get_json();p=preference(cid)
    u=one('SELECT password FROM users WHERE id=?',(g.uid,))
    if not check_password_hash(u['password'],str(d.get('password',''))[:128]):abort(403,description='Incorrect password')
    run('UPDATE preferences SET locked=? WHERE chat_id=? AND user_id=?',(int(bool(d.get('locked'))),cid,g.uid))
    run('DELETE FROM lock_grants WHERE chat_id=? AND token IN (SELECT token FROM sessions WHERE user_id=?)',(cid,g.uid))
    return jsonify(ok=True)
