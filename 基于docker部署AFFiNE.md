#  创建token 值
本次拉取的镜像在 github 的官方仓库，先创建一个 token 值

[https://github.com/settings/tokens/new](https://github.com/settings/tokens/new)



![](https://cdn.nlark.com/yuque/0/2024/png/38872479/1719895546823-1e979ec7-b435-4163-8c31-b1546a80c221.png)



## 登录
```bash
#登录

echo "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" | docker login ghcr.io -u 1905801933@qq.com --password-stdin



root@docker-node01:/apps# echo "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" | docker login ghcr.io -u 1905801933@qq.com --password-stdin 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

```





```yaml
services:
  affine:
    image: ghcr.io/toeverything/affine-graphql:stable
    container_name: affine_selfhosted
    command:
      ['sh', '-c', 'node ./scripts/self-host-predeploy && node ./dist/index.js']
    ports:
      - '3010:3010'
      - '5555:5555'
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    volumes:
      # custom configurations
      - ./affine/self-host/config:/root/.affine/config
      # blob storage
      - ./affine/self-host/storage:/root/.affine/storage
    logging:
      driver: 'json-file'
      options:
        max-size: '1000m'
    restart: unless-stopped
    environment:
      - NODE_OPTIONS="--import=./scripts/register.js"
      - AFFINE_CONFIG_PATH=/root/.affine/config
      - REDIS_SERVER_HOST=redis
      - DATABASE_URL=postgres://affine:affine@postgres:5432/affine
      - NODE_ENV=production
      - AFFINE_ADMIN_EMAIL=admin@123.com
      - AFFINE_ADMIN_PASSWORD=admin
        #- AFFINE_ADMIN_EMAIL=${AFFINE_ADMIN_EMAIL}
        #- AFFINE_ADMIN_PASSWORD=${AFFINE_ADMIN_PASSWORD}
      # Telemetry allows us to collect data on how you use the affine. This data will helps us improve the app and provide better features.
      # Uncomment next line if you wish to quit telemetry.
      # - TELEMETRY_ENABLE=false
  redis:
    image: redis:7.4-rc2-alpine3.20
    container_name: affine_redis
    restart: unless-stopped
    volumes:
      - ./affine/self-host/redis:/data
    healthcheck:
      test: ['CMD', 'redis-cli', '--raw', 'incr', 'ping']
      interval: 10s
      timeout: 5s
      retries: 5
  postgres:
    image: postgres:latest
    container_name: affine_postgres
    restart: unless-stopped
    volumes:
      - ./affine/self-host/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U affine']
      interval: 10s
      timeout: 5s
      retries: 5
    environment:
      POSTGRES_USER: affine
      POSTGRES_PASSWORD: affine
      POSTGRES_DB: affine
      PGDATA: /var/lib/postgresql/data/pgdata

```

