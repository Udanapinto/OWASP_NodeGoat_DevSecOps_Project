#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "========================================"
echo " Starting NodeGoat DevSecOps Environment"
echo "========================================"

docker compose up -d --build

echo
echo "Container status:"
docker compose ps

echo
echo "NodeGoat:"
echo "http://127.0.0.1:4000"


