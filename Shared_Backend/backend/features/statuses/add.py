from ._shared import abort, auth, bp, g, jsonify, request, run, time, one

@bp.post('/api/statuses')
@auth
def add():
    data=request.get_json() or {}
    text=str(data.get('body','')).strip()
    media_id=data.get('media_id')
    kind='text'
    if media_id:
        media=one("SELECT * FROM shared_media WHERE id=? AND owner=? AND purpose='status'",(media_id,g.uid))
        if not media: abort(400,description='Upload your status media first')
        kind=media['mime'].split('/')[0]
    if len(text)>700 or (not text and not media_id): abort(400,description='Add text or image/video')
    now=time.time()
    sid=run('INSERT INTO statuses(user_id,body,created,expires,media_id,kind) VALUES(?,?,?,?,?,?)',(g.uid,text,now,now+86400,media_id,kind))
    return jsonify(id=sid),201
