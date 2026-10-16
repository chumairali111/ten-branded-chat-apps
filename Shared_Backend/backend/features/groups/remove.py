from ._shared import auth, bp, db, event, g, group, jsonify, member

@bp.delete('/api/groups/<int:cid>/members/<int:uid>')
@auth
def remove(cid,uid):
    group(cid)
    if uid!=g.uid:member(cid,True)
    cx=db()
    with cx:
        cx.execute('DELETE FROM members WHERE chat_id=? AND user_id=?',(cid,uid))
        remaining=cx.execute('SELECT user_id FROM members WHERE chat_id=? ORDER BY user_id',(cid,)).fetchall()
        admin=cx.execute("SELECT 1 FROM members WHERE chat_id=? AND role='admin'",(cid,)).fetchone()
        if remaining and not admin:cx.execute("UPDATE members SET role='admin' WHERE chat_id=? AND user_id=?",(cid,remaining[0]['user_id']))
    event(cid,f'Member {uid} left or removed');return jsonify(ok=True)
