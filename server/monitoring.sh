#!/bin/bash

BUILD_DIR="/docker/build/monitoring"

if [[ -z "$@" ]]; then
    echo >&2 "Usage: $0 <command>"
    echo >&2 "command = up, down, restart"
    exit 1
fi

case "$1" in
  up)
    cd $BUILD_DIR
    docker-compose -p "Monitoring" up -d
    cd /docker/bin
  ;;
  down)
    cd $BUILD_DIR
    docker-compose down
    cd /docker/bin
  ;;
  restart)
    ./$0 down
    ./$0 up
  ;;
  *)
    echo "$0: Error: Invalid option: $1"
    exit 1
  ;;
esac

