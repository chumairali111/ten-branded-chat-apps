import time

from flask import Blueprint,request,jsonify,g,abort

from ...db import one,rows,run

from ...security import auth,member,preference

bp=Blueprint('messaging',__name__)

def accessible(mid):
    m=one('SELECT * FROM messages WHERE id=?',(mid,))
    if not m:abort(404)
    member(m['chat_id'])
    p=preference(m['chat_id'])
    if m['created']<=p['cleared'] or (m['expires'] and m['expires']<=time.time()) or one('SELECT 1 FROM hidden_messages WHERE message_id=? AND user_id=?',(mid,g.uid)):abort(404)
    return m

