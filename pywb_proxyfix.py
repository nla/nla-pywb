from werkzeug.middleware.proxy_fix import ProxyFix
from pywb.apps.wayback import application as pywb_app

#application = ProxyFix(pywb_app, x_for=2, x_proto=1, x_host=1, x_port=1)

import json
import logging

log = logging.getLogger("wsgi_debug")
logging.basicConfig(level=logging.INFO)

def application(environ, start_response):
    # Print the interesting ones + all HTTP_*
    interesting = {
        "HTTP_HOST": environ.get("HTTP_HOST"),
        "SERVER_NAME": environ.get("SERVER_NAME"),
        "SERVER_PORT": environ.get("SERVER_PORT"),
        "wsgi.url_scheme": environ.get("wsgi.url_scheme"),
        "HTTP_X_FORWARDED_HOST": environ.get("HTTP_X_FORWARDED_HOST"),
        "HTTP_X_FORWARDED_PROTO": environ.get("HTTP_X_FORWARDED_PROTO"),
        "HTTP_X_FORWARDED_PORT": environ.get("HTTP_X_FORWARDED_PORT"),
        "HTTP_X_FORWARDED_FOR": environ.get("HTTP_X_FORWARDED_FOR"),
        "HTTP_FORWARDED": environ.get("HTTP_FORWARDED"),
    }

    # Also include every HTTP_ header if you want:
    all_http = {k: v for k, v in environ.items() if k.startswith("HTTP_")}

    log.info("INTERESTING=%s", json.dumps(interesting, sort_keys=True))
    log.info("ALL_HTTP=%s", json.dumps(all_http, sort_keys=True))

    return pywb_app(environ, start_response)
