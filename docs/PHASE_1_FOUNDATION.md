# GenGate — Phase 1 Foundation Specification

## 1. Objective
Phase 1 is only about building the **real technical foundation** for GenGate on 4 surfaces:
- Python backend
- Next.js web frontend
- native iOS app in Swift
- native Android app in Kotlin

This phase is **not** about finishing the product. It is about creating the first stable architecture that later phases can build on without redoing the whole system.

## 2. Phase 1 outcomes
At the end of Phase 1, the system must have:
1. a runnable Python backend service
2. a real database connection layer
3. a health endpoint
4. a clear backend module structure by domain
5. a real Next.js web app scaffold
6. a real native iOS project scaffold
7. a real native Android project scaffold
8. initial DB schema for core domains
9. initial API contract skeleton
10. startup instructions for local development

## 3. What Phase 1 includes
### Backend
- FastAPI app bootstrap
- settings/config loader
- health endpoint
- routing structure
- SQLAlchemy + Alembic setup
- PostgreSQL connection setup
- Redis connection setup
- object storage config placeholder
- domain module folders:
  - auth
  - profiles
  - friendships
  - moments
  - messages
  - locations
- base models and first migration

### Web
- Next.js app bootstrap
- app router layout
- route shells:
  - `/login`
  - `/feed`
  - `/inbox`
  - `/location`
  - `/profile`
- shared layout shell
- API client placeholder
- env example

### iOS
- native Swift project scaffold
- SwiftUI app shell
- top-level screens:
  - Login
  - Feed
  - Inbox
  - Location
  - Profile
- API service placeholder
- app navigation shell
- environment/config note

### Android
- native Kotlin project scaffold
- Jetpack Compose app shell
- top-level screens:
  - Login
  - Feed
  - Inbox
  - Location
  - Profile
- API service placeholder
- app navigation shell
- environment/config note

### Contracts / docs
- initial API contract skeleton
- phase startup instructions
- local run instructions
- list of pending decisions

## 4. What Phase 1 explicitly does NOT include
- fully working auth logic
- full messaging implementation
- real media upload pipeline
- production-grade realtime events
- full location sync behavior
- notification delivery
- advanced design system
- desktop clients

## 5. Folder structure to create
```text
generated/gengate/
  apps/
    backend-python/
    web-nextjs/
    ios-swift/
    android-kotlin/
  contracts/
  docs/
  infra/
```

## 6. Recommended backend structure
```text
apps/backend-python/
  app/
    main.py
    core/
      config.py
      db.py
      redis.py
      storage.py
    api/
      router.py
      health.py
    modules/
      auth/
      profiles/
      friendships/
      moments/
      messages/
      locations/
    models/
    schemas/
    services/
  alembic/
  tests/
  requirements.txt
  pyproject.toml
  .env.example
```

## 7. Recommended web structure
```text
apps/web-nextjs/
  app/
    login/
    feed/
    inbox/
    location/
    profile/
    layout.tsx
    page.tsx
  components/
  lib/
    api/
    config/
  public/
  package.json
  tsconfig.json
  .env.example
```

## 8. Recommended iOS structure
```text
apps/ios-swift/
  GenGateIOS/
    App/
    Core/
    Features/
      Auth/
      Feed/
      Inbox/
      Location/
      Profile/
    Networking/
    Resources/
  GenGateIOS.xcodeproj
```

## 9. Recommended Android structure
```text
apps/android-kotlin/
  app/
    src/main/java/.../
      core/
      features/
        auth/
        feed/
        inbox/
        location/
        profile/
      networking/
    src/main/res/
  build.gradle.kts
  settings.gradle.kts
```

## 10. Initial schema required in Phase 1
Create the first DB schema with these entities:
- users
- profiles
- devices
- sessions
- friend_requests
- friendships
- moments
- moment_media
- conversations
- conversation_members
- messages
- location_shares
- user_location_snapshots
- notifications

The schema only needs baseline columns, but it must be real and migratable.

## 11. API surface required in Phase 1
Only skeleton endpoints are required now:
- `GET /health`
- route groups for:
  - `/auth`
  - `/profiles`
  - `/friends`
  - `/moments`
  - `/messages`
  - `/locations`

Handlers may return stub responses in Phase 1 if the route structure is correct and clearly marked.

## 12. Local infrastructure for Phase 1
Need local dev story for:
- PostgreSQL
- Redis
- environment variables
- backend run command
- web run command

Native mobile apps only need project shells and build instructions in this phase.

## 13. Testing required in Phase 1
### Backend
- health endpoint test
- config load test
- db import/bootstrap smoke test

### Web
- route shell lint/typecheck

### iOS / Android
- buildable shell target or at minimum generated project structure + documented build steps

## 14. Acceptance criteria
Phase 1 is complete only if:
1. backend starts locally
2. `GET /health` returns success
3. DB migration baseline exists
4. web app starts and renders route shells
5. iOS project opens and has shell screens
6. Android project opens and has shell screens
7. docs explain how to run each surface
8. folder structure is clean and future-proof

## 15. Risks to watch
- backend contract drift from mobile/web needs
- too much time wasted polishing shell UI too early
- trying to implement business logic before base contract/schema is stable
- native mobile scaffolds diverging from backend naming conventions

## 16. Recommended coding order inside Phase 1
1. backend-python scaffold
2. backend config/db/health
3. schema + migration baseline
4. web-nextjs scaffold
5. iOS Swift scaffold
6. Android Kotlin scaffold
7. contracts + startup docs
8. smoke verification

## 17. Deliverable of this phase
A repository that still looks skeletal product-wise, but is technically real, bootable, and ready for Phase 2 vertical slices.
