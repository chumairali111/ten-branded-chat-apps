from ._shared import Path, abort, auth, bp, g, member, one, preference, request, send_file

@bp.get('/api/files/<fid>')
@auth
def download(fid):
    f=one('SELECT * FROM files WHERE id=?',(fid,))
    if not f:abort(404)
    member(f['chat_id']);p=preference(f['chat_id'])
    import time
    if not one('SELECT 1 FROM messages WHERE file_id=? AND deleted=0 AND created>? AND (expires IS NULL OR expires>?) AND id NOT IN (SELECT message_id FROM hidden_messages WHERE user_id=?)',(fid,p['cleared'],time.time(),g.uid)):abort(404)
    if not Path(f['path']).exists():abort(404)
    return send_file(f['path'],mimetype=f['mime'],download_name=f['name'],as_attachment=request.args.get('download')=='1' or not f['mime'].startswith(('image/','audio/','video/')))
