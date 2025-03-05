ARG ALPINE_VERSION=latest

# │ STAGE: CONTAINER
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――
FROM gautada/alpine:$ALPINE_VERSION as CONTAINER

# ╭――――――――――――――――――――╮
# │ VARIABLES          │
# ╰――――――――――――――――――――╯
ARG IMAGE_VERSION="15.11-r0"
ARG POSTGRES_MAJOR="15"
ARG POSTGRES="postgresql${POSTGRES_MAJOR}"
ARG POSTGRES_PACKAGE="${POSTGRES}=${IMAGE_VERSION}"

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="postgresql"
LABEL org.opencontainers.image.description="A PostgreSQL database container."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/postgresql"
LABEL org.opencontainers.image.source="https://github.com/gautada/postgresql"
LABEL org.opencontainers.image.version="${CONTAINER_VERSION}"
LABEL org.opencontainers.image.license="Upstream"

# ╭―
# │ USER
# ╰――――――――――――――――――――
ARG USER=postgres
RUN /usr/sbin/usermod -l $USER alpine \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER alpine \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd \

# ╭―
# │ BACKUP
# ╰――――――――――――――――――――
COPY backup /etc/container/backup

# ╭―
# │ ENTRYPOINT
# ╰――――――――――――――――――――
COPY entrypoint /etc/container/entrypoint

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
RUN /sbin/apk add --no-cache readline \
                            "${POSTGRES_PACKAGE}" \
                            "${POSTGRES}-contrib" \
                            py3-psycopg
RUN /bin/ln -fsv /mnt/volumes/configmaps/postgresql.conf \
                /etc/container/postgresql.conf \
 && /bin/ln -fsv /mnt/volumes/configmaps/pg_hba.conf \
                /etc/container/pg_hba.conf \
 && /bin/ln -fsv /mnt/volumes/configmaps/pg_ident.conf \
                /etc/container/pg_ident.conf \
 && /bin/mkdir -p /run/postgresql \
 && /bin/chown -R $USER:$USER /run/postgresql

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯
USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
VOLUME /mnt/volumes/secrets
EXPOSE 5432/tcp
WORKDIR /home/$USER
