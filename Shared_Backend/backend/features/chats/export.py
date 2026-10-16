from ._shared import abort, auth, bp, g, member, one, preference, rows, time

@bp.get('/api/chats/<int:cid>/export')
@auth
def export(cid):
    member(cid);c=one('SELECT * FROM chats WHERE id=?',(cid,))
    if c['advanced_privacy']:abort(403,description='Export disabled by advanced chat privacy')
    p=preference(cid)
    msgs=rows('SELECT m.body,m.kind,m.created,u.name FROM messages m JOIN users u ON u.id=m.sender WHERE m.chat_id=? AND m.created>? AND m.deleted=0 AND (m.expires IS NULL OR m.expires>?) AND m.id NOT IN (SELECT message_id FROM hidden_messages WHERE user_id=?) ORDER BY m.id',(cid,p['cleared'],time.time(),g.uid))
    text='\n'.join(f"{time.strftime('%Y-%m-%d %H:%M',time.localtime(m['created']))} | {m['name']}: {m['body'] or '['+m['kind']+']'}" for m in msgs)
    return text,200,{'Content-Type':'text/plain; charset=utf-8','Content-Disposition':f'attachment; filename="chat-{cid}.txt"'}
