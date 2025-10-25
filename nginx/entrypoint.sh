#!/bin/bash

set -e

# Substitute ACTIVE_POOL in template and start Nginx
envsubst '${ACTIVE_POOL}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf

echo "Using active pool: ${ACTIVE_POOL}"
nginx -g 'daemon off;'
