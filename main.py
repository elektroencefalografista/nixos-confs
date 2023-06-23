## main.py - MAIN APP FILE

# reqs: Flask waitress netaddr google-cloud-storage

_devel = False
import base64, gzip
from netaddr import IPAddress, IPNetwork
from flask import Flask, request
from google.cloud import storage
from google.api_core.exceptions import NotFound

app = Flask(__name__.split('.')[0])

def getSecret(bucket, secret):
    try:
        ret = bucket.blob(secret).download_as_string()
    except NotFound:
        ret = False
    return ret

def IPisAllowed(ip, networks):
    for network in networks:
        if IPAddress(ip) in IPNetwork(network): return True
    return False

@app.route('/')
def query():
    st_cl = storage.Client.from_service_account_json(json_credentials_path="acc.json")
    bucket = st_cl.bucket('drath-private')
    networks = bucket.blob('allowedips.txt').download_as_string().decode().splitlines()

    if IPisAllowed(request.remote_addr, networks):
        msg = getSecret(bucket, request.args.get('q'))
    else:
        return "unallowed", 403
    st_cl.close()

    if not msg: return "no", 403

    if request.args.get('gz') != '0': msg = gzip.compress(msg)
    return base64.b64encode(msg)



@app.route('/ip')
def checkIP():
    addr = request.remote_addr
    st_cl = storage.Client.from_service_account_json(json_credentials_path="acc.json")
    networks = st_cl.bucket('drath-private').blob('allowedips.txt').download_as_string().decode().splitlines()
    st_cl.close()
    return addr + (" un" if not IPisAllowed(addr, networks) else " ") + "allowed"



if __name__ == '__main__':
    if _devel:
        app.run(host='0.0.0.0', port=8080, debug=_devel)
    else:
        from waitress import serve
        serve(app, host="0.0.0.0", port=8080)