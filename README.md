# nla-pywb
pywb config overlay for the Australian Web Archive

## Container Usage

### Build
```bash
podman build -t nla-pywb .
```

### Run
To run the container manually, you must provide the `CDX_URL` and `WARC_URL` environment variables.

```bash
podman run -p 8080:8080 \
  -e CDX_URL="http://pandas.nla.gov.au/cdx/trove" \
  -e WARC_URL="http://pandas.nla.gov.au/bamboo/warcs/" \
  nla-pywb
```

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