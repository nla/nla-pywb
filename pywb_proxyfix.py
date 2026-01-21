from werkzeug.middleware.proxy_fix import ProxyFix
from pywb.apps.wayback import application as pywb_app

application = ProxyFix(pywb_app, x_for=1, x_proto=1, x_host=1, x_port=1)
