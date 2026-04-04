# GenGate — Architecture

## 1. High-level architecture
GenGate uses a multi-client architecture with one Python backend and three client surfaces in the current phase:
- Web: Next.js
- iOS: Swift
- Android: Kotlin

## 2. Core layers
### Client layer
- `web-nextjs`
- `ios-swift`
- `android-kotlin`

### Backend platform
- HTTP API
- WebSocket/realtime gateway
- background jobs
- auth/session/device management
- media upload orchestration

### Data layer
- PostgreSQL
- Redis
- object storage

### Contract layer
- OpenAPI or shared contract artifacts
- request/response schemas
- event definitions

## 3. Suggested repo layout
/apps
- `backend-python`
- `web-nextjs`
- `ios-swift`
- `android-kotlin`
/docs
- product, architecture, api, flows, roadmap, plans
/contracts
- generated schemas or API artifacts

## 4. Backend architecture
### Recommended stack
- FastAPI
- SQLAlchemy or Prisma-equivalent Python ORM preference to be decided (recommended: SQLAlchemy + Alembic)
- PostgreSQL
- Redis
- S3-compatible storage
- WebSocket support

### Backend modules
- auth
- users
- profiles
- friendships
- moments
- media
- conversations
- messages
- locations
- notifications
- devices/sessions

## 5. Web architecture
- Next.js app router
- authenticated shell routes
- feed, inbox, location, profile, settings
- frontend consumes backend API and realtime events

## 6. iOS architecture
- Swift native app
- modular feature folders:
  - Auth
  - Feed
  - Inbox
  - Location
  - Profile
- API client generated or handwritten from contract

## 7. Android architecture
- Kotlin native app
- feature modules mirroring iOS domains
- API client consistent with backend contract

## 8. Realtime architecture
Use authenticated realtime channel for:
- new messages
- read receipts
- new moments
- friend request updates
- location state changes

## 9. Storage architecture
### PostgreSQL
Primary source of persistent relational truth.

### Redis
- caching
- pub/sub
- presence / ephemeral state
- rate limit helpers

### Object storage
- media originals
- thumbnails / transformed assets
- signed uploads

## 10. Security principles
- privacy rules enforced on backend
- per-device sessions
- signed media access where needed
- visibility rules for moments and location
- audit hooks for sensitive actions

## 11. Engineering principles
- contract-first enough to avoid platform drift
- domain-first module boundaries
- shared truth in docs + API schema
- thin vertical slices before polish
