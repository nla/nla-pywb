from pywb.apps.wayback import application as pywb_app

def application(environ, start_response):
    edge_host = environ.get("HTTP_PYWB_EDGE_HOST")
    if edge_host:
        environ["HTTP_HOST"] = edge_host.split(",")[0].strip()
    return pywb_app(environ, start_response)
