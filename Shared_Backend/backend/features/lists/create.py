from ._shared import abort, auth, bp, g, jsonify, request, run

@bp.post('/api/lists')
@auth
def create():
    name=str(request.get_json().get('name','')).strip()[:40]
    if not name:abort(400)
    return jsonify(id=run('INSERT INTO lists(user_id,name) VALUES(?,?)',(g.uid,name)))
