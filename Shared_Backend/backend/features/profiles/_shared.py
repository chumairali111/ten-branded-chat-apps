from flask import Blueprint,request,jsonify,g,abort

from ...db import one,rows,run

from ...security import auth

bp=Blueprint('profiles',__name__)

