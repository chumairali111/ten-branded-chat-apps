import time,json

from flask import Blueprint,request,jsonify,g,abort

from ...db import one,rows,run

from ...security import auth,member

bp=Blueprint('calls',__name__)

def call_access(call_id):
    c=one('SELECT * FROM calls WHERE id=?',(call_id,))
    if not c or g.uid not in [c['caller'],c['callee']]:abort(403)
    member(c['chat_id'])
    now=time.time()
    if c['state']=='ringing' and c['created']<now-60:
        run("UPDATE calls SET state='missed',updated=? WHERE id=?",(now,call_id))
        c['state']='missed'
    elif c['state']=='active' and c['updated']<now-45:
        run("UPDATE calls SET state='ended',updated=? WHERE id=?",(now,call_id))
        c['state']='ended'
    return c

