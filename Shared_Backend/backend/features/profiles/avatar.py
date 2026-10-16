from ._shared import auth, bp, g, jsonify, run, one
from flask import request, abort

@bp.post('/api/profile/avatar')
@auth
def set_avatar():
    media_id=(request.get_json() or {}).get('media_id')
    if not one("SELECT id FROM shared_media WHERE id=? AND owner=? AND purpose='avatar'",(media_id,g.uid)):
        abort(400,description='Upload a profile picture first')
    run('UPDATE users SET avatar=? WHERE id=?',(media_id,g.uid))
    return jsonify(ok=True,avatar=media_id)

@bp.delete('/api/profile/avatar')
@auth
def remove_avatar():
    run("UPDATE users SET avatar='' WHERE id=?",(g.uid,))
    return jsonify(ok=True)
