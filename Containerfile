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
RUN git config --global advice.detachedHead false
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
RUN apk add --no-cache go build-base git

# ╭――――――――――――――――――――╮
# │ SOURCE             │
# ╰――――――――――――――――――――╯
RUN git config --global advice.detachedHead false
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

# ╭――――――――――――――――――――╮
# │ BACKUP             │
# ╰――――――――――――――――――――╯
COPY container-backup.fnc /etc/backup/backup.d/container-backup.fnc
 
# ╭――――――――――――――――――――╮
# │ HEALTHCHECK        │
# ╰――――――――――――――――――――╯
COPY hc-disk.sh /etc/healthcheck.d/hc-disk.sh
COPY hc-postgres.sh /etc/healthcheck.d/hc-postgres.sh
COPY hc-pgweb.sh /etc/healthcheck.d/hc-pgweb.sh

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG USER=postgres
# VOLUME /opt/$USER
RUN /bin/mkdir -p /opt/$USER /var/backup /opt/backup /temp/backup \
 && /usr/sbin/addgroup -g 1001 $USER \
 && /usr/sbin/adduser -D -s /bin/ash -G $USER -u 1001 $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd \
 && /bin/chown $USER:$USER -R /opt/$USER /etc/backup /var/backup /tmp/backup /opt/backup
USER $USER
WORKDIR /home/$USER



