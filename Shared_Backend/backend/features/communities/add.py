from ._shared import abort, auth, bp, g, jsonify, request, run

@bp.post('/api/communities')
@auth
def add():
    d=request.get_json();name=str(d.get('name','')).strip()[:80]
    if not name:abort(400)
    return jsonify(id=run('INSERT INTO communities(owner,name,description) VALUES(?,?,?)',(g.uid,name,str(d.get('description',''))[:500])))
