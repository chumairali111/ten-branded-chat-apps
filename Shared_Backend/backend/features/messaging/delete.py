from ._shared import abort, accessible, auth, bp, g, jsonify, request, run, time

@bp.delete('/api/messages/<int:mid>')
@auth
def delete(mid):
    m=accessible(mid)
    if request.args.get('scope')=='everyone':
        if m['sender']!=g.uid or time.time()-m['created']>2*86400:abort(403)
        run("UPDATE messages SET deleted=1,body='',file_id=NULL WHERE id=?",(mid,))
    else:run('INSERT OR IGNORE INTO hidden_messages VALUES(?,?)',(mid,g.uid))
    return jsonify(ok=True)
