from ._shared import auth, bp, g, jsonify, member, run, time

@bp.post('/api/chats/<int:cid>/typing')
@auth
def typing(cid):
    member(cid);run('INSERT OR REPLACE INTO typing VALUES(?,?,?)',(cid,g.uid,time.time()+4));return jsonify(ok=True)
