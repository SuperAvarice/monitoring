#!/bin/bash

PROJECT="monitoring"
COMPOSE_CMD="docker-compose"
ENV_FILE="./.env"; source ${ENV_FILE}

if [[ -z "$@" ]]; then
    echo >&2 "Usage: $0 <command>"
    echo >&2 "command = pull, up, down, init, clean, logs, restart"
    exit 1
fi

case "$1" in
    pull)
        ${COMPOSE_CMD} -p "${PROJECT}" pull
    ;;
    up)
        ${COMPOSE_CMD} -p "${PROJECT}" up -d
    ;;
    down)
        ${COMPOSE_CMD} -p "${PROJECT}" down
    ;;
    init)
        echo "Copy configs to ${DATA_DIR}"
        sudo mkdir -p ${DATA_DIR}/grafana/data
        sudo mkdir -p ${DATA_DIR}/grafana/provisioning
        sudo mkdir -p ${DATA_DIR}/influx/data
        sudo mkdir -p ${DATA_DIR}/influx/setup-data
        sudo mkdir -p ${DATA_DIR}/chronograf/data
        sudo cp -R ./grafana/provisioning ${DATA_DIR}/grafana/
    ;;
    clean)
        ${COMPOSE_CMD} -p "${PROJECT}" down -v
    ;;
    logs)
        ${COMPOSE_CMD} -p "${PROJECT}" logs $2
    ;;
    restart)
        ${COMPOSE_CMD} -p "${PROJECT}" down
        ${COMPOSE_CMD} -p "${PROJECT}" up -d
    ;;
    *)
        echo "$0: Error: Invalid option: $1"
        exit 1
    ;;
esac
