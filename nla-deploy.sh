#!/bin/bash
set -eu

dest=$1
virtualenv-3.6 $dest
$dest/bin/pip install git+https://github.com/webrecorder/pywb.git@v-2.4.0-rc2
virtualenv-3.6 --relocatable $dest
cp -a awa awa-nobanner $dest
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa/config.yaml
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa-nobanner/config.yaml
