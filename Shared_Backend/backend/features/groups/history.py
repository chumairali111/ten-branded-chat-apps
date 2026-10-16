from ._shared import auth, bp, group, jsonify, rows

@bp.get('/api/groups/<int:cid>/events')
@auth
def history(cid):group(cid);return jsonify(events=rows('SELECT e.*,u.name FROM member_events e JOIN users u ON u.id=e.actor WHERE chat_id=? ORDER BY e.id DESC',(cid,)))
