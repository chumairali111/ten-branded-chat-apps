import hashlib
import hmac
import secrets
import time

from ._shared import abort, auth, bp, current_app, g, jsonify, one, request, run
from ...db import db


PAIRING_LIFETIME = 180
PLATFORMS = {'android', 'ios', 'web', 'windows', 'macos', 'linux'}


def _pairing(pairing_id, secret):
    item = one('SELECT * FROM device_pairings WHERE id=?', (pairing_id,))
    if not item:
        abort(404, description='Pairing challenge not found')
    if not hmac.compare_digest(item['secret_hash'], hashlib.sha256(secret.encode()).hexdigest()):
        cx=db()
        with cx:
            cx.execute(
                "UPDATE device_pairings SET failed_attempts=failed_attempts+1,status=CASE WHEN failed_attempts+1>=5 THEN 'expired' ELSE status END WHERE id=?",
                (pairing_id,),
            )
            if item['failed_attempts']+1>=5 and item['session_token']:
                cx.execute("UPDATE device_pairings SET session_token=NULL WHERE id=?",(pairing_id,))
                cx.execute('DELETE FROM sessions WHERE token=?',(item['session_token'],))
            cx.execute("INSERT INTO device_pairing_events(pairing_id,event,created) VALUES(?,'invalid_secret',?)",
                       (pairing_id,time.time()))
        abort(404, description='Pairing challenge not found')
    if item['expires'] <= time.time():
        cx=db()
        with cx:
            if item['status'] == 'pending':
                cx.execute("UPDATE device_pairings SET status='expired' WHERE id=? AND status='pending'", (pairing_id,))
            elif item['status']=='approved' and not item['delivered']:
                cx.execute("UPDATE device_pairings SET status='expired',session_token=NULL WHERE id=?",(pairing_id,))
                cx.execute('DELETE FROM sessions WHERE token=?',(item['session_token'],))
        abort(410, description='Pairing challenge expired')
    return item


@bp.post('/api/device-pairings')
def create_pairing():
    data=request.get_json(silent=True) or {}
    name=data.get('device_name')
    platform=data.get('platform')
    if not isinstance(name,str) or not 1<=len(name.strip())<=80 or not isinstance(platform,str) or platform not in PLATFORMS:
        abort(400, description='Provide a device name and supported platform')
    pairing_id=secrets.token_urlsafe(24)
    secret=secrets.token_urlsafe(32)
    now=time.time()
    run('INSERT INTO device_pairings(id,secret_hash,device_name,platform,expires,created) VALUES(?,?,?,?,?,?)',
        (pairing_id,hashlib.sha256(secret.encode()).hexdigest(),name.strip(),platform,now+PAIRING_LIFETIME,now))
    run("INSERT INTO device_pairing_events(pairing_id,event,created) VALUES(?,'created',?)",(pairing_id,now))
    return jsonify(id=pairing_id,secret=secret,expires_in=PAIRING_LIFETIME,
                   pairing_uri=f'whatsappclone://pair?id={pairing_id}&secret={secret}'),201


@bp.post('/api/device-pairings/<pairing_id>/approve')
@auth
def approve_pairing(pairing_id):
    data=request.get_json(silent=True) or {}
    secret=data.get('secret')
    if not isinstance(secret,str) or not secret:
        abort(400, description='Pairing secret is required')
    item=_pairing(pairing_id,secret)
    if item['status']!='pending':
        abort(409, description='Pairing challenge is no longer pending')
    token=secrets.token_urlsafe(48)
    csrf=secrets.token_urlsafe(32)
    session_id=secrets.token_urlsafe(18)
    now=time.time()
    cx=db()
    with cx:
        cx.execute(
            'INSERT INTO sessions(token,user_id,csrf,expires,id,device_name,platform,created) VALUES(?,?,?,?,?,?,?,?)',
            (token,g.uid,csrf,item['expires'],session_id,item['device_name'],item['platform'],now),
        )
        changed=cx.execute(
            "UPDATE device_pairings SET status='approved',account_id=?,session_token=? WHERE id=? AND status='pending' AND expires>?",
            (g.uid,token,pairing_id,now),
        ).rowcount
        if not changed:
            abort(409, description='Pairing challenge is no longer pending')
        cx.execute("INSERT INTO device_pairing_events(pairing_id,account_id,event,created) VALUES(?,?,?,?)",
                   (pairing_id,g.uid,'approved',now))
    return jsonify(ok=True,device_name=item['device_name'],platform=item['platform']),200


@bp.post('/api/device-pairings/<pairing_id>/details')
@auth
def pairing_details(pairing_id):
    data=request.get_json(silent=True) or {}
    secret=data.get('secret')
    if not isinstance(secret,str) or not secret:
        abort(400, description='Pairing secret is required')
    item=_pairing(pairing_id,secret)
    if item['status']!='pending':
        abort(409, description='Pairing challenge is no longer pending')
    return jsonify(device_name=item['device_name'],platform=item['platform'],
                   expires_in=max(0,int(item['expires']-time.time())))


@bp.post('/api/device-pairings/<pairing_id>/poll')
def pairing_status(pairing_id):
    data=request.get_json(silent=True) or {}
    secret=data.get('secret','')
    if not isinstance(secret,str):
        abort(400, description='Pairing secret is required')
    item=_pairing(pairing_id,secret)
    if item['status']=='cancelled':
        return jsonify(status='cancelled')
    if item['status']!='approved':
        return jsonify(status=item['status'])
    if item['delivered']:
        return jsonify(status='approved',delivered=True)
    cx=db()
    with cx:
        changed=cx.execute('UPDATE device_pairings SET delivered=1 WHERE id=? AND delivered=0',(pairing_id,)).rowcount
        if not changed:
            return jsonify(status='approved',delivered=True)
        session=cx.execute('SELECT token,csrf,id,user_id FROM sessions WHERE token=? AND expires>?',
                           (item['session_token'],time.time())).fetchone()
        if not session:
            cx.execute('UPDATE device_pairings SET delivered=0 WHERE id=?',(pairing_id,))
            return jsonify(status='revoked')
        cx.execute('UPDATE sessions SET expires=? WHERE token=?',(time.time()+7*86400,item['session_token']))
        session=dict(session)
    run("INSERT INTO device_pairing_events(pairing_id,account_id,event,created) VALUES(?,?,'delivered',?)",
        (pairing_id,session['user_id'],time.time()))
    response=jsonify(status='approved',delivered=False,
                     token=session['token'] if item['platform']!='web' else None,
                     csrf=session['csrf'],session_id=session['id'],
                     user=one('SELECT id,username,name,about,avatar FROM users WHERE id=?',(session['user_id'],)))
    if item['platform']=='web':
        response.set_cookie('chat_session',session['token'],httponly=True,samesite='Strict',
                            secure=current_app.config['COOKIE_SECURE'],max_age=7*86400)
    return response


@bp.post('/api/device-pairings/<pairing_id>/cancel')
def cancel_pairing(pairing_id):
    data=request.get_json(silent=True) or {}
    secret=data.get('secret','')
    if not isinstance(secret,str):
        abort(400, description='Pairing secret is required')
    item=_pairing(pairing_id,secret)
    if item['status'] in ('pending','approved'):
        cx=db()
        with cx:
            cx.execute("UPDATE device_pairings SET status='cancelled',session_token=NULL WHERE id=? AND status IN ('pending','approved')",(pairing_id,))
            if item['session_token']:
                cx.execute('DELETE FROM sessions WHERE token=?',(item['session_token'],))
            cx.execute("INSERT INTO device_pairing_events(pairing_id,account_id,event,created) VALUES(?,?,'cancelled',?)",
                       (pairing_id,item['account_id'],time.time()))
    return jsonify(ok=True)
