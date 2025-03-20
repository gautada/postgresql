# Development Notes

## Containers

Launch the container

<!-- markdownlint-disable MD013 -->

```sh
/usr/bin/podman run --interactive --name postgresql01 --rm --tty --volume Backup:/mnt/volumes/backups --volume Data:/mnt/volumes/container --volume Configmaps:/mnt/volumes/configmaps --volume Secrets:/mnt/volumes/secrets docker.io/gautada/postgresql:dev 
```

```sh
/usr/bin/podman run --interactive --name postgresql02 --rm --tty --volume Backup:/mnt/volumes/backups --volume Data:/mnt/volumes/container --volume Configmaps:/mnt/volumes/configmaps --volume Secrets:/mnt/volumes/secrets docker.io/gautada/postgresql:dev 
```

```sh
/usr/bin/podman volume create --driver local --opt type=none --opt device=/mnt/host/backup --opt o=bind Backup
/usr/bin/podman volume create --driver local --opt type=none --opt device=/mnt/host/data --opt o=bind Data
/usr/bin/podman volume create --driver local --opt type=none --opt device=/mnt/host/configmaps --opt o=bind Configmaps
/usr/bin/podman volume create --driver local --opt type=none --opt device=/mnt/host/secrets  --opt o=bind Secrets
```

```sh
/usr/bin/podman run --interactive --name postgresql01 --rm --tty --volume /mnt/host/backup:/mnt/volumes/backups --volume /mnt/host/data:/mnt/volumes/container --volume /mnt/host/configmaps:/mnt/volumes/configmaps --volume /mnt/host/secrets:/mnt/volumes/secrets docker.io/gautada/postgresql:dev 
```

<!-- markdownlint-enable MD013 -->
