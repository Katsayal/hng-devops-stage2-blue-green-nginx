#!/bin/bash
set -e

# Determine primary and backup based on ACTIVE_POOL
if [[ "$ACTIVE_POOL" == "blue" ]]; then
    export PRIMARY="app_blue"
    export BACKUP="app_green"
else
    export PRIMARY="app_green"
    export BACKUP="app_blue"
fi

echo "Active pool: $ACTIVE_POOL -> PRIMARY=$PRIMARY, BACKUP=$BACKUP"

# Substitute PRIMARY/BACKUP into Nginx template
envsubst '${PRIMARY} ${BACKUP}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf

# Start Nginx in foreground
nginx -g 'daemon off;'
