# GenGate Workflow Status

- Batch: 57
- Worker: team (`pikamen` backend / `pikachu-web` web / `pikame-ios` iOS)
- Scope: batch 57 private friend feed shell — add backend feed contract for accepted-friend moments and wire web `/feed` to load that contract by viewer UUID
- Status: MVP-testable
- Files:
  - apps/backend-python/app/modules/moments/router.py
  - apps/backend-python/app/services/moments.py
  - apps/backend-python/app/repositories/moments.py
  - apps/backend-python/app/schemas/moments.py
  - apps/backend-python/tests/test_moments_api.py
  - apps/web-nextjs/app/feed/page.tsx
  - apps/web-nextjs/lib/moments/client.ts
  - apps/web-nextjs/components/moment-compose-shell.tsx
  - WORKFLOW_STATUS.md
  - WORKFLOW_CHECKLIST.md
  - TEAM_DISPATCH.md
- Test:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_moments_api.py` ✅
  - web: `cd apps/web-nextjs && npm run verify` ✅
- Git:
  - latest commit: `c4f5fcb` — `batch56: wire moment posting shell`
  - working tree: bẩn (batch 57 ready to commit)
- Blocker: none
- Next: commit batch 57 private friend feed slice, then move to next narrow MVP seam: direct messaging shell
- Context rule: mỗi lane dùng 1 agent cố định (`pikamen`, `pikachu-web`, `pikame-ios`); khi mở batch mới, main agent phải clear context của session lane đó bằng handoff note ngắn, không kéo full history cũ
- Batch 55 handoff:
  - `9786726` — `batch55: wire friend graph shell`
  - friend graph seam remains MVP-testable while batch 56 is opened for the next slice
- Batch 56 handoff:
  - `c4f5fcb` — `batch56: wire moment posting shell`
  - moment posting seam remains MVP-testable while batch 57 opens the next feed slice
- Batch 57 outcome:
  - backend now supports `GET /moments/feed?viewer_user_id=<uuid>` returning accepted-friend moments only
  - web `/feed` keeps the authored moment compose shell and now also reloads a private friend feed by viewer UUID
  - this seam is now also **MVP-testable** beyond auth
- Run/test path:
  - backend run: `cd apps/backend-python && ./.venv/bin/uvicorn app.main:app --reload`
  - web run: `cd apps/web-nextjs && npm run dev`
  - test friend graph seam: `http://localhost:3000/profile?user=<uuid>`
  - test moment authoring seam: `http://localhost:3000/feed`
  - test private friend feed seam:
    1. register viewer + friend users
    2. create and accept a friendship via `/friends/requests` + `/friends/requests/{request_id}/accept`
    3. create a moment + image for the friend user
    4. open `http://localhost:3000/feed`
    5. paste friend UUID into author field if you want to create authored data, and paste viewer UUID into feed viewer field
    6. click `Reload private friend feed` to confirm only accepted-friend moments appear
