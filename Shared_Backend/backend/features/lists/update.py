from ._shared import abort, auth, bp, g, jsonify, member, one, request, run

@bp.route('/api/lists/<int:lid>/chats/<int:cid>',methods=['POST','DELETE'])
@auth
def update(lid,cid):
    member(cid)
    if not one('SELECT id FROM lists WHERE id=? AND user_id=?',(lid,g.uid)):abort(403)
    if request.method=='POST':run('INSERT OR IGNORE INTO list_chats VALUES(?,?)',(lid,cid))
    else:run('DELETE FROM list_chats WHERE list_id=? AND chat_id=?',(lid,cid))
    return jsonify(ok=True)
