import re,secrets,time

from flask import Blueprint,request,jsonify,g,abort,current_app

from werkzeug.security import generate_password_hash,check_password_hash

from ...db import one,run

from ...security import auth

bp=Blueprint('authentication',__name__)

def establish(uid,device_name='Browser',platform='web'):
    token=secrets.token_urlsafe(48);csrf=secrets.token_urlsafe(32)
    session_id=secrets.token_urlsafe(18)
    run('INSERT INTO sessions(token,user_id,csrf,expires,id,device_name,platform,created) VALUES(?,?,?,?,?,?,?,?)',
        (token,uid,csrf,time.time()+7*86400,session_id,device_name,platform,time.time()))
    result={'user':one('SELECT id,username,name,about,avatar FROM users WHERE id=?',(uid,)),'csrf':csrf}
    if request.headers.get('X-Client')=='flutter-native':
        result.update(token=token,session_id=session_id,device_name=device_name)
    r=jsonify(result)
    if request.headers.get('X-Client')!='flutter-native':
        r.set_cookie('chat_session',token,httponly=True,samesite='Strict',secure=current_app.config['COOKIE_SECURE'],max_age=7*86400)
    return r
