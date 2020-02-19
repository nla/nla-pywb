# nla-pywb
pywb config overlay for the Australian Web Archive

## jvmctl config
```
PORT=8080
REPO=git@github.com:nla/nla-pywb.git
CONTAINER=none
APP_OPTS=

CDX_URL=http://cdx-server/coll
WARC_URL=http://warc-server/warcs/

[systemd.service.Service]
WorkingDirectory = /apps/pywb/awa
ExecStart = /usr/bin/logduct-run /apps/pywb/bin/pywb --port ${PORT}
```

## Multiple access points

Currently multiple access points are configured by deploying a separate instance of Pywb for each with a different
CDX_URL configured.