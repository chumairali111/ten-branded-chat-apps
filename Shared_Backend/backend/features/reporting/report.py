from ._shared import abort, auth, bp, g, jsonify, member, request, run, time

@bp.post('/api/chats/<int:cid>/report')
@auth
def report(cid):
    member(cid);reason=str(request.get_json().get('reason','')).strip()[:1000]
    if not reason:abort(400)
    run('INSERT INTO reports(user_id,chat_id,reason,created) VALUES(?,?,?,?)',(g.uid,cid,reason,time.time()));return jsonify(ok=True)
