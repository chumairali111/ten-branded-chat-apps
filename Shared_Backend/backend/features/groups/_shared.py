import time,secrets,io

from flask import Blueprint,request,jsonify,g,abort,send_file

from ...db import one,rows,run,db

from ...security import auth,member,event

bp=Blueprint('groups',__name__)

def group(cid,admin=False):
    m=member(cid,admin);c=one('SELECT * FROM chats WHERE id=?',(cid,))
    if c['kind']!='group':abort(400,description='Group action requires a group chat')
    return c,m

