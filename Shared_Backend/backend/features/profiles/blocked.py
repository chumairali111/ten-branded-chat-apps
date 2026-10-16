from ._shared import auth, bp, g, jsonify, rows

@bp.get('/api/blocks')
@auth
def blocked(): return jsonify(users=rows('SELECT u.id,u.name FROM blocks b JOIN users u ON u.id=b.blocked_id WHERE b.user_id=?',(g.uid,)))
