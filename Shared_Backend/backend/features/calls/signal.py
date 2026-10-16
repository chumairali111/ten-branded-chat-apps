from ._shared import abort, auth, bp, call_access, g, json, jsonify, request, run, time

@bp.post('/api/calls/<int:call_id>/signals')
@auth
def signal(call_id):
    c=call_access(call_id)
    if c['state'] not in ['ringing','active']:abort(409)
    d=request.get_json();payload=json.dumps(d)
    if len(payload)>100000 or d.get('type') not in ['offer','answer','candidate']:abort(400)
    if d['type']=='offer' and g.uid!=c['caller']:abort(403)
    if d['type']=='answer' and g.uid!=c['callee']:abort(403)
    run('INSERT INTO call_signals(call_id,sender,payload,created) VALUES(?,?,?,?)',(call_id,g.uid,payload,time.time()));run('UPDATE calls SET updated=? WHERE id=?',(time.time(),call_id));return jsonify(ok=True)
