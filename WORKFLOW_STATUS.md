# GenGate Workflow Status

- Batch: 61
- Worker: team (`pikamen` backend / `pikachu-web` web / `pikame-ios` iOS)
- Scope: batch 61 MVP test hub hardening — turn web home into a guided test hub and expose navigation to all MVP seams from one place
- Status: MVP-testable
- Files:
  - apps/web-nextjs/app/page.tsx
  - apps/web-nextjs/components/app-shell.tsx
  - WORKFLOW_STATUS.md
  - WORKFLOW_CHECKLIST.md
  - TEAM_DISPATCH.md
- Test:
  - web: `cd apps/web-nextjs && npm run verify` ✅
- Git:
  - latest commit: `878e131` — `batch60: wire location sharing shell`
  - working tree: bẩn (batch 61 ready to commit)
- Blocker: none
- Next: commit batch 61 MVP test hub hardening; after that, do not open a new core seam unless requirements change — prefer refinement, bug-fixing, or mobile consumption of existing seams
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
- Batch 61 outcome:
  - web home `/` is now a guided MVP test hub that links to all current seams in a suggested smoke-test order
  - global web nav now exposes all MVP seams directly: login, profile, feed, inbox, notifications, location
  - human testers no longer need to memorize separate routes to walk the MVP
- Run/test path:
  - backend run: `cd apps/backend-python && ./.venv/bin/uvicorn app.main:app --reload`
  - web run: `cd apps/web-nextjs && npm run dev`
  - MVP hub: `http://localhost:3000/`
  - smoke path from one entry point:
    1. `/login`
    2. `/profile`
    3. `/feed`
    4. `/inbox`
    5. `/notifications`
    6. `/location`
