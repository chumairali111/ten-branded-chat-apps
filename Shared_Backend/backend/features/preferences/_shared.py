import time

from flask import Blueprint,request,jsonify,g

from ...db import run

from ...security import auth,member,preference

bp=Blueprint('preferences',__name__)

