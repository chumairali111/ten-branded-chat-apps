from ._shared import abort, accessible, auth, bp, g, jsonify, request, run, time

@bp.patch('/api/messages/<int:mid>')
@auth
def edit(mid):
    m=accessible(mid);body=str(request.get_json().get('body','')).strip()
    if m['sender']!=g.uid or m['deleted']:abort(403)
    if time.time()-m['created']>900:abort(400,description='Edit window is 15 minutes')
    if not body or len(body)>10000:abort(400)
    run('UPDATE messages SET body=?,edited=1 WHERE id=?',(body,mid));return jsonify(ok=True)
