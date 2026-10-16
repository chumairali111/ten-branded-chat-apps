from ._shared import auth, bp, g, jsonify, rows

@bp.get('/api/lists')
@auth
def get():
    lists=rows('SELECT * FROM lists WHERE user_id=?',(g.uid,))
    for l in lists:l['chat_ids']=[c['chat_id'] for c in rows('SELECT chat_id FROM list_chats WHERE list_id=?',(l['id'],))]
    return jsonify(lists=lists)
