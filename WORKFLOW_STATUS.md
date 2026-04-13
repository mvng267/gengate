# GenGate Workflow Status

- Batch: 60
- Worker: team (`pikamen` backend / `pikachu-web` web / `pikame-ios` iOS)
- Scope: batch 60 location sharing state shell — wire web `/location` to create/load/toggle per-user share state and snapshots against existing backend contracts
- Status: MVP-testable
- Files:
  - apps/web-nextjs/app/location/page.tsx
  - apps/web-nextjs/lib/location/client.ts
  - apps/web-nextjs/components/location-shell.tsx
  - WORKFLOW_STATUS.md
  - WORKFLOW_CHECKLIST.md
  - TEAM_DISPATCH.md
- Test:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_locations_api.py tests/test_location_audience_api.py` ✅
  - web: `cd apps/web-nextjs && npm run verify` ✅
- Git:
  - latest commit: `697b356` — `batch59: wire notification shell`
  - working tree: bẩn (batch 60 ready to commit)
- Blocker: none
- Next: commit batch 60 location sharing state shell; MVP priority seams are now all present, so next work should be refinement or cross-surface hardening rather than opening a new core seam
- Context rule: mỗi lane dùng 1 agent cố định (`pikamen`, `pikachu-web`, `pikame-ios`); khi mở batch mới, main agent phải clear context của session lane đó bằng handoff note ngắn, không kéo full history cũ
- Batch 55 handoff:
  - `9786726` — `batch55: wire friend graph shell`
  - friend graph seam remains MVP-testable while batch 56 is opened for the next slice
- Batch 56 handoff:
  - `c4f5fcb` — `batch56: wire moment posting shell`
  - moment posting seam remains MVP-testable while batch 57 opens the next feed slice
- Batch 57 handoff:
  - `4a779eb` — `batch57: wire private friend feed shell`
  - private friend feed seam remains MVP-testable while batch 58 opens direct messaging
- Batch 60 outcome:
  - existing backend location contracts are now exposed on web via `/location`
  - web `/location` now creates a share for an owner UUID, toggles active/inactive state, adds an audience user, creates snapshots, and reloads audience/snapshot counts
  - this seam is now also **MVP-testable** beyond notifications/inbox/feed/auth
- Run/test path:
  - backend run: `cd apps/backend-python && ./.venv/bin/uvicorn app.main:app --reload`
  - web run: `cd apps/web-nextjs && npm run dev`
  - friend graph seam: `http://localhost:3000/profile?user=<uuid>`
  - moments/feed seam: `http://localhost:3000/feed`
  - direct messaging seam: `http://localhost:3000/inbox`
  - notifications seam: `http://localhost:3000/notifications`
  - location seam: `http://localhost:3000/location`
  - test location seam:
    1. register an owner user and optionally a second user for audience
    2. open `http://localhost:3000/location`
    3. paste owner UUID into `Owner user UUID`
    4. click `Create location share`
    5. optionally paste second user UUID and click `Add audience member`
    6. click `Create location snapshot`
    7. use `Disable sharing` / `Enable sharing` and `Reload counts` to confirm state persists
