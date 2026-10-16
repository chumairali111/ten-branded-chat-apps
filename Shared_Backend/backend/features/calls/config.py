import os,json
from flask import jsonify,current_app
from ._shared import bp,auth

@bp.get('/api/calls/config')
@auth
def config():
    try:
        servers=json.loads(os.getenv('ICE_SERVERS_JSON','[{"urls":"stun:stun.l.google.com:19302"}]'))
        if not isinstance(servers,list): raise ValueError()
    except (ValueError,TypeError):
        servers=[]
    return jsonify(iceServers=servers)
