from ._shared import abort, auth, bp, g, jsonify, one, request, run

@bp.route('/api/blocks/<int:uid>',methods=['POST','DELETE'])
@auth
def blocks(uid):
    if uid==g.uid or not one('SELECT id FROM users WHERE id=?',(uid,)): abort(400)
    if request.method=='POST': run('INSERT OR IGNORE INTO blocks VALUES(?,?)',(g.uid,uid))
    else: run('DELETE FROM blocks WHERE user_id=? AND blocked_id=?',(g.uid,uid))
    return jsonify(ok=True)
