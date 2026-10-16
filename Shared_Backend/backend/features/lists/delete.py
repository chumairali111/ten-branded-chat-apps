from ._shared import auth, bp, g, jsonify, run

@bp.delete('/api/lists/<int:lid>')
@auth
def delete(lid):run('DELETE FROM lists WHERE id=? AND user_id=?',(lid,g.uid));return jsonify(ok=True)
