# GenGate Social Platform Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bootstrap the real first-phase platform for GenGate with Python backend, Next.js web, native iOS Swift app, and native Android Kotlin app.

**Architecture:** One Python backend as the source of truth, plus 3 client surfaces: web, iOS, Android. Shared truth comes from docs, API contracts, and domain model rather than a forced shared UI runtime.

**Tech Stack:** Monorepo, Python (recommended FastAPI), PostgreSQL, Redis, object storage, Next.js, Swift, Kotlin.

---

### Task 1: Reset implementation direction in docs

**Files:**
- Modify: `SYSTEM_SPEC.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/PLATFORM_STRATEGY.md`
- Modify: `docs/ROADMAP.md`

**Step 1:** Remove old assumptions about NestJS / Expo / Tauri from the active plan.

**Step 2:** Re-state current build scope as backend-python + web-nextjs + ios-swift + android-kotlin.

### Task 2: Create backend-python foundation

**Files:**
- Create: `apps/backend-python/*`

**Step 1:** Bootstrap FastAPI project skeleton.

**Step 2:** Add health endpoint.

**Step 3:** Add modular folders for auth, profiles, friendships, moments, messages, locations.

**Step 4:** Add environment config and startup docs.

### Task 3: Create web-nextjs foundation

**Files:**
- Create: `apps/web-nextjs/*`

**Step 1:** Bootstrap Next.js app.

**Step 2:** Add route shells for feed, inbox, location, profile, auth.

### Task 4: Create native iOS foundation

**Files:**
- Create: `apps/ios-swift/*`

**Step 1:** Create native iOS project structure.

**Step 2:** Add shell screens for auth, feed, inbox, location, profile.

### Task 5: Create native Android foundation

**Files:**
- Create: `apps/android-kotlin/*`

**Step 1:** Create native Android project structure.

**Step 2:** Add shell screens for auth, feed, inbox, location, profile.

### Task 6: Define schema and contracts

**Files:**
- Create: backend schema files
- Create: contract/openapi artifacts

**Step 1:** Define users, sessions, friendships, moments, messages, location sharing.

**Step 2:** Keep API and docs aligned.

### Task 7: Report clearly

**Step 1:** Summarize what is runnable now.

**Step 2:** Call out platform-specific blockers.

**Step 3:** Recommend the next vertical slice.
