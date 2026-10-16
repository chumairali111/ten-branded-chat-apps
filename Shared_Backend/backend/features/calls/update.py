from ._shared import abort, auth, bp, call_access, g, jsonify, request, run, time

@bp.patch('/api/calls/<int:call_id>')
@auth
def update(call_id):
    c=call_access(call_id);state=request.get_json().get('state')
    if state not in ['active','ended','declined']:abort(400)
    if c['state'] not in ['ringing','active']:abort(409)
    if state in ['active','declined'] and g.uid!=c['callee']:abort(403)
    run('UPDATE calls SET state=?,updated=? WHERE id=?',(state,time.time(),call_id));return jsonify(ok=True)
