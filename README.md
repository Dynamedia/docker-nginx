# Nginx with extra modules

This repository contains the build instructions for nginx with the following modules:

ModSecurity (includes the latest OWASP core ruleset)

Geoip2 (includes the maxmind geolite2 city database)

PageSpeed

Brotli

These extra modules are disabled by default but can be enabled and configured using environment variables.

Please review .env-example and entrypoint.sh to see available options and their defaults.

This image will, by default, serve files from /var/www/app on port 80 only.

The initial site configuration is at /etc/nginx/sites-available/default.conf. This can be deleted on startup via environment variables but take care when using mounts. It's configured this way because the default configuration will cause problems if using the image in conjunction with third party configuration managers such as docker-gen and the letsencrypt companion (for reverse proxying).

The pre-built image can be found at https://hub.docker.com/r/dynamedia/nginx/
