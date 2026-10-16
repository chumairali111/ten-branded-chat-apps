from ._shared import auth, bp, g, jsonify, member, one, preference, rows

@bp.get('/api/chats/<int:cid>')
@auth
def detail(cid):
    member(cid);c=one('SELECT * FROM chats WHERE id=?',(cid,));c['members']=rows('SELECT u.id,u.name,u.username,u.about,u.avatar,u.last_seen,m.role,m.tag FROM members m JOIN users u ON u.id=m.user_id WHERE m.chat_id=?',(cid,));c['preferences']=preference(cid)
    if c['kind']=='direct':c['title']=next((u['name'] for u in c['members'] if u['id']!=g.uid),c['title'])
    return jsonify(c)
