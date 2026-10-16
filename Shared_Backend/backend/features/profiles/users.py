from ._shared import auth, bp, g, jsonify, request, rows

@bp.get('/api/users')
@auth
def users():
    q='%'+request.args.get('q','')[:80]+'%'
    return jsonify(users=rows('SELECT id,username,name,about,avatar,last_seen FROM users WHERE id<>? AND (name LIKE ? OR username LIKE ?) LIMIT 100',(g.uid,q,q)))
