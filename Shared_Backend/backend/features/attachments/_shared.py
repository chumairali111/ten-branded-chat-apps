import uuid,io

from pathlib import Path

from flask import Blueprint,request,jsonify,abort,current_app,send_file,g

from werkzeug.utils import secure_filename

from ...db import one,rows,run

from ...security import auth,member,preference

bp=Blueprint('attachments',__name__)

ALLOWED={'png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg','webp':'image/webp','gif':'image/gif','m4a':'audio/mp4','aac':'audio/aac','mov':'video/quicktime','mp4':'video/mp4','webm':'video/webm','mp3':'audio/mpeg','ogg':'audio/ogg','wav':'audio/wav','pdf':'application/pdf','txt':'text/plain','csv':'text/csv','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','zip':'application/zip'}

