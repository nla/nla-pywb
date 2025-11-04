#!/bin/bash
set -eu

dest=$1

# use virtualenv-3.6 if available (RHEL < 9), otherwise use virtualenv (RHEL >= 9)
if command -v python3.11 > /dev/null; then
  virtualenv='python3.11 -m virtualenv'
elif command -v virtualenv-3.6 > /dev/null; then
  virtualenv=virtualenv-3.6
else
  virtualenv=virtualenv
fi

$virtualenv $dest

$dest/bin/pip install git+https://github.com/webrecorder/pywb.git@inject_scripts-option
#$dest/bin/pip install git+https://github.com/nla/pywb.git
$dest/bin/pip install wheel
$dest/bin/pip install uwsgi
$dest/bin/pip install gevent
$virtualenv --relocatable $dest || echo "virtualenv doesnt support relocatable (probably ok)"
cp -a awa awa-nobanner static $dest
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa/config.yaml
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa-nobanner/config.yaml

sed '/^rules:/ r rules-extra.yaml' $dest/lib/python*/site-packages/pywb/rules.yaml > $dest/awa/rules.yaml
cp $dest/awa/rules.yaml $dest/awa-nobanner/rules.yaml

curl -sSfLo ruffle.zip https://github.com/ruffle-rs/ruffle/releases/download/nightly-2025-11-04/ruffle-nightly-2025_11_04-web-selfhosted.zip
unzip -d "$dest/awa/static/ruffle" ruffle.zip