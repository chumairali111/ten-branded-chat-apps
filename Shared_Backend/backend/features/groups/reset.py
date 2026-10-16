from ._shared import auth, bp, group, jsonify, run, secrets

@bp.post('/api/groups/<int:cid>/invite/reset')
@auth
def reset(cid):
    group(cid,True);run('UPDATE chats SET invite=? WHERE id=?',(secrets.token_urlsafe(24),cid));return jsonify(ok=True)
