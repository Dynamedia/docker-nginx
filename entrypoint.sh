#!/bin/bash

USER_NAME=${USER_NAME:-www-data}
USER_GROUP=${USER_GROUP:-www-data}
USER_UID=${USER_UID:-1001}
USER_GID=${USER_GID:-1001}
NGINX_WORKER_PROCESSES="${NGINX_WORKER_PROCESSES:-1}"
NGINX_WEBROOT="${NGINX_WEBROOT:-/var/www/app}"
PHP_UPSTREAM_CONTAINER="${PHP_UPSTREAM_CONTAINER:-}"
PHP_UPSTREAM_PORT="${PHP_UPSTREAM_PORT:-}"
MODSECURITY_STATUS="${MODSECURITY_STATUS:-off}"
MODSECURITY_POLICY="${MODSECURITY_POLICY:-DetectionOnly}"
BROTLI_STATUS="${BROTLI_STATUS:-off}"
BROTLI_STATIC_STATUS="${BROTLI_STATIC_STATUS:-off}"
BROTLI_COMP_LEVEL="${BROTLI_COMP_LEVEL:-4}"
BROTLI_TYPES="${BROTLI_TYPES:-text/plain text/css application/javascript application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript}"
GZIP_STATUS="${GZIP_STATUS:-off}"
GZIP_COMP_LEVEL="${GZIP_COMP_LEVEL:-1}"
GZIP_TYPES="${GZIP_TYPES:-text/plain text/css application/javascript application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript}"
GEOIP2_STATUS="${GEOIP2_STATUS:-off}"
PROXY_CACHE_STATUS="${PROXY_CACHE_STATUS:-off}"
PREFER_WWW="${PREFER_WWW:-off}"
PAGESPEED_STATUS="${PAGESPEED_STATUS:-unplugged}"
PAGESPEED_REWRITE_LEVEL="${PAGESPEED_REWRITE_LEVEL:-CoreFilters}"
PAGESPEED_ENABLE_FILTERS="${PAGESPEED_ENABLE_FILTERS:-}"
PAGESPEED_DISABLE_FILTERS="${PAGESPEED_DISABLE_FILTERS:-}"
REMOVE_INITIAL_CONFIG="${REMOVE_INITIAL_CONFIG:-off}"

# Delete the already existing user / group if existing

if id -u $USER_NAME > /dev/null 2>&1  ; then
    deluser $USER_NAME > /dev/null 2>&1
fi

if getent passwd $USER_UID > /dev/null 2>&1  ; then
    CLASH_USER="$(getent passwd $USER_UID | cut -d: -f1)"
    deluser $CLASH_USER > /dev/null 2>&1
fi

if getent group $USER_GID > /dev/null 2>&1  ; then
    CLASH_GROUP="$(getent group $USER_GID | cut -d: -f1)"
    # Try to delete the clashing group. If it has users we will just have to use that group (It's ok, the GID is what we wanted)
    if ! delgroup $CLASH_GROUP > /dev/null 2>&1  ; then
      USER_GROUP=$CLASH_GROUP
    else
      groupadd -g $USER_GID $USER_GROUP > /dev/null 2>&1
    fi
else
  groupadd -g $USER_GID $USER_GROUP > /dev/null 2>&1
fi

# Create our user & group with the specified details
mkdir -p /home/$USER_NAME
chown -R $USER_UID:$USER_GID /home/$USER_NAME
useradd -u $USER_UID -s /bin/bash -d /home/$USER_NAME -g $USER_GROUP $USER_NAME > /dev/null 2>&1

chown -R $USER_UID:$USER_GID /var/www/app \
                             /var/log/nginx \
                             /var/cache/nginx \
                             /etc/nginx > /dev/null 2>&1

## Modify the main config

sed -i "s#NGINX_USER_PLACEHOLDER#user $USER_NAME\;#g" /etc/nginx/nginx.conf
sed -i "s#NGINX_WORKER_PROCESSES_PLACEHOLDER#worker_processes $NGINX_WORKER_PROCESSES\;#g" /etc/nginx/nginx.conf

# Modsecurity

if [ "$MODSECURITY_STATUS" = "on" ] || [ "$MODSECURITY_STATUS" = "enabled" ] ; then
    sed -i "s#MODSECURITY_STATUS_PLACEHOLDER#modsecurity on;#g" /etc/nginx/nginx.conf
else
    sed -i "s#MODSECURITY_STATUS_PLACEHOLDER#modsecurity off;#g" /etc/nginx/nginx.conf
fi

if [ "$MODSECURITY_POLICY" = "On" ] || [ "$MODSECURITY_POLICY" = "Off" ] || [ "$MODSECURITY_STATUS" = "DetectionOnly" ] ; then
    sed -i "s#^SecRuleEngine.*#SecRuleEngine $MODSECURITY_POLICY#g" /etc/nginx/modsecurity.d/modsecurity.conf
else
    sed -i "s#^SecRuleEngine.*#SecRuleEngine DetectionOnly#g" /etc/nginx/modsecurity.d/modsecurity.conf
fi

# Brotli

if [ "$BROTLI_STATUS" = "on" ] || [ "$BROTLI_STATUS" = "enabled" ] ; then
    sed -i "s#BROTLI_STATUS_PLACEHOLDER#brotli on;#g" /etc/nginx/nginx.conf
else
    sed -i "s#BROTLI_STATUS_PLACEHOLDER#brotli off;#g" /etc/nginx/nginx.conf
fi

if [ "$BROTLI_STATIC_STATUS" = "on" ] || [ "$BROTLI_STATIC_STATUS" = "enabled" ] ; then
    sed -i "s#BROTLI_STATIC_STATUS_PLACEHOLDER#brotli_static on;#g" /etc/nginx/nginx.conf
else
    sed -i "s#BROTLI_STATIC_STATUS_PLACEHOLDER#brotli_static off;#g" /etc/nginx/nginx.conf
fi

if [[ "$BROTLI_COMP_LEVEL" =~ ^[0-9]+$ ]] & [ "$BROTLI_COMP_LEVEL" -ge 0  -a "$BROTLI_COMP_LEVEL" -le 11 ] ; then
    sed -i "s#BROTLI_COMP_LEVEL_PLACEHOLDER#brotli_comp_level $BROTLI_COMP_LEVEL;#g" /etc/nginx/nginx.conf
else
    sed -i "s#BROTLI_COMP_LEVEL_PLACEHOLDER#brotli_comp_level 4;#g" /etc/nginx/nginx.conf
fi

sed -i "s#BROTLI_TYPES_PLACEHOLDER#brotli_types $BROTLI_TYPES;#g" /etc/nginx/nginx.conf

# Gzip

if [ "$GZIP_STATUS" = "on" ] || [ "$GZIP_STATUS" = "enabled" ] ; then
    sed -i "s#GZIP_STATUS_PLACEHOLDER#gzip on;#g" /etc/nginx/nginx.conf
else
    sed -i "s#GZIP_STATUS_PLACEHOLDER#gzip off;#g" /etc/nginx/nginx.conf
fi

if [[ "$GZIP_COMP_LEVEL" =~ ^[0-9]+$ ]] & [ "$GZIP_COMP_LEVEL" -ge 1  -a "$GZIP_COMP_LEVEL" -le 9 ] ; then
    sed -i "s#GZIP_COMP_LEVEL_PLACEHOLDER#gzip_comp_level $GZIP_COMP_LEVEL;#g" /etc/nginx/nginx.conf
else
    sed -i "s#GZIP_COMP_LEVEL_PLACEHOLDER#gzip_comp_level 1;#g" /etc/nginx/nginx.conf
fi

sed -i "s#GZIP_TYPES_PLACEHOLDER#gzip_types $GZIP_TYPES;#g" /etc/nginx/nginx.conf

# Geoip2

if [ "$GEOIP2_STATUS" = "on" ] || [ "$GEOIP2_STATUS" = "enabled" ] ; then
    sed -i "s#GEOIP2_STATUS_PLACEHOLDER##g" /etc/nginx/nginx.conf
else
    sed -i "s#GEOIP2_STATUS_PLACEHOLDER#\##g" /etc/nginx/nginx.conf
fi

# Proxy cache

if [ "$PROXY_CACHE_STATUS" = "on" ] || [ "$PROXY_CACHE_STATUS" = "enabled" ] ; then
    sed -i "s#PROXY_CACHE_STATUS_PLACEHOLDER##g" /etc/nginx/nginx.conf
else
    sed -i "s#PROXY_CACHE_STATUS_PLACEHOLDER#\##g" /etc/nginx/nginx.conf
fi

# Pagespeed

if [ "$PAGESPEED_STATUS" = "on" ] || [ "$PAGESPEED_STATUS" = "off" ] || [ "$PAGESPEED_STATUS" = "standby" ] || [ "$PAGESPEED_STATUS" = "unplugged" ] ; then
    sed -i "s#PAGESPEED_STATUS_PLACEHOLDER#pagespeed $PAGESPEED_STATUS;#g" /etc/nginx/nginx.conf
else
    sed -i "s#PAGESPEED_STATUS_PLACEHOLDER#pagespeed unplugged;#g" /etc/nginx/nginx.conf
fi

if [ "$PAGESPEED_REWRITE_LEVEL" = "PassThrough" ] || [ "$PAGESPEED_REWRITE_LEVEL" = "CoreFilters" ] || [ "$PAGESPEED_REWRITE_LEVEL" = "OptimizeForBandwidth" ] ; then
    sed -i "s#PAGESPEED_REWRITE_LEVEL_PLACEHOLDER#pagespeed RewriteLevel $PAGESPEED_REWRITE_LEVEL;#g" /etc/nginx/nginx.conf
else
    sed -i "s#PAGESPEED_REWRITE_LEVEL_PLACEHOLDER#pagespeed RewriteLevel CoreFilters;#g" /etc/nginx/nginx.conf
fi

if [[ ! -z "$PAGESPEED_ENABLE_FILTERS" ]] ; then
    sed -i "s#PAGESPEED_ENABLE_FILTERS_PLACEHOLDER#pagespeed EnableFilters $PAGESPEED_ENABLE_FILTERS;#g" /etc/nginx/nginx.conf
else
    sed -i "s#PAGESPEED_ENABLE_FILTERS_PLACEHOLDER##g" /etc/nginx/nginx.conf
fi

if [[ ! -z "$PAGESPEED_DISABLE_FILTERS" ]] ; then
    sed -i "s#PAGESPEED_DISABLE_FILTERS_PLACEHOLDER#pagespeed DisableFilters $PAGESPEED_DISABLE_FILTERS;#g" /etc/nginx/nginx.conf
else
    sed -i "s#PAGESPEED_DISABLE_FILTERS_PLACEHOLDER##g" /etc/nginx/nginx.conf
fi

## Edit site specific config

sed -i "s#WEBROOT_PLACEHOLDER#$NGINX_WEBROOT#g" /etc/nginx/sites-enabled/default.conf

if [ "$PREFER_WWW" = "on" ] || [ "$PREFER_WWW" = "enabled" ] ; then
    sed -i "s#PREFER_NON_WWW_PLACEHOLDER#\##g" /etc/nginx/sites-enabled/default.conf
    sed -i "s#PREFER_WWW_PLACEHOLDER##g" /etc/nginx/sites-enabled/default.conf
else
    sed -i "s#PREFER_WWW_PLACEHOLDER#\##g" /etc/nginx/sites-enabled/default.conf
    sed -i "s#PREFER_NON_WWW_PLACEHOLDER##g" /etc/nginx/sites-enabled/default.conf
fi

if [[ ! -z "$PHP_UPSTREAM_CONTAINER" ]] & [[ ! -z "$PHP_UPSTREAM_PORT" ]] ; then
    echo "upstream php-upstream { server ${PHP_UPSTREAM_CONTAINER}:${PHP_UPSTREAM_PORT}; }" > /etc/nginx/sites-enabled/upstream.conf
fi

# Delete the default site configuration if requested. Don't do this if you've mounted your own!
# This is useful when a third party container wants to manage our configuration (Docker-gen, lets encrypt...)

if [ "$REMOVE_INITIAL_CONFIG" = "on" ] || [ "$REMOVE_INITIAL_CONFIG" = "enabled" ] ; then
    rm /etc/nginx/sites-enabled/default.conf
    rm /etc/nginx/sites-enabled/upstream.conf
fi

exec "$@"
