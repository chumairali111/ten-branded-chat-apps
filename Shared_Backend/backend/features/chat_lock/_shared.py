import time

from flask import Blueprint,request,g,jsonify,abort

from werkzeug.security import check_password_hash

from ...db import one,run

from ...security import auth,member,preference

bp=Blueprint('chat_lock',__name__)

