from ._shared import auth, bp, g, jsonify, rows

@bp.get('/api/communities')
@auth
def get():return jsonify(communities=rows('SELECT DISTINCT c.* FROM communities c LEFT JOIN chats ch ON ch.community_id=c.id LEFT JOIN members m ON m.chat_id=ch.id WHERE c.owner=? OR m.user_id=?',(g.uid,g.uid)))
