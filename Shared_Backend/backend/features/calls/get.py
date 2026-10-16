from ._shared import auth, bp, g, jsonify, rows, run, time

@bp.get('/api/calls')
@auth
def get():
    run("UPDATE calls SET state='missed' WHERE state='ringing' AND created<?",(time.time()-60,))
    run("UPDATE calls SET state='ended' WHERE state='active' AND updated<?",(time.time()-45,))
    return jsonify(calls=rows('SELECT c.*,u.name caller_name,v.name callee_name FROM calls c JOIN users u ON u.id=c.caller JOIN users v ON v.id=c.callee WHERE (caller=? OR callee=?) AND NOT EXISTS(SELECT 1 FROM preferences p WHERE p.chat_id=c.chat_id AND p.user_id=? AND p.locked=1 AND NOT EXISTS(SELECT 1 FROM lock_grants l WHERE l.chat_id=p.chat_id AND l.token=? AND l.expires>?)) ORDER BY c.id DESC LIMIT 100',(g.uid,g.uid,g.uid,g.session_token,time.time())))
