#!/usr/bin/env sh
set -eu

cd /app/apps/web-nextjs
npm install
exec npm run dev -- --hostname 0.0.0.0 --port 3000
