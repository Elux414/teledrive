FROM node:18.16.0 AS build

WORKDIR /app

ARG REACT_APP_TG_API_ID
ARG REACT_APP_TG_API_HASH
ARG ENV
ARG TG_API_ID
ARG TG_API_HASH
ARG ADMIN_USERNAME
ARG API_JWT_SECRET
ARG FILES_JWT_SECRET
ARG DATABASE_URL
ARG REDIS_URL

# зависимости для native-модулей (ТОЛЬКО build)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

COPY yarn.lock package.json ./
COPY api/package.json api/package.json
COPY web/package.json web/package.json

RUN yarn install --frozen-lockfile --network-timeout 1000000

COPY . .

RUN yarn workspaces run build
RUN yarn server prisma generate

# ОСТАВЛЯЕМ ТОЛЬКО PROD DEPENDENCIES
RUN yarn install --production --ignore-scripts --prefer-offline

FROM node:18.16.0-slim AS runtime
WORKDIR /app

ENV NODE_ENV=production
ENV PRISMA_CLIENT_ENGINE_TYPE=library

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Копируем только нужное
COPY --from=build /app/package.json /app/yarn.lock ./
COPY --from=build /app/node_modules ./node_modules

COPY --from=build /app/api ./api
COPY --from=build /app/web ./web
COPY docker/.env ./web/.env

CMD ["node", "dist/index.js"]
