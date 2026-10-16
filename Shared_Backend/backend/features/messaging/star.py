from ._shared import accessible, auth, bp, g, jsonify, one, run

@bp.post('/api/messages/<int:mid>/star')
@auth
def star(mid):
    accessible(mid)
    if one('SELECT 1 FROM stars WHERE message_id=? AND user_id=?',(mid,g.uid)):run('DELETE FROM stars WHERE message_id=? AND user_id=?',(mid,g.uid))
    else:run('INSERT INTO stars VALUES(?,?)',(mid,g.uid))
    return jsonify(ok=True)
