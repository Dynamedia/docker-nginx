# Nginx with extra modules

This repository contains the build instructions for nginx with the following dynamic modules:

ModSecurity (includes the latest OWASP core ruleset) - Default disabled

Headers More - Default enabled

Geoip2 (Module support but database cannot be distributed - register, download and mount database to use) - Default disabled

Google PageSpeed - Default disabled

Google Brotli - Default enabled

Dynamic modules can be enabled or disabled by required

This image will serve files from /var/www/app on port 80. It is suitable for use as or behind a reverse proxy.

To use alternative configurations simply create your own (eg. nginx.conf, default.conf etc.) and mount them in the correct location.

The pre-built image can be found at https://hub.docker.com/r/dynamedia/nginx/
