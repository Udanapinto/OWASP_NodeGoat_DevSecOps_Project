#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "========================================"
echo " Stopping NodeGoat DevSecOps Environment"
echo "========================================"

docker compose down

echo
echo "Environment stopped."

