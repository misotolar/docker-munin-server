FROM misotolar/alpine:3.23.2

LABEL org.opencontainers.image.url="https://github.com/misotolar/docker-munin-server"
LABEL org.opencontainers.image.description="Munin Server Alpine Linux image"
LABEL org.opencontainers.image.authors="Michal Sotolar <michal@sotolar.com>"

ENV MUNIN_VERSION=2.999.18
ENV MUNIN_SHA256=400d0b316f966839a735842aa6d628cf89f6f2ff8011ff955998fe4caed27312
ADD https://github.com/munin-monitoring/munin/archive/refs/tags/$MUNIN_VERSION.tar.gz /tmp/munin.tar.gz

ENV MUNIN_USER_UID=116
ENV MUNIN_HTTPD_HOST=localhost
ENV MUNIN_HTTPD_PORT=4948
ENV MUNIN_WORKERS=16
ENV MUNIN_TIMEOUT=20

WORKDIR /build

RUN set -ex; \
    apk add --no-cache \
        bash \
        expat \
        font-dejavu \
        gettext-envsubst \
        pcre \
        perl-cgi \
        perl-dbd-sqlite \
        perl-html-template \
        perl-http-server-simple \
        perl-io-socket-inet6 \
        perl-json \
        perl-list-moreutils \
        perl-lwp-useragent-determined \
        perl-log-dispatch \
        perl-net-server \
        perl-net-snmp \
        perl-net-ssleay \
        perl-parallel-forkmanager \
        perl-params-validate \
        perl-rrd \
        perl-xml-parser \
        rrdtool \
        tzdata \
        runit \
    ; \
    apk add --no-cache --virtual .build-deps \
        pcre-dev \
        expat-dev \
        perl-app-cpanminus \
        perl-module-build \
        perl-dev \
        grep \
        make \
        g++ \
    ; \
    cpanm --notest \
        HTML::Template::Pro \
        HTTP::Server::Simple::CGI::PreFork \
        XML::Dumper \
    ; \
    adduser -u $MUNIN_USER_UID -D -S -G www-data munin; \
    echo "$MUNIN_SHA256 */tmp/munin.tar.gz" | sha256sum -c -; \
    tar xf /tmp/munin.tar.gz --strip-components=1; \
    echo $MUNIN_VERSION | tee RELEASE; \
    perl Build.PL \
        --install_path etc=/usr/local/munin \
    ; \
    ./Build; \
    ./Build install; \
    mkdir -p /usr/local/munin/conf.d; \
    install -m 755 -d -o munin -g www-data \
        /usr/local/munin/data \
        /usr/local/munin/logs \
        /var/run/munin \
    ; \
    ln -fs /usr/local/munin/data /var/lib/munin; \
    ln -fs /usr/local/munin/logs /var/log/munin; \
    apk del --no-network .build-deps; \
    rm -rf \
        /build \
        /root/.cpanm \
        /var/log/apk.log \
        /var/cache/apk/* \
        /var/tmp/* \
        /tmp/*

WORKDIR /usr/local/munin

COPY resources/service /etc/service
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY resources/munin.conf /usr/local/munin/munin.conf.docker

VOLUME /usr/local/munin/data
VOLUME /usr/local/munin/logs
VOLUME /usr/local/munin/conf.d

STOPSIGNAL SIGTERM
ENTRYPOINT ["entrypoint.sh"]
CMD ["runsvdir", "-P", "/etc/service"]
