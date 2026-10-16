from ._shared import abort, auth, bp, check_password_hash, g, jsonify, member, one, request, run, time

@bp.post('/api/chats/<int:cid>/unlock')
@auth
def unlock(cid):
    member(cid,allow_locked=True);password=str(request.get_json().get('password',''))[:128]
    a=one('SELECT * FROM login_attempts WHERE username=?',('unlock-'+str(g.uid),))
    if a and a['locked_until']>time.time():abort(429,description='Too many attempts; retry in 15 minutes')
    if not check_password_hash(one('SELECT password FROM users WHERE id=?',(g.uid,))['password'],password):
        count=(a['count'] if a and a['locked_until']==0 else 0)+1
        run('INSERT OR REPLACE INTO login_attempts VALUES(?,?,?)',('unlock-'+str(g.uid),count,time.time()+900 if count>=5 else 0));abort(403,description='Incorrect password')
    run('DELETE FROM login_attempts WHERE username=?',('unlock-'+str(g.uid),))
    run('INSERT OR REPLACE INTO lock_grants VALUES(?,?,?)',(g.session_token,cid,time.time()+300));return jsonify(ok=True)
