ARG ALPINE_VERSION=3.22

# │ STAGE: CONTAINER
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――
FROM gautada/alpine:$ALPINE_VERSION as CONTAINER

# ╭――――――――――――――――――――╮
# │ VARIABLES          │
# ╰――――――――――――――――――――╯
ARG IMAGE_NAME="postgresql"
ARG IMAGE_VERSION="15.11-r0"
# ARG POSTGRES_MAJOR="15"
# ARG POSTGRES="postgresql${POSTGRES_MAJOR}"
# ARG POSTGRES_PACKAGE="${POSTGRES}=${IMAGE_VERSION}"

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A PostgreSQL database container."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.source="https://github.com/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.license="Upstream"

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
SHELL ["/bin/ash", "-o", "pipefail", "-c"]
ARG USER=postgres
RUN /usr/sbin/usermod -l $USER alpine \
  && /usr/sbin/usermod -d /home/$USER -m $USER \
  && /usr/sbin/groupmod -n $USER alpine \
  && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd

# ╭―
# │ BACKUP
# ╰――――――――――――――――――――
# COPY backup /etc/container/backup
COPY backup.sh /usr/bin/backup
RUN /bin/rm /etc/periodic/hourly/container-backup \
  && /bin/ln -fsv /usr/bin/backup /etc/periodic/15min/backup


# ╭―
# │ ENTRYPOINT
# ╰――――――――――――――――――――
# Overwrite upstream entrypoint
COPY entrypoint.sh /usr/bin/container-entrypoint

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
RUN  MAJOR_VERSION="$(echo "${IMAGE_VERSION}" | cut -d . -f1)" \
 && POSTGRESQL_PACKAGE="${IMAGE_NAME}${MAJOR_VERSION}" \
 && echo "${POSTGRESQL_PACKAGE}" \
 && echo "${MAJOR_VERSION}" \
 && echo "------------------------------------------------------------------" \
 && /bin/sed -i 's|dl-cdn.alpinelinux.org/alpine/|mirror.math.princeton.edu/pub/alpinelinux/|g' /etc/apk/repositories \
 && /sbin/apk add --no-cache readline "${POSTGRESQL_PACKAGE}=${IMAGE_VERSION}" \
  "${POSTGRESQL_PACKAGE}-contrib" py3-psycopg bash\
 && /bin/ln -fsv /mnt/volumes/configmaps/postgresql.conf \
  /etc/container/postgresql.conf \
 && /bin/ln -fsv /mnt/volumes/configmaps/pg_hba.conf \
  /etc/container/pg_hba.conf \
 && /bin/ln -fsv /mnt/volumes/configmaps/pg_ident.conf \
  /etc/container/pg_ident.conf \
 && /bin/mkdir -p /run/postgresql \
 && /bin/chown -R $USER:$USER /run/postgresql \
 && mkdir -p /etc/container/secrets \
 && /bin/chown -R $USER:$USER /etc/container/secrets 

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
