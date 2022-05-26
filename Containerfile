ARG ALPINE_VERSION=3.14.1
FROM gautada/alpine:$ALPINE_VERSION as src-postgres
USER root
WORKDIR /
ARG POSTGRES_VERSION=14_3
ARG POSTGRES_BRANCH=REL_"$POSTGRES_VERSION"
RUN apk add --no-cache bison build-base flex git linux-headers libxml2-dev \
                       libxml2-utils libxslt-dev openssl-dev perl \
                       readline-dev zlib-dev
RUN git clone --branch $POSTGRES_BRANCH --depth 1 https://github.com/postgres/postgres.git
WORKDIR /postgres
RUN ./configure \
 && make \
 && make install


FROM gautada/alpine:$ALPINE_VERSION

USER root
WORKDIR /

LABEL source="https://github.com/gautada/postgres-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"
LABEL description="An postgres container"

EXPOSE 5432

RUN apk add --no-cache readline

# /usr/local/pgsql
COPY --from=src-postgres /usr/local/pgsql /usr/local/pgsql

COPY 10-entrypoint.sh /etc/entrypoint.d/10-entrypoint.sh
COPY daily-backup.sh /usr/bin/daily-backup

# ARG USER=postgres
# RUN addgroup $USER \
#  && adduser -D -s /bin/sh -G $USER $USER \
#  && echo "$USER:$USER" | chpasswd
#
# RUN ln -s /usr/local/pgsql/bin/* /usr/bin/ \
#  && mkdir -p /opt/postgres \
#  && chmod 777 /opt/postgres \
#  && chown postgres:postgres /opt/postgres
#
# USER $USER
# WORKDIR /home/$USER


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



