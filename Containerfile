ARG ALPINE_VERSION=3.14.1

# ╭―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │                                                                         │
# │ STAGE 1: src-postgres - Build postgres from source                      │
# │                                                                         │
# ╰―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM gautada/alpine:$ALPINE_VERSION as src-postgres

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
ARG POSTGRES_VERSION=14_3
ARG POSTGRES_BRANCH=REL_"$POSTGRES_VERSION"

# ╭――――――――――――――――――――╮
# │ PACKAGES           │
# ╰――――――――――――――――――――╯
RUN apk add --no-cache bison build-base flex git linux-headers libxml2-dev \
                       libxml2-utils libxslt-dev openssl-dev perl \
                       readline-dev zlib-dev

# ╭――――――――――――――――――――╮
# │ SOURCE             │
# ╰――――――――――――――――――――╯
RUN git clone --branch $POSTGRES_BRANCH --depth 1 https://github.com/postgres/postgres.git

# ╭――――――――――――――――――――╮
# │ BUILD              │
# ╰――――――――――――――――――――╯
WORKDIR /postgres
RUN ./configure \
 && make \
 && make install

# ╭―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │                                                                         │
# │ STAGE 2: src-pgweb - Build pgweb from source                            │
# │                                                                         │
# ╰―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM gautada/alpine:$ALPINE_VERSION as src-pgweb

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
ARG PGWEB_VERSION=0.11.11
ARG PGWEB_BRANCH=v"$PGWEB_VERSION"

# ╭――――――――――――――――――――╮
# │ PACKAGES           │
# ╰――――――――――――――――――――╯
RUN apk add --no-cache go build-base

# ╭――――――――――――――――――――╮
# │ SOURCE             │
# ╰――――――――――――――――――――╯
RUN git clone --branch $PGWEB_BRANCH --depth 1 https://github.com/sosedoff/pgweb.git

# ╭――――――――――――――――――――╮
# │ BUILD              │
# ╰――――――――――――――――――――╯
WORKDIR /pgweb
RUN make build


# ╭――――――――――――――――-------------------------------------------------------――╮
# │                                                                         │
# │ STAGE 3: postgres-container                                             │
# │                                                                         │
# ╰―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM gautada/alpine:$ALPINE_VERSION

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/postgres-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"
LABEL description="A postgres container with pgweb GUI"

# ╭――――――――――――――――――――╮
# │ PORTS              │
# ╰――――――――――――――――――――╯
EXPOSE 5432/tcp
EXPOSE 8081/tcp

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
RUN /sbin/apk add --no-cache readline
COPY --from=src-postgres /usr/local/pgsql /usr/local/pgsql
RUN /bin/ln -s /usr/local/pgsql/bin/* /usr/bin/
COPY --from=src-pgweb /pgweb/pgweb /usr/bin/pgweb
COPY 10-ep-container.sh /etc/entrypoint.d/10-ep-container.sh
COPY container-backup /etc/periodic/hourly/container-backup
# COPY healthcheck.sh /usr/bin/healthcheck

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG USER=postgres
VOLUME /opt/$USER
RUN /bin/mkdir -p /opt/$USER \
 && /usr/sbin/addgroup $USER \
 && /usr/sbin/adduser -D -s /bin/ash -G $USER $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd \
 && /bin/chown $USER:$USER -R /opt/$USER
 
USER $USER
WORKDIR /home/$USER



