from ._shared import auth, bp, g, jsonify, rows, time

@bp.get('/api/statuses')
@auth
def get():
    return jsonify(statuses=rows("SELECT s.*,u.name,u.avatar,sm.mime,(SELECT COUNT(*) FROM status_views v WHERE v.status_id=s.id AND v.user_id<>s.user_id) views FROM statuses s JOIN users u ON u.id=s.user_id LEFT JOIN shared_media sm ON sm.id=s.media_id WHERE expires>? AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.user_id=? AND b.blocked_id=s.user_id) OR (b.user_id=s.user_id AND b.blocked_id=?)) ORDER BY s.id DESC",(time.time(),g.uid,g.uid)))
