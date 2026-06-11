#!/bin/sh
set -e

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

: "${SLOCK_API_KEY:?SLOCK_API_KEY environment variable is required}"

exec slock-daemon \
  --server-url "${SLOCK_SERVER_URL:-https://api.slock.ai}" \
  --api-key "${SLOCK_API_KEY}"
