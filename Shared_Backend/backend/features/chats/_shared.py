import time,secrets

from flask import Blueprint,request,jsonify,g,abort

from ...db import one,rows,run,db

from ...security import auth,member,preference,event

bp=Blueprint('chats',__name__)

