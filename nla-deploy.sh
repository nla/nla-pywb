#!/bin/bash
set -eu

dest=$1
virtualenv-3.4 $dest
$dest/bin/pip install pywb==2.2.20190311
virtualenv-3.4 --relocatable $dest
cp -a awa $dest
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa/config.yaml
