#!/bin/bash

set -e

POSTGRES_CONTAINER_NAME="$(docker ps --filter "name=postgres" --format "{{.Names}}")"
LIFERAY_CONTAINER_NAME="$(docker ps --filter "name=liferay" --format "{{.Names}}")"

restore_database() {
  DUMP_FILE=$(docker exec "$POSTGRES_CONTAINER_NAME" sh -c 'ls /dump/*.sql | head -n 1')
  if [ -z "$DUMP_FILE" ]; then
    echo "Nenhum arquivo de dump encontrado em /dump/."
    exit 1
  fi
  echo "Derrubando e recriando o banco de dados..."
  docker exec "$POSTGRES_CONTAINER_NAME" psql -U liferay -c "DROP DATABASE lportal;"
  docker exec "$POSTGRES_CONTAINER_NAME" psql -U liferay -c "CREATE DATABASE lportal;"
  echo "Restaurando dump: $DUMP_FILE"
  docker exec -i "$POSTGRES_CONTAINER_NAME" psql -U liferay -d lportal < "$DUMP_FILE"
  echo "Banco de dados restaurado com sucesso."
  restart_liferay
}

atualize_database() {
  DUMP_FILE=$(docker exec "$POSTGRES_CONTAINER_NAME" sh -c 'ls /dump/*.sql | head -n 1')
  if [ -z "$DUMP_FILE" ]; then
    echo "Nenhum arquivo de dump encontrado em /dump/."
    exit 1
  fi
  echo "Atualizando banco de dados com o novo dump: $DUMP_FILE"
  docker exec -i "$POSTGRES_CONTAINER_NAME" psql -U liferay -d lportal < "$DUMP_FILE"
  echo "Banco de dados atualizado com sucesso."
  restart_liferay
}

restart_liferay() {
  echo "Reiniciando o container do Liferay..."
  docker restart "$LIFERAY_CONTAINER_NAME"
  echo "Liferay reiniciado com sucesso."
}

case "$1" in
  restore)
    restore_database
    ;;
  update)
    atualize_database
    ;;
  *)
    echo "Uso: $0 {restore|update}"
    exit 1
    ;;
esac
