from ._shared import abort, auth, bp, event, g, jsonify, one, run

@bp.post('/api/invite/<token>')
@auth
def join(token):
    c=one("SELECT id FROM chats WHERE invite=? AND kind='group'",(token,))
    if not c:abort(404,description='Invite is invalid')
    run('INSERT OR IGNORE INTO members(chat_id,user_id) VALUES(?,?)',(c['id'],g.uid));event(c['id'],'Joined via invite');return jsonify(id=c['id'])
