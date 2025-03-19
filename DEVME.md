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

<!-- markdownlint-enable MD013 -->
