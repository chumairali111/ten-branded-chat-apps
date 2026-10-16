"""Authenticated media for stories and profile pictures; tokens never enter URLs."""
import time, uuid
from pathlib import Path
from flask import request, abort, g, current_app, jsonify, send_file
from werkzeug.utils import secure_filename
from ._shared import bp, ALLOWED, auth, one, run

@bp.post('/api/media/<purpose>')
@auth
def upload_shared(purpose):
    if purpose not in ('avatar','status'): abort(404)
    upload=request.files.get('file')
    if not upload: abort(400,description='Choose a file')
    name=secure_filename(upload.filename or '')[:150]
    mime=ALLOWED.get(name.rsplit('.',1)[-1].lower(),'')
    if not mime.startswith('image/') and not (purpose=='status' and mime.startswith('video/')):
        abort(400,description='Choose an image' if purpose=='avatar' else 'Choose an image or video')
    content=upload.read()
    limit=5*1024*1024 if purpose=='avatar' else 20*1024*1024
    if not content or len(content)>limit: abort(400,description='File is empty or exceeds upload limit')
    fid=uuid.uuid4().hex
    path=Path(current_app.config['UPLOADS'])/fid
    path.write_bytes(content)
    run('INSERT INTO shared_media VALUES(?,?,?,?,?,?,?,?)',(fid,g.uid,purpose,name,mime,len(content),str(path),time.time()))
    return jsonify(id=fid,mime=mime,name=name),201

@bp.get('/api/media/<fid>')
@auth
def download_shared(fid):
    media=one('SELECT * FROM shared_media WHERE id=?',(fid,))
    if not media: abort(404)
    owner=media['owner']
    if owner!=g.uid:
        if one('SELECT 1 FROM blocks WHERE (user_id=? AND blocked_id=?) OR (user_id=? AND blocked_id=?)',(g.uid,owner,owner,g.uid)): abort(403)
        if media['purpose']=='status':
            if not one('SELECT id FROM statuses WHERE media_id=? AND expires>?',(fid,time.time())): abort(404)
        elif not one('SELECT id FROM users WHERE id=? AND avatar=?',(owner,fid)): abort(404)
    if not Path(media['path']).is_file(): abort(404)
    return send_file(media['path'],mimetype=media['mime'],download_name=media['name'],conditional=True)
