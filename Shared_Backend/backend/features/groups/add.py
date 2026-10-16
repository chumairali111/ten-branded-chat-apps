from ._shared import abort, auth, bp, event, group, jsonify, one, request, run

@bp.post('/api/groups/<int:cid>/members')
@auth
def add(cid):
    group(cid,True);uid=int(request.get_json().get('user_id',0))
    if not one('SELECT id FROM users WHERE id=?',(uid,)):abort(404)
    run('INSERT OR IGNORE INTO members(chat_id,user_id) VALUES(?,?)',(cid,uid));event(cid,f'Member {uid} added');return jsonify(ok=True)
