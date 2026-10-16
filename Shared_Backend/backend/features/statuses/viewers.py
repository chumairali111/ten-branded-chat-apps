from ._shared import abort, auth, bp, g, jsonify, one, rows, time

@bp.get('/api/statuses/<int:sid>/viewers')
@auth
def viewers(sid):
    status=one('SELECT * FROM statuses WHERE id=? AND expires>?',(sid,time.time()))
    if not status: abort(404)
    if status['user_id']!=g.uid: abort(403,description='Only the story owner can see viewers')
    return jsonify(viewers=rows('SELECT u.id,u.name,u.username,u.avatar,v.viewed_at FROM status_views v JOIN users u ON u.id=v.user_id WHERE v.status_id=? AND v.user_id<>? ORDER BY v.viewed_at DESC',(sid,g.uid)))
