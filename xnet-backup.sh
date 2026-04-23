#!/bin/sh
set -e
DATA_DIR="${XNET_DATA:-./data}"
BACKUP_DIR="${XNET_BACKUP_DIR:-./backups}"

case "$1" in
  backup)
    mkdir -p "$BACKUP_DIR"
    STAMP=$(date +%Y%m%d-%H%M%S)
    tar czf "$BACKUP_DIR/xnet-$STAMP.tar.gz" -C "$(dirname "$DATA_DIR")" "$(basename "$DATA_DIR")"
    echo "Backup: $BACKUP_DIR/xnet-$STAMP.tar.gz"
    # Keep last 7
    ls -t "$BACKUP_DIR"/xnet-*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null
    ;;
  restore)
    [ -z "$2" ] && echo "Usage: $0 restore <backup.tar.gz>" && exit 1
    [ ! -f "$2" ] && echo "File not found: $2" && exit 1
    echo "Restoring from $2 ..."
    docker stop xnet 2>/dev/null || true
    rm -rf "$DATA_DIR.old"
    mv "$DATA_DIR" "$DATA_DIR.old"
    mkdir -p "$(dirname "$DATA_DIR")"
    tar xzf "$2" -C "$(dirname "$DATA_DIR")"
    docker start xnet 2>/dev/null || true
    echo "Restored. Old data in $DATA_DIR.old"
    ;;
  *)
    echo "Usage: $0 {backup|restore <file>}"
    exit 1
    ;;
esac
