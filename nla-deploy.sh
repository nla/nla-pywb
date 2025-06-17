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

#$dest/bin/pip install git+https://github.com/webrecorder/pywb.git@issue-924-client-side-playback
$dest/bin/pip install git+https://github.com/webrecorder/pywb.git@8ea2f74517161c1fc91ca969cea6328a20f5dce6
#$dest/bin/pip install git+https://github.com/nla/pywb.git@issue-924-client-side-playback-patched
#$dest/bin/pip install git+https://github.com/webrecorder/pywb.git@v-2.6.6
$dest/bin/pip install wheel
$dest/bin/pip install uwsgi
$dest/bin/pip install gevent
$virtualenv --relocatable $dest || echo "virtualenv doesnt support relocatable (probably ok)"
cp -a awa awa-nobanner $dest
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa/config.yaml
sed -i -e "s|CDX_URL|$CDX_URL|" -e "s|WARC_URL|$WARC_URL|" $dest/awa-nobanner/config.yaml

sed '/^rules:/ r rules-extra.yaml' $dest/lib/python*/site-packages/pywb/rules.yaml > $dest/awa/rules.yaml
cp $dest/awa/rules.yaml $dest/awa-nobanner/rules.yaml
