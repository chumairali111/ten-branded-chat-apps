from ._shared import abort, auth, bp, g, jsonify, request, run

@bp.patch('/api/profile')
@auth
def update():
    d=request.get_json();name=str(d.get('name','')).strip();about=str(d.get('about',''))
    if not 1<=len(name)<=80 or len(about)>140: abort(400)
    run('UPDATE users SET name=?,about=? WHERE id=?',(name,about,g.uid));return jsonify(ok=True)
