from flask import Blueprint,request,jsonify,abort

from ...db import one,run

from ...security import auth,member,event

bp=Blueprint('chat_settings',__name__)

