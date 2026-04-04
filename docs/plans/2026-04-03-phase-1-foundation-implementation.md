# GenGate Phase 1 Foundation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the real Phase 1 foundation for GenGate: Python backend, Next.js web, native iOS Swift shell, and native Android Kotlin shell with a stable structure for future feature development.

**Architecture:** Use one Python backend as the source of truth, then scaffold three client surfaces around it. Phase 1 is architecture-first: create real projects, real config, real routes, real schema baseline, and runnable local foundations before implementing product logic.

**Tech Stack:** Python (recommended FastAPI), SQLAlchemy, Alembic, PostgreSQL, Redis, object storage placeholders, Next.js, SwiftUI, Kotlin + Jetpack Compose.

---

### Task 1: Lock the Phase 1 spec into docs

**Files:**
- Create: `docs/PHASE_1_FOUNDATION.md`
- Modify: `SYSTEM_SPEC.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/PLATFORM_STRATEGY.md`
- Modify: `docs/ROADMAP.md`

**Step 1:** Read `SYSTEM_SPEC.md`, `docs/ARCHITECTURE.md`, `docs/PLATFORM_STRATEGY.md`, and `docs/ROADMAP.md`.

**Step 2:** Ensure they all match the active stack: Python backend, Next.js web, iOS Swift, Android Kotlin.

**Step 3:** Confirm `docs/PHASE_1_FOUNDATION.md` is the source of truth for this phase.

**Step 4:** Re-read docs and summarize the implementation boundaries before touching code.

### Task 2: Create the repository structure for the active stack

**Files:**
- Create: `apps/backend-python/`
- Create: `apps/web-nextjs/`
- Create: `apps/ios-swift/`
- Create: `apps/android-kotlin/`
- Create: `contracts/`
- Create: `infra/`

**Step 1:** Create the directories exactly as specified.

**Step 2:** Keep existing earlier scaffold separate; do not mix old NestJS/Expo/Tauri assumptions into the active stack folders.

**Step 3:** Add a root note in README if needed to clarify active vs old scaffold.

### Task 3: Bootstrap backend-python

**Files:**
- Create: `apps/backend-python/pyproject.toml`
- Create: `apps/backend-python/app/main.py`
- Create: `apps/backend-python/app/core/config.py`
- Create: `apps/backend-python/app/core/db.py`
- Create: `apps/backend-python/app/core/redis.py`
- Create: `apps/backend-python/app/core/storage.py`
- Create: `apps/backend-python/app/api/router.py`
- Create: `apps/backend-python/app/api/health.py`
- Create: `apps/backend-python/app/modules/auth/__init__.py`
- Create: `apps/backend-python/app/modules/profiles/__init__.py`
- Create: `apps/backend-python/app/modules/friendships/__init__.py`
- Create: `apps/backend-python/app/modules/moments/__init__.py`
- Create: `apps/backend-python/app/modules/messages/__init__.py`
- Create: `apps/backend-python/app/modules/locations/__init__.py`
- Create: `apps/backend-python/.env.example`

**Step 1:** Write a failing backend smoke test if a test setup is introduced.

**Step 2:** Implement FastAPI app bootstrap with `/health`.

**Step 3:** Add config loaders and connection placeholders.

**Step 4:** Run backend startup locally.

**Step 5:** Confirm `GET /health` returns success.

### Task 4: Add schema and migration baseline

**Files:**
- Create: `apps/backend-python/alembic.ini`
- Create: `apps/backend-python/alembic/`
- Create: `apps/backend-python/app/models/`
- Create: `apps/backend-python/app/models/base.py`
- Create: `apps/backend-python/app/models/user.py`
- Create: `apps/backend-python/app/models/profile.py`
- Create: `apps/backend-python/app/models/friendship.py`
- Create: `apps/backend-python/app/models/moment.py`
- Create: `apps/backend-python/app/models/message.py`
- Create: `apps/backend-python/app/models/location.py`

**Step 1:** Define baseline SQLAlchemy models for core entities.

**Step 2:** Add initial Alembic migration.

**Step 3:** Run the migration against local Postgres.

**Step 4:** Verify migration history is clean.

### Task 5: Bootstrap web-nextjs

**Files:**
- Create: `apps/web-nextjs/package.json`
- Create: `apps/web-nextjs/app/layout.tsx`
- Create: `apps/web-nextjs/app/page.tsx`
- Create: `apps/web-nextjs/app/login/page.tsx`
- Create: `apps/web-nextjs/app/feed/page.tsx`
- Create: `apps/web-nextjs/app/inbox/page.tsx`
- Create: `apps/web-nextjs/app/location/page.tsx`
- Create: `apps/web-nextjs/app/profile/page.tsx`
- Create: `apps/web-nextjs/lib/api/client.ts`
- Create: `apps/web-nextjs/.env.example`

**Step 1:** Bootstrap a real Next.js app.

**Step 2:** Create route shells for login, feed, inbox, location, and profile.

**Step 3:** Add a lightweight API client placeholder.

**Step 4:** Run Next.js locally and verify routes render.

### Task 6: Bootstrap iOS native shell

**Files:**
- Create: `apps/ios-swift/GenGateIOS.xcodeproj`
- Create: `apps/ios-swift/GenGateIOS/`
- Create feature folders for Auth, Feed, Inbox, Location, Profile

**Step 1:** Create a native SwiftUI project structure.

**Step 2:** Add shell screens and a root navigation entry.

**Step 3:** Add API service placeholder and config note.

**Step 4:** Document how to open/build the iOS project.

### Task 7: Bootstrap Android native shell

**Files:**
- Create: `apps/android-kotlin/settings.gradle.kts`
- Create: `apps/android-kotlin/build.gradle.kts`
- Create: `apps/android-kotlin/app/build.gradle.kts`
- Create Android feature folders for Auth, Feed, Inbox, Location, Profile

**Step 1:** Create a native Kotlin + Compose project structure.

**Step 2:** Add shell screens and root navigation.

**Step 3:** Add API service placeholder and config note.

**Step 4:** Document how to open/build the Android project.

### Task 8: Add local infrastructure and startup docs

**Files:**
- Create: `infra/docker-compose.yml`
- Create: `docs/LOCAL_DEVELOPMENT.md`
- Create: `contracts/README.md`

**Step 1:** Add local Postgres + Redis setup.

**Step 2:** Document backend/web startup commands.

**Step 3:** Document iOS and Android shell startup/build expectations.

### Task 9: Verify the whole foundation

**Files:**
- Modify any files needed to fix verification issues

**Step 1:** Run backend locally.

**Step 2:** Check `GET /health`.

**Step 3:** Run web locally.

**Step 4:** Verify iOS and Android project structures are coherent and documented.

**Step 5:** Summarize exactly what is runnable and what remains shell-only.

### Task 10: End-of-batch report

**Step 1:** Report progress percent.

**Step 2:** List files and folders created.

**Step 3:** State what now runs for real.

**Step 4:** State blockers or pending decisions.

**Step 5:** Recommend the first Phase 2 vertical slice.
