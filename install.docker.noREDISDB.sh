#!/bin/bash

set -e

echo "Node Version: $(node -v)"
echo "cURL Version: $(curl --version | head -n 1)"
echo "Docker Version: $(docker -v)"
echo "Docker Compose Version: $(docker compose version)"

if [ ! -f docker/.env ]
then
  echo "Generating .env file..."

  ENV="develop"

  echo "Preparing your keys from https://my.telegram.org/"
  read -p "Enter your TG_API_ID: " TG_API_ID
  read -p "Enter your TG_API_HASH: " TG_API_HASH

  echo
  read -p "Enter your ADMIN_USERNAME: " ADMIN_USERNAME
  read -p "Enter your DATABASE_URL: " DATABASE_URL
  read -p "Enter your PORT: " PORT
  read -p "Enter your REDIS_URL: " REDIS_URL
  PORT="${PORT:=4000}"

  echo "ENV=$ENV" > docker/.env
  echo "PORT=$PORT" >> docker/.env
  echo "TG_API_ID=$TG_API_ID" >> docker/.env
  echo "TG_API_HASH=$TG_API_HASH" >> docker/.env
  echo "ADMIN_USERNAME=$ADMIN_USERNAME" >> docker/.env
  echo "DATABASE_URL=$DATABASE_URL" >> docker/.env
  echo "REDIS_URL=$REDIS_URL" >> docker/.env

  cd docker
  docker compose build teledrive
  docker compose up -d
  sleep 2
  docker compose exec teledrive yarn workspace api prisma migrate reset
  docker compose exec teledrive yarn workspace api prisma migrate deploy
else
  # git pull origin main

  export $(cat docker/.env | xargs)

  cd docker
  docker compose down
  docker compose up --build --force-recreate -d
  sleep 2
  docker compose up -d
  docker compose exec teledrive yarn workspace api prisma migrate deploy
  ## git reset --hard
  ## git clean -f
  ## git pull origin main
fi
