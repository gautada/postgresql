# PostgeSQL

https://docs.docker.com/engine/examples/postgresql_service/

## Container

### Build Script
```docker build --tag psql:$(date '+%Y-%m-%d')-build . && docker tag psql:$(date '+%Y-%m-%d')-build psql:latest```

### Run Script
```docker run -Pit --rm --name psql psql:latest /bin/bash```

### Deploy Script
```docker tag psql:latest localhost:32000/psql:latest && docker push localhost:32000/psql:latest```

Set listen_addresses = 'localhost' to listen_addresses = '*' 
