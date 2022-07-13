ARG ALPINE_VERSION=3.14.1

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

# ╭―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │                                                                      │
# │ STAGE 3: postgres-container                                          │
# │                                                                      │
# ╰―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM gautada/alpine:$ALPINE_VERSION

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/postgres-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"
LABEL description="A postgres container with pgweb GUI"

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG UID=1001
ARG GID=1001
ARG USER=postgres
RUN /usr/sbin/addgroup -g $GID $USER \
 && /usr/sbin/adduser -D -G $USER -s /bin/ash -u $UID $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd
 

# ╭――――――――――――――――――――╮
# │ PORTS              │
# ╰――――――――――――――――――――╯
EXPOSE 5432/tcp
EXPOSE 8081/tcp

# ╭――――――――――――――――――――╮
# │ CONFIG             │
# ╰――――――――――――――――――――╯
RUN rm -rf /etc/postgres
RUN ln -s /etc/container/configmap.d /etc/postgres

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
ARG POSTGRES_VERSION=14.3
ARG POSTGRES_PACKAGE="$POSTGRES_VERSION"-r0

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
RUN /sbin/apk add --no-cache readline postgresql14=$POSTGRES_PACKAGE
COPY --from=src-pgweb /pgweb/pgweb /usr/bin/pgweb
RUN ln -s /opt/postgres/datastore/postgresql.conf /etc/postgres/postgresql.conf \
 && ln -s /opt/postgres/datastore/pg_hba.conf /etc/postgres/pg_hba.conf \
 && ln -s /opt/postgres/datastore/pg_ident.conf /etc/postgres/pg_ident.conf
COPY 10-ep-container.sh /etc/container/entrypoint.d/10-ep-container.sh
# COPY 10-ex-postgres.sh /etc/container/exitpoint.d/10-ex-postgres.sh

# ╭――――――――――――――――――――╮
# │ SUDO               │
# ╰――――――――――――――――――――╯
# COPY wheel-chown /etc/container/wheel.d/wheel-chown

# ╭――――――――――――――――――――╮
# │ BACKUP             │
# ╰――――――――――――――――――――╯
COPY backup.fnc /etc/container/backup.d/backup.fnc
 
# ╭――――――――――――――――――――╮
# │ HEALTHCHECK        │
# ╰――――――――――――――――――――╯
COPY hc-disk.sh /etc/container/healthcheck.d/hc-disk.sh
COPY hc-postgres.sh /etc/container/healthcheck.d/hc-postgres.sh
COPY hc-pgweb.sh /etc/container/healthcheck.d/hc-pgweb.sh


RUN /bin/mkdir -p /opt/$USER /run/postgresql /var/backup /opt/backup /temp/backup \
 && /bin/chown -R $USER:$USER /opt/$USER /etc/postgres /run/postgresql /var/backup /tmp/backup /opt/backup
 
USER $USER
WORKDIR /home/$USER
VOLUME /opt/$USER

