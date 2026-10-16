from ._shared import abort, auth, bp, event, jsonify, member, one, request, run

@bp.patch('/api/chats/<int:cid>/settings')
@auth
def update(cid):
    member(cid);c=one('SELECT kind FROM chats WHERE id=?',(cid,))
    if c['kind']=='group':member(cid,True)
    d=request.get_json()
    if 'disappear' in d:
        try:value=int(d['disappear'])
        except (TypeError,ValueError):abort(400)
        if value not in [0,86400,604800,7776000]:abort(400)
        run('UPDATE chats SET disappear=? WHERE id=?',(value,cid))
    if 'advanced_privacy' in d:run('UPDATE chats SET advanced_privacy=? WHERE id=?',(int(bool(d['advanced_privacy'])),cid))
    event(cid,'Chat privacy settings updated');return jsonify(ok=True)
