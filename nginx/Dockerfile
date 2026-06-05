FROM ubuntu:22.04 as builder
WORKDIR /tmp
ADD nginx-sticky-module-ng.tar.gz /tmp/
ADD nginx_upstream_check_module-0.4.0.tar.gz /tmp/
ADD openssl-1.0.2k.tar.gz /tmp/
ADD pcre-8.45.tar.gz /tmp/
ADD zlib-1.2.11.tar.gz /tmp/
ADD nginx-1.30.2.tar.gz /tmp/
RUN set -eux; \
    sed -i 's@//.*ports.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget gcc make libssl-dev zlib1g-dev libgd-dev libgeoip-dev libpcre2-dev libpcre3-dev g++; \
    tar xzf nginx-sticky-module-ng.tar.gz; \
    tar xzf nginx_upstream_check_module-0.4.0.tar.gz; \
    tar xzf openssl-1.0.2k.tar.gz; \
    tar xzf pcre-8.45.tar.gz; \
    tar xzf zlib-1.2.11.tar.gz; \
    tar xzf nginx-1.30.2.tar.gz; \
    cd /tmp/nginx-1.30.2; \
    ./configure \
    --with-openssl-opt="no-asm" \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-http_slice_module \
    --with-zlib=/tmp/zlib-1.2.11 \
    --with-pcre=/tmp/pcre-8.45 \
    --with-openssl=/tmp/openssl-1.0.2k \
    --add-module=/tmp/nginx-sticky-module-ng-1.2.6 \
    --add-module=/tmp/nginx_upstream_check_module-0.4.0 \
    --with-http_v2_module; \
    make; \
    make install;
FROM ubuntu:22.04-arm64 as runner
COPY --from=builder /usr/sbin/nginx /usr/sbin/
COPY --from=builder /etc/nginx /etc/nginx
ENV NGINX_VERSION=1.30.2
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV PS1='[\u@\h \W]\$'
ENV TZ=Asia/Shanghai
ADD psutil-5.9.8.tar.gz /
RUN set -eux; \
    sed -i 's@//.*ports.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl wget telnet net-tools iputils-ping dnsutils fontconfig ca-certificates p11-kit tzdata locales python2.7 python2-dev gcc; \
    ln -s /usr/bin/python2.7 /usr/bin/python; \
    tar xzf psutil-5.9.8.tar.gz; \
    cd psutil-5.9.8/; \
    python setup.py install; \
    cd / ;\
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen; \
    locale-gen en_US.UTF-8; \
    rm -rf /var/lib/apt/lists/*; \
    rm -f /psutil-5.9.8.tar.gz; \
    rm -rf /psutil-5.9.8; \
    apt-get --purge autoremove -y python2-dev gcc; \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone; \
    sed -i -e 's/#access_log  logs\/access.log  main;/access_log \/dev\/stdout;/' -e 's/#error_log  logs\/error.log  notice;/error_log stderr notice;/' /etc/nginx/nginx.conf; \
    ldconfig; \
    mkdir /var/log/nginx/; \
    addgroup nginx; \
    adduser --system --home /var/cache/nginx --disabled-login --ingroup nginx nginx;
ENTRYPOINT []
CMD ["nginx", "-g", "daemon off;"]
