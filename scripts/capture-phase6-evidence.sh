#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EVIDENCE="$ROOT/docs/report-evidence/03-architecture"

mkdir -p "$EVIDENCE"

echo "Capturing Phase 6 architecture evidence..."

docker compose config \
> "$EVIDENCE/docker-compose-resolved.yml"

docker compose config --services \
> "$EVIDENCE/services.txt"

docker compose ps \
> "$EVIDENCE/container-status.txt"

docker compose port web 4000 \
> "$EVIDENCE/web-port.txt"

docker compose exec -T web printenv MONGODB_URI \
> "$EVIDENCE/mongodb-uri.txt"

docker compose exec -T web getent hosts mongo \
> "$EVIDENCE/mongo-dns-resolution.txt"

docker compose exec -T web sh -c \
'nc -z -w 2 mongo 27017 && echo "WEB -> MONGO OK"' \
> "$EVIDENCE/web-to-mongo-connectivity.txt"

git diff vulnerable-baseline -- app \
> "$EVIDENCE/application-baseline-diff.txt"

echo "Phase 6 evidence captured."
