from ._shared import auth, bp, g, jsonify, time
from ...db import rows

@bp.get('/api/sessions')
@auth
def sessions():
    active=rows('SELECT id,device_name,platform,created,expires FROM sessions WHERE user_id=? AND expires>? ORDER BY created DESC',(g.uid,time.time()))
    return jsonify(sessions=len(active),devices=[dict(item,current=item['id']==g.session_id) for item in active])
