#!/bin/sh
set -eu
# Only manage our own cache, never the original pictures or existing user files.
if [ ! -d /data/thumbnails ]; then
    mkdir /data/thumbnails
    chown nginx:nginx /data/thumbnails
fi
spawn-fcgi -a 127.0.0.1 -p 8081 -u nginx -g nginx -- /usr/bin/fcgiwrap -c 2
