ARG ALPINE_VERSION=3.14.1

# ╭―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │                                                                         │
# │ STAGE: Build pgweb from source                                          │
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
# │                                                                     │
# │ STAGE: Postgres container                                           │
# │                                                                     │
# ╰―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM gautada/alpine:$ALPINE_VERSION

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/postgres-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"
LABEL description="A postgres container with pgweb GUI"

# ╭――――――――――――――――――――╮
# │ STANDARD CONFIG    │
# ╰――――――――――――――――――――╯

# USER:
ARG USER=postgres

ARG UID=1000
ARG GID=1003
RUN /usr/sbin/addgroup -g $GID $USER \
 && /usr/sbin/adduser -D -G $USER -s /bin/ash -u $UID $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd

# PRIVILEGE:
# COPY wheel  /etc/container/wheel

# BACKUP:
COPY backup /etc/container/backup

# ENTRYPOINT:
RUN rm -v /etc/container/entrypoint
COPY entrypoint /etc/container/entrypoint

# FOLDERS
RUN /bin/chown -R $USER:$USER /mnt/volumes/container \
 && /bin/chown -R $USER:$USER /mnt/volumes/backup \
 && /bin/chown -R $USER:$USER /var/backup \
 && /bin/chown -R $USER:$USER /tmp/backup

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
ARG POSTGRES_MAJOR="15"
ARG POSTGRES_MINOR="1"
ARG POSTGRES_RELEASE="r1"

ARG POSTGRES_PACKAGE="postgresql$POSTGRES_MAJOR=$POSTGRES_MAJOR.$POSTGRES_MINOR-$POSTGRES_RELEASE"

RUN /sbin/apk add --no-cache readline $POSTGRES_PACKAGE
RUN /sbin/apk add --no-cache py3-psycopg

COPY --from=src-pgweb /pgweb/pgweb /usr/bin/pgweb

RUN /bin/ln -fsv /mnt/volumes/configmaps/postgresql.conf /etc/container/postgresql.conf \
 && /bin/ln -fsv /mnt/volumes/container/datastore/postgresql.conf~ /mnt/volumes/configmaps/postgresql.conf

RUN /bin/ln -fsv /mnt/volumes/configmaps/pg_hba.conf /etc/container/pg_hba.conf \
 && /bin/ln -fsv /mnt/volumes/container/datastore/pg_hba.conf~ /mnt/volumes/configmaps/pg_hba.conf

RUN /bin/ln -fsv /mnt/volumes/configmaps/pg_ident.conf /etc/container/pg_ident.conf \
 && /bin/ln -fsv /mnt/volumes/container/datastore/pg_ident.conf~ /mnt/volumes/configmaps/pg_ident.conf
 
RUN /bin/mkdir -p /run/postgresql \
 && /bin/chown -R $USER:$USER /run/postgresql

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯
USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
EXPOSE 8080/tcp 5432/tcp
WORKDIR /home/$USER
