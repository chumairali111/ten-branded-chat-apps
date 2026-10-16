from ._shared import abort, auth, bp, event, g, jsonify, member, one, run

@bp.post('/api/communities/<int:coid>/groups/<int:cid>')
@auth
def attach(coid,cid):
    member(cid,True)
    if not one('SELECT id FROM communities WHERE id=? AND owner=?',(coid,g.uid)):abort(403)
    if not one("SELECT id FROM chats WHERE id=? AND kind='group'",(cid,)):abort(400)
    run('UPDATE chats SET community_id=? WHERE id=?',(coid,cid));event(cid,'Group added to community');return jsonify(ok=True)
