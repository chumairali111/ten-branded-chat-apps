from ._shared import abort, auth, bp, event, g, group, jsonify, member, one, request, run

@bp.patch('/api/groups/<int:cid>/members/<int:uid>')
@auth
def change(cid,uid):
    group(cid);d=request.get_json()
    if 'role' in d:
        member(cid,True);role=d['role']
        if role not in ['admin','member']:abort(400)
        if role=='member' and one('SELECT role FROM members WHERE chat_id=? AND user_id=?',(cid,uid)) and one("SELECT COUNT(*) n FROM members WHERE chat_id=? AND role='admin'",(cid,))['n']==1 and one('SELECT role FROM members WHERE chat_id=? AND user_id=?',(cid,uid))['role']=='admin':abort(400,description='Keep at least one admin')
        run('UPDATE members SET role=? WHERE chat_id=? AND user_id=?',(role,cid,uid));event(cid,f'Member {uid} role: {role}')
    if 'tag' in d:
        if uid!=g.uid:member(cid,True)
        run('UPDATE members SET tag=? WHERE chat_id=? AND user_id=?',(str(d['tag'])[:30],cid,uid));event(cid,f'Member {uid} tag updated')
    return jsonify(ok=True)
