ARG ALPINE_VERSION=3.14.1

# ╭―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │                                                                         │
# │ STAGE 1: src-postgres - Build postgres from source                      │
# │                                                                         │
# ╰―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM gautada/alpine:$ALPINE_VERSION as src-postgres


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
# │ USER               │
# ╰――――――――――――――――――――╯
ARG UID=1001
ARG GID=1001
ARG USER=postgres
RUN /usr/sbin/addgroup -g $GID $USER \
 && /usr/sbin/adduser -D -G $USER -s /bin/ash -u $UID $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd \
 

# ╭――――――――――――――――――――╮
# │ PORTS              │
# ╰――――――――――――――――――――╯
EXPOSE 5432/tcp
EXPOSE 8081/tcp

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
COPY 10-ep-container.sh /etc/container/entrypoint.d/10-ep-container.sh
COPY 10-ex-postgres.sh /etc/container/exitpoint.d/10-ex-postgres.sh

# ╭――――――――――――――――――――╮
# │ SUDO               │
# ╰――――――――――――――――――――╯
# COPY wheel-chown /etc/container/wheel.d/wheel-chown

# ╭――――――――――――――――――――╮
# │ BACKUP             │
# ╰――――――――――――――――――――╯
COPY backup.fnc /etc/container/backup.fnc
 
# ╭――――――――――――――――――――╮
# │ HEALTHCHECK        │
# ╰――――――――――――――――――――╯
COPY hc-disk.sh /etc/healthcheck.d/hc-disk.sh
COPY hc-postgres.sh /etc/healthcheck.d/hc-postgres.sh
COPY hc-pgweb.sh /etc/healthcheck.d/hc-pgweb.sh


RUN /bin/mkdir -p /opt/$USER /run/postgresql /var/backup /opt/backup /temp/backup \
 && /bin/chown -R $USER:$USER /opt/$USER /run/postgresql /var/backup /tmp/backup /opt/backup
 
USER $USER
WORKDIR /home/$USER
VOLUME /opt/$USER

