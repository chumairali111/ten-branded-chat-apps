from flask import Blueprint,request,jsonify,g,abort

from ...db import one,rows,run

from ...security import auth,member,event

bp=Blueprint('communities',__name__)

