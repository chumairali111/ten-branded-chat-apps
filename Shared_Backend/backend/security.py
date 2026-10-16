import time,secrets
from functools import wraps
from flask import request,g,abort
from .db import one,run

def auth(f):
    @wraps(f)
    def wrapped(*a,**kw):
        bearer=request.headers.get('Authorization','')
        token=bearer[7:] if bearer.startswith('Bearer ') else request.cookies.get('chat_session','')
        s=one('SELECT * FROM sessions WHERE token=? AND expires>?',(token,time.time()))
        if not s: abort(401,description='Please sign in')
        if request.method not in ('GET','HEAD','OPTIONS') and not secrets.compare_digest(request.headers.get('X-CSRF-Token',''),s['csrf']):
            abort(403,description='Invalid CSRF token')
        g.uid=s['user_id'];g.csrf=s['csrf'];g.session_token=token;g.session_id=s['id']
        run('UPDATE users SET last_seen=? WHERE id=?',(time.time(),g.uid))
        return f(*a,**kw)
    return wrapped

def member(chat_id,admin=False,allow_locked=False):
    m=one('SELECT * FROM members WHERE chat_id=? AND user_id=?',(chat_id,g.uid))
    if not m: abort(403,description='You are not a member of this chat')
    if admin and m['role']!='admin': abort(403,description='Group admin permission required')
    if not allow_locked:
        p=one('SELECT locked FROM preferences WHERE chat_id=? AND user_id=?',(chat_id,g.uid))
        if p and p['locked'] and not one('SELECT 1 FROM lock_grants WHERE token=? AND chat_id=? AND expires>?',(g.session_token,chat_id,time.time())):
            abort(423,description='Chat is locked')
    return m

def preference(chat_id):
    run('INSERT OR IGNORE INTO preferences(chat_id,user_id) VALUES(?,?)',(chat_id,g.uid))
    return one('SELECT * FROM preferences WHERE chat_id=? AND user_id=?',(chat_id,g.uid))

def event(cid,text): run('INSERT INTO member_events(chat_id,actor,detail,created) VALUES(?,?,?,?)',(cid,g.uid,text,time.time()))
