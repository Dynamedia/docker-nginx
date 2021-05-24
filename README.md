# Nginx with extra modules

This repository contains the build instructions for Nginx with the following dynamic modules:

ModSecurity (includes the latest OWASP core ruleset) - Default disabled

Headers More - Default enabled

Geoip2 (Module support but database cannot be distributed - register, download and mount database to use) - Default disabled

Google PageSpeed - Default unplugged (disabled)

Google Brotli - Default enabled

This image will serve files from /var/www/app on port 80. It is suitable for use both as or behind a reverse proxy.

To use alternative configurations simply create your own (eg. nginx.conf, default.conf etc.) and mount them in the correct location or you can modify and rebuild.

The pre-built image can be found at https://hub.docker.com/r/dynamedia/docker-nginx/
