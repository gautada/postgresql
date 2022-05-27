ARG ALPINE_VERSION=3.14.1

# ╭――――――――――――――――---------------------------------------------------------――╮
# │                                                                           │
# │ STAGE 1: src-postgres - Build postgres from source                        │
# │                                                                           │
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

# ╭――――――――――――――――---------------------------------------------------------――╮
# │                                                                           │
# │ STAGE 2: postgres-container                                                                           │
# │                                                                           │
# ╰―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM gautada/alpine:$ALPINE_VERSION

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/postgres-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"
LABEL description="An postgres container"

# ╭――――――――――――――――――――╮
# │ PORTS              │
# ╰――――――――――――――――――――╯
EXPOSE 5432

# ╭――――――――――――――――――――╮
# │ PACKAGES           │
# ╰――――――――――――――――――――╯
RUN apk add --no-cache readline

# /usr/local/pgsql
COPY --from=src-postgres /usr/local/pgsql /usr/local/pgsql

COPY 10-entrypoint.sh /etc/entrypoint.d/10-entrypoint.sh
COPY daily-backup.sh /usr/bin/daily-backup
COPY healthcheck.sh /usr/bin/healthcheck

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



