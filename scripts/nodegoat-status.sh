#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==============================="
echo " NodeGoat Container Status"
echo "==============================="

docker compose ps

echo
echo "Images:"
docker compose images

echo
echo "Application URL:"
echo "http://127.0.0.1:4000"
