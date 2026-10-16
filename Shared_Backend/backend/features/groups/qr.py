from ._shared import auth, bp, group, io, request, send_file

@bp.get('/api/groups/<int:cid>/qr')
@auth
def qr(cid):
    c,_=group(cid);import qrcode
    image=qrcode.make(request.host_url+'?invite='+c['invite']);b=io.BytesIO();image.save(b,format='PNG');b.seek(0);return send_file(b,mimetype='image/png')
