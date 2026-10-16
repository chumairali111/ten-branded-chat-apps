from ._shared import abort, accessible, auth, bp, g, jsonify, request, run

@bp.post('/api/messages/<int:mid>/reaction')
@auth
def reaction(mid):
    m=accessible(mid);e=str(request.get_json().get('emoji',''))
    if m['deleted'] or len(e)>16:abort(400)
    if e:run('INSERT OR REPLACE INTO reactions VALUES(?,?,?)',(mid,g.uid,e))
    else:run('DELETE FROM reactions WHERE message_id=? AND user_id=?',(mid,g.uid))
    return jsonify(ok=True)
