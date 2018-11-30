# Build ModSecurity

FROM debian:9-slim as modsecurity-build
MAINTAINER Rob Ballantyne admin@dynamedia.uk

# Install Prereqs

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq && \
    apt install  -qq -y --no-install-recommends --no-install-suggests \
    ca-certificates      \
    automake             \
    autoconf             \
    build-essential      \
    libcurl4-openssl-dev \
    libpcre++-dev        \
    libtool              \
    libxml2-dev          \
    libyajl-dev          \
    lua5.2-dev           \
    git                  \
    pkgconf              \
    ssdeep               \
    libgeoip-dev         \
    wget             &&  \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cd /opt && \
    git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
    cd ModSecurity && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && \
    make && \
    make install && \
    strip /usr/local/modsecurity/bin/* /usr/local/modsecurity/lib/*.a /usr/local/modsecurity/lib/*.so*

RUN cd /opt && \
    git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git



# Build Nginx

FROM debian:9-slim AS nginx-build
MAINTAINER Rob Ballantyne admin@dynamedia.uk

ENV DEBIAN_FRONTEND noninteractive
ENV NGINX_VERSION 1.15.7
ENV NPS_VERSION 1.13.35.2-
ENV NPS_TYPE stable
ENV ARCHITECTURE x64

# Install geoip2 and build prereqs

RUN apt update && \
    apt install  -qq -y --no-install-recommends --no-install-suggests \
    ca-certificates \
    autoconf        \
    automake        \
    build-essential \
    libtool         \
    pkgconf         \
    wget            \
    git             \
    zlib1g-dev      \
    libssl-dev      \
    libpcre3-dev    \
    libxml2-dev     \
    libyajl-dev     \
    lua5.2-dev      \
    libgeoip-dev    \
    libcurl4-openssl-dev    \
    openssl \
    libmaxminddb0 \
    libmaxminddb-dev \
    mmdb-bin \
    unzip \
    uuid-dev

RUN cd /opt && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    git clone https://github.com/google/ngx_brotli && \
    cd /opt/ngx_brotli && \
    git submodule update --init --recursive && \
    cd /opt && \
    git clone https://github.com/leev/ngx_http_geoip2_module && \
    cd /opt && \
    mkdir mmdb && \
    cd /opt/mmdb && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz && \
    gunzip GeoLite2-City.mmdb.gz && \
    cd /opt && \
    wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}${NPS_TYPE}.zip && \
    unzip v${NPS_VERSION}${NPS_TYPE}.zip && \
    cd incubator-pagespeed-ngx-${NPS_VERSION}${NPS_TYPE} && \
    wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}${ARCHITECTURE}.tar.gz && \
    tar -xzvf ${NPS_VERSION}${ARCHITECTURE}.tar.gz && \
    cd /opt

COPY --from=modsecurity-build /usr/local/modsecurity/ /usr/local/modsecurity/

RUN wget -q -P /opt https://nginx.org/download/nginx-"$NGINX_VERSION".tar.gz && \
    tar xvzf /opt/nginx-"$NGINX_VERSION".tar.gz -C /opt && \
    cd /opt/nginx-"$NGINX_VERSION" && \
    ./configure \
        --prefix=/usr/local/nginx \
        --sbin-path=/usr/local/nginx/nginx \
        --modules-path=/usr/local/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --user=nginx \
        --group=nginx \
        --with-pcre-jit \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_sub_module \
        --with-http_stub_status_module \
        --with-http_v2_module \
        --with-http_secure_link_module \
        --with-stream \
        --with-stream_realip_module \
        --add-module=/opt/ModSecurity-nginx \
        --add-module=/opt/ngx_brotli \
        --add-module=/opt/ngx_http_geoip2_module \
        --add-module=/opt/incubator-pagespeed-ngx-${NPS_VERSION}${NPS_TYPE} \
        --with-cc-opt='-g -O2 -specs=/usr/share/dpkg/no-pie-compile.specs -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
        --with-ld-opt='-specs=/usr/share/dpkg/no-pie-link.specs -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
        --with-http_dav_module

RUN cd /opt/nginx-"$NGINX_VERSION" && \
    make && \
    make install && \
    make modules

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/local/nginx/nginx", "-g", "daemon off;"]

# Build production container

FROM debian:9-slim
MAINTAINER Rob Ballantyne admin@dynamedia.uk

ENV DEBIAN_FRONTEND noninteractive

# Libraries for ModSecurity
RUN apt update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        ca-certificates \
        libcurl4-openssl-dev  \
        libyajl-dev \
        lua5.2-dev \
        libgeoip-dev \
        vim \
        libxml2 \
        libmaxminddb0 \
        libmaxminddb-dev \
        mmdb-bin && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* &&\
    ldconfig

COPY --from=modsecurity-build /usr/local/modsecurity/ /usr/local/modsecurity/

COPY --from=nginx-build /usr/local/nginx/ /usr/local/nginx/

COPY --from=nginx-build /etc/nginx/ /etc/nginx/

COPY --from=nginx-build /opt/mmdb/GeoLite2-City.mmdb /etc/nginx/GeoLite2-City.mmdb

COPY --from=modsecurity-build /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsecurity.d/modsecurity.conf

COPY --from=modsecurity-build /opt/ModSecurity/unicode.mapping /etc/nginx/modsecurity.d/unicode.mapping

COPY --from=modsecurity-build /opt/owasp-modsecurity-crs/crs-setup.conf.example /etc/nginx/modsecurity.d/owasp.conf

COPY --from=modsecurity-build /opt/owasp-modsecurity-crs/rules /etc/nginx/modsecurity.d/rules

# Create required files and directories
RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/www/app && \
    cp /usr/local/nginx/html/* /var/www/app && \
    mkdir -p /etc/nginx/modsecurity.d && \
    mkdir -p /var/cache/nginx/standard_cache && \
    mkdir -p /var/cache/nginx/micro_cache && \
    mkdir -p /var/cache/nginx/ngx_pagespeed && \
    mkdir -p /var/log/nginx

COPY ./nginx.conf /etc/nginx/nginx.conf

COPY ./sites-enabled/ /etc/nginx/sites-enabled/

COPY ./MMDB_LICENCE /

RUN echo "Include /etc/nginx/modsecurity.d/owasp.conf" >> /etc/nginx/modsecurity.d/modsecurity.conf && \
    echo "Include /etc/nginx/modsecurity.d/rules/*.conf" >> /etc/nginx/modsecurity.d/modsecurity.conf && \
    ln -s /usr/local/nginx/nginx /usr/local/bin

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

STOPSIGNAL SIGTERM

CMD ["nginx"]