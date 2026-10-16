from ._shared import abort, auth, bp, g, jsonify, one, run, time

@bp.post('/api/statuses/<int:sid>/view')
@auth
def view(sid):
    s=one('SELECT * FROM statuses WHERE id=? AND expires>?',(sid,time.time()))
    if not s:abort(404)
    if one('SELECT 1 FROM blocks WHERE (user_id=? AND blocked_id=?) OR (user_id=? AND blocked_id=?)',(g.uid,s['user_id'],s['user_id'],g.uid)):abort(403)
    if s['user_id']!=g.uid:
        run('INSERT OR IGNORE INTO status_views(status_id,user_id,viewed_at) VALUES(?,?,?)',(sid,g.uid,time.time()))
    return jsonify(ok=True)
