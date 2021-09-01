ARG ALPINE_TAG=3.14.1
FROM alpine:$ALPINE_TAG as config-alpine

RUN apk add --no-cache tzdata

RUN cp -v /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone

FROM alpine:$ALPINE_TAG as src-postgres

ARG BRANCH=v0.0.0
RUN apk add --no-cache bison build-base flex \
                       git linux-headers libxml2-dev \
                       libxml2-utils libxslt-dev \
                       openssl-dev perl \
                       readline-dev zlib-dev
	
RUN git clone --branch $BRANCH --depth 1 https://github.com/postgres/postgres.git

WORKDIR /postgres

RUN ./configure \
 && make \
 && make install

FROM alpine:$ALPINE_TAG

EXPOSE 5432

RUN apk add --no-cache readline

COPY --from=config-alpine /etc/localtime /etc/localtime
COPY --from=config-alpine /etc/timezone /etc/timezone

# /usr/local/pgsql
COPY --from=src-postgres /usr/local/pgsql /usr/local/pgsql

COPY entrypoint.sh /usr/bin/entrypoint
COPY backup.sh /usr/bin/backup

ARG USER=postgres
RUN addgroup $USER \
 && adduser -D -s /bin/sh -G $USER $USER \
 && echo "$USER:$USER" | chpasswd
 
RUN ln -s /usr/local/pgsql/bin/* /usr/bin/ \
 && mkdir -p /opt/postgres-data \
 && chmod 777 /opt/postgres-data \
 && chown postgres:postgres /opt/postgres-data

USER $USER

ENTRYPOINT ["/usr/bin/entrypoint"]

