# GenGate — Local Development

## 1. Goal
This document defines the expected local development story for the active stack:
- backend-python
- web-nextjs
- ios-swift
- android-kotlin

## 2. Required local dependencies
### Core
- Node.js
- pnpm or npm
- Python 3.11+
- PostgreSQL
- Redis
- Docker (recommended for local infra)

### Native
- Xcode for iOS
- Android Studio + JDK for Android

## 3. Repository structure
Expected active app folders:
- `apps/backend-python`
- `apps/web-nextjs`
- `apps/ios-swift`
- `apps/android-kotlin`
- `infra`

## 4. Local infrastructure
Recommended local services:
- PostgreSQL
- Redis

Suggested `infra/docker-compose.yml` responsibilities:
- run local postgres
- run local redis
- expose ports for development only

## 5. Backend local run expectation
Typical steps:
1. create python virtual environment
2. install backend dependencies
3. copy `.env.example` to `.env`
4. configure DB/Redis/R2 values
5. run migrations
6. start FastAPI server
7. verify `GET /health`

## 6. Web local run expectation
Typical steps:
1. install dependencies
2. copy `.env.example`
3. point web client to backend base URL
4. start Next.js dev server
5. verify route shells render

## 7. iOS local run expectation
Typical steps:
1. open project in Xcode
2. configure backend base URL for local environment
3. run simulator build
4. verify Login / Feed / Inbox / Location / Profile shells

## 8. Android local run expectation
Typical steps:
1. open project in Android Studio
2. configure backend base URL for emulator/device
3. run debug build
4. verify Login / Feed / Inbox / Location / Profile shells

## 9. Local environment variables expected
### Backend
- DATABASE_URL
- REDIS_URL
- R2_ACCOUNT_ID
- R2_ACCESS_KEY_ID
- R2_SECRET_ACCESS_KEY
- R2_BUCKET
- JWT secrets / auth config

### Web / mobile
- API base URL
- websocket base URL
- environment mode

## 10. Foundation verification checklist
- backend starts locally
- `/health` returns ok
- web shell starts
- ios shell opens
- android shell opens
- db migrations run cleanly
- routes/screens exist according to docs

## 11. Rule for coding agents
If local run steps are incomplete, the coding agent must document the exact missing step rather than pretending the app is fully runnable.
