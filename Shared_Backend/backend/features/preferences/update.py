from ._shared import auth, bp, g, jsonify, member, preference, request, run

@bp.patch('/api/chats/<int:cid>/preferences')
@auth
def update(cid):
    member(cid);preference(cid);d=request.get_json()
    for key in ['favourite','archived','muted','media_visible']:
        if key in d:run(f'UPDATE preferences SET {key}=? WHERE chat_id=? AND user_id=?',(int(bool(d[key])),cid,g.uid))
    return jsonify(ok=True)
