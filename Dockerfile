FROM alpine:3.12.1 as config-alpine

RUN apk add --no-cache tzdata

RUN cp -v /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone


FROM alpine:3.12.1 as src-postgres

RUN apk add --no-cache bison \
                       build-base \
                       flex \
                       git \
                       linux-headers \
                       libxml2-dev \
                       libxml2-utils \
                       libxslt-dev \
                       openssl-dev \
                       perl \
                       readline-dev \
                       zlib-dev
	
RUN git clone --branch REL_13_STABLE --depth 1 https://github.com/postgres/postgres.git

WORKDIR /postgres

RUN ./configure \
 && make \
 && make install

FROM alpine:3.12.1

EXPOSE 5432

RUN apk add --no-cache readline

COPY --from=config-alpine /etc/localtime /etc/localtime
COPY --from=config-alpine /etc/timezone /etc/timezone

# /usr/local/pgsql
COPY --from=src-postgres /usr/local/pgsql /usr/local/pgsql

COPY entrypoint /entrypoint

RUN ln -s /usr/local/pgsql/bin/* /usr/bin/ \
 && adduser -D -s /bin/sh postgres \
 && echo 'postgres:postgres' | chpasswd \
 && mkdir -p /opt/postgres-data \
 && chmod 777 /opt/postgres-data \
 && chown postgres:postgres /opt/postgres-data

USER postgres

ENTRYPOINT ["/entrypoint"]
# ENTRYPOINT ["tail", "-f", "/dev/null"]
