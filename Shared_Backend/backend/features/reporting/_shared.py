import time

from flask import Blueprint,request,jsonify,g,abort

from ...db import run

from ...security import auth,member

bp=Blueprint('reporting',__name__)

