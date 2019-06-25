#!/bin/bash
set -eu

dest=$1
virtualenv-3.4 $dest
$dest/bin/pip install pywb==2.2.20190311
virtualenv-3.4 --relocatable $dest
