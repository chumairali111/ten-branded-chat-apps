import os
from pathlib import Path
from flask import Flask,jsonify,request,send_from_directory
from werkzeug.exceptions import HTTPException
from .db import init_db,close_db

def create_app(test_config=None):
    root=Path(__file__).resolve().parents[1]
    app=Flask(__name__,static_folder=str(root/'frontend'),static_url_path='/static')
    instance=Path(os.getenv('DATA_DIR',str(root/'instance'))).resolve();instance.mkdir(parents=True,exist_ok=True)
    app.config.update(DATABASE=os.getenv('DATABASE_PATH',str(instance/'chat.db')),UPLOADS=os.getenv('UPLOADS_PATH',str(instance/'uploads')),MAX_CONTENT_LENGTH=20*1024*1024,COOKIE_SECURE=os.getenv('COOKIE_SECURE')=='1',WEB_ALLOWED_ORIGINS=os.getenv('WEB_ALLOWED_ORIGINS',''))
    if test_config: app.config.update(test_config)
    Path(app.config['UPLOADS']).mkdir(parents=True,exist_ok=True)
    app.teardown_appcontext(close_db)
    with app.app_context(): init_db()
    from .features import authentication,profiles,chats,messaging,attachments,groups,preferences,lists,statuses,communities,reporting,chat_lock,calls,chat_settings
    for m in [authentication,profiles,chats,messaging,attachments,groups,preferences,lists,statuses,communities,reporting,chat_lock,calls,chat_settings]: app.register_blueprint(m.bp)
    @app.get('/')
    def index(): return send_from_directory(root/'frontend','index.html')
    @app.get('/api/health')
    def health(): return jsonify(status='ok')
    @app.errorhandler(HTTPException)
    def error(e): return jsonify(error=e.description),e.code
    @app.after_request
    def headers(r):
        configured=app.config['WEB_ALLOWED_ORIGINS']
        allowed=set(configured if isinstance(configured,(list,tuple,set)) else (origin.strip() for origin in configured.split(',') if origin.strip()))
        origin=request.headers.get('Origin')
        if origin and origin in allowed:
            r.headers['Access-Control-Allow-Origin']=origin
            r.headers['Access-Control-Allow-Credentials']='true'
            r.headers['Access-Control-Allow-Methods']='GET, HEAD, POST, PATCH, DELETE, OPTIONS'
            r.headers['Access-Control-Allow-Headers']='Authorization, Content-Type, X-CSRF-Token, X-Client'
            r.headers['Access-Control-Max-Age']='600'
            r.vary.add('Origin')
        r.headers['X-Content-Type-Options']='nosniff'
        r.headers['X-Frame-Options']='DENY'
        r.headers['Referrer-Policy']='same-origin'
        r.headers['Cache-Control']='no-store'
        r.headers['Content-Security-Policy']="default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' blob: data:; media-src 'self' blob:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'"
        return r
    return app
