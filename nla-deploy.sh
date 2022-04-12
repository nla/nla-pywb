#!/bin/bash
set -eu

dest=$1
virtualenv-3.6 $dest
#$dest/bin/pip install git+https://github.com/nla/pywb.git@v-2.6.0-nla1
$dest/bin/pip install git+https://github.com/webrecorder/pywb.git@v-2.6.6
$dest/bin/pip install wheel
$dest/bin/pip install uwsgi
$dest/bin/pip install gevent
virtualenv-3.6 --relocatable $dest
cp -a awa awa-nobanner $dest
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa/config.yaml
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa-nobanner/config.yaml
