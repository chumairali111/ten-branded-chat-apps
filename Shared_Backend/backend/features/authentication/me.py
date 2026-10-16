from ._shared import auth, bp, g, jsonify, one

@bp.get('/api/me')
@auth
def me(): return jsonify(user=one('SELECT id,username,name,about,avatar FROM users WHERE id=?',(g.uid,)),csrf=g.csrf)
