#!/bin/sh
set -e

: "${SLOCK_API_KEY:?SLOCK_API_KEY environment variable is required}"

exec npx --yes @slock-ai/daemon@latest \
  --server-url "${SLOCK_SERVER_URL:-https://api.slock.ai}" \
  --api-key "${SLOCK_API_KEY}"
