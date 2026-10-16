from ._shared import auth, bp, g, jsonify, run

@bp.delete('/api/statuses/<int:sid>')
@auth
def delete(sid):run('DELETE FROM status_views WHERE status_id=? AND EXISTS(SELECT 1 FROM statuses WHERE id=? AND user_id=?)',(sid,sid,g.uid));run('DELETE FROM statuses WHERE id=? AND user_id=?',(sid,g.uid));return jsonify(ok=True)
