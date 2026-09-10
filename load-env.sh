#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo ".env not found. Copy .env.example to .env first."
  exit 1
fi

set -a
source .env
set +a

echo ".env loaded for this shell."
