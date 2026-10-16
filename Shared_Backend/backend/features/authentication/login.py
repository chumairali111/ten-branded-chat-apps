from ._shared import abort, bp, check_password_hash, establish, one, request, run, time

@bp.post('/api/login')
def login():
    d=request.get_json();username=str(d.get('username','')).lower().strip();password=d.get('password','')
    if not isinstance(password,str) or len(password)>128: abort(400)
    a=one('SELECT * FROM login_attempts WHERE username=?',(username,))
    if a and a['locked_until']>time.time(): abort(429,description='Too many attempts; retry in 15 minutes')
    u=one('SELECT * FROM users WHERE username=?',(username,))
    if not u or not check_password_hash(u['password'],password):
        count=(a['count'] if a and a['locked_until']==0 else 0)+1
        run('INSERT OR REPLACE INTO login_attempts VALUES(?,?,?)',(username,count,time.time()+900 if count>=5 else 0))
        abort(401,description='Invalid username or password')
    run('DELETE FROM login_attempts WHERE username=?',(username,))
    return establish(u['id'],str(d.get('device_name') or 'Browser')[:80],str(d.get('platform') or 'web')[:20])
