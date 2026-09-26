#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EVIDENCE="$ROOT/docs/report-evidence/02-docker/baseline"

mkdir -p "$EVIDENCE"

echo "Capturing Docker evidence..."

docker --version \
> "$EVIDENCE/docker-version.txt"

docker compose version \
> "$EVIDENCE/docker-compose-version.txt"

docker compose config \
> "$EVIDENCE/resolved-compose.yml"

docker compose ps \
> "$EVIDENCE/container-status.txt"

docker compose images \
> "$EVIDENCE/container-images.txt"

docker compose logs --no-color web \
> "$EVIDENCE/nodegoat-web.log" 2>&1

docker compose logs --no-color mongo \
> "$EVIDENCE/mongodb.log" 2>&1

docker compose exec -T web node --version \
> "$EVIDENCE/node-version.txt"

docker compose exec -T web npm --version \
> "$EVIDENCE/npm-version.txt"

docker compose exec -T web sh -c \
'nc -z -w 2 mongo 27017 && echo "WEB -> MONGO: OK"' \
> "$EVIDENCE/web-to-mongo.txt"

curl -sS \
-D "$EVIDENCE/http-headers.txt" \
-o /dev/null \
http://127.0.0.1:4000/

git diff vulnerable-baseline -- app \
> "$EVIDENCE/app-baseline-diff.txt"

echo "Evidence captured in:"
echo "$EVIDENCE"
