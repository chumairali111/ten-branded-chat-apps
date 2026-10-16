from ._shared import ALLOWED, Path, abort, auth, bp, current_app, g, jsonify, member, one, request, run, secure_filename, uuid

@bp.post('/api/chats/<int:cid>/files')
@auth
def upload(cid):
    m=member(cid);c=one('SELECT admin_only FROM chats WHERE id=?',(cid,))
    if c['admin_only'] and m['role']!='admin':abort(403)
    f=request.files.get('file')
    if not f:abort(400)
    name=secure_filename(f.filename or '')[:150];ext=name.rsplit('.',1)[-1].lower()
    if ext not in ALLOWED:abort(400,description='Unsupported file type')
    fid=uuid.uuid4().hex;path=Path(current_app.config['UPLOADS'])/fid;f.save(path)
    run('INSERT INTO files VALUES(?,?,?,?,?,?,?)',(fid,cid,g.uid,name,ALLOWED[ext],path.stat().st_size,str(path)))
    return jsonify(id=fid,name=name,mime=ALLOWED[ext])
