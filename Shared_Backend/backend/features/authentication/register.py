from ._shared import abort, bp, establish, generate_password_hash, one, re, request, run

@bp.post('/api/register')
def register():
    d=request.get_json();username=str(d.get('username','')).lower().strip();name=str(d.get('name','')).strip();password=d.get('password','')
    if not re.fullmatch(r'[a-z0-9_]{3,30}',username) or not 1<=len(name)<=80 or not isinstance(password,str) or not 10<=len(password)<=128:
        abort(400,description='Use a 3–30 character username, name and 10–128 character password')
    if one('SELECT id FROM users WHERE username=?',(username,)): abort(409,description='Username already exists')
    uid=run('INSERT INTO users(username,name,password) VALUES(?,?,?)',(username,name,generate_password_hash(password)))
    return establish(uid,str(d.get('device_name') or 'Browser')[:80],str(d.get('platform') or 'web')[:20])
