"""
Pywb Proxy Fix

This copies the Pywb-Edge-Host HTTP header to the Host header so that pywb generates
correct URLs when behind both the Kubernetes ingress nginx and our frontend nginx.

We unfortunately can't use the Werkzeug ProxyFix module with X-Forwarded-Host because
the Kubernetes ingress controller clobbers X-Forwarded-Host rather than appending to it.
We also can't set the Host header to the edge hostname because we run multiple instances
of pywb for different access environments (e.g. reading room vs public) and so need to
use the Host header for the ingress controller to route the requests to the correct instance.

So intead, we have the frontend nginx set a custom header Pywb-Edge-Host with the original
edge Host value. The nice thing about this approach is the generated URLs are correct when the
app accessed both via the edge hostname and directly via the ingress hostname, which makes
testing and troubleshooting a bit easier.
"""
from pywb.apps.wayback import application as pywb_app

def application(environ, start_response):
    edge_host = environ.get("HTTP_PYWB_EDGE_HOST")
    if edge_host:
        environ["HTTP_HOST"] = edge_host.split(",")[0].strip()
    return pywb_app(environ, start_response)
