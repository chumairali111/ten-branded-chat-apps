from ._shared import abort, auth, bp, call_access, g, jsonify, request, rows, run, time

@bp.get('/api/calls/<int:call_id>/signals')
@auth
def signals(call_id):
    c=call_access(call_id)
    if c['state'] in ['ringing','active']:run('UPDATE calls SET updated=? WHERE id=?',(time.time(),call_id))
    try:after=int(request.args.get('after',0))
    except ValueError:abort(400)
    return jsonify(state=c['state'],signals=rows('SELECT id,payload FROM call_signals WHERE call_id=? AND sender<>? AND id>? ORDER BY id',(call_id,g.uid,after)))
