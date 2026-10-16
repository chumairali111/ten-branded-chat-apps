from ._shared import abort, auth, bp, event, group, jsonify, request, run

@bp.patch('/api/groups/<int:cid>')
@auth
def update(cid):
    group(cid,True);d=request.get_json()
    for key in ['title','description','admin_only','disappear','advanced_privacy']:
        if key not in d:continue
        value=d[key]
        if key in ['title','description']:value=str(value).strip()[:80 if key=='title' else 500]
        elif key=='disappear':
            value=int(value)
            if value not in [0,86400,604800,7776000]:abort(400)
        else:value=int(bool(value))
        if key=='title' and not value:abort(400)
        run(f'UPDATE chats SET {key}=? WHERE id=?',(value,cid))
    event(cid,'Group settings updated');return jsonify(ok=True)
