# GenGate Workflow Status

- Batch: 55
- Worker: team (`pikamen` backend / `pikachu-web` web / `pikame-ios` iOS)
- Scope: batch 55 friend graph MVP shell — reopen autopilot after auth/session closeout, add backend friend-request/friendship listing contracts and wire web profile route to a testable friend graph shell
- Status: MVP-testable
- Files:
  - apps/backend-python/app/modules/friendships/router.py
  - apps/backend-python/app/services/friendships.py
  - apps/backend-python/app/repositories/friendships.py
  - apps/backend-python/app/schemas/friendships.py
  - apps/backend-python/tests/test_friendships_api.py
  - apps/web-nextjs/lib/friends/client.ts
  - apps/web-nextjs/components/friend-graph-shell.tsx
  - apps/web-nextjs/app/profile/page.tsx
  - WORKFLOW_STATUS.md
  - WORKFLOW_CHECKLIST.md
  - TEAM_DISPATCH.md
- Test:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_friendships_api.py` ✅
  - web: `cd apps/web-nextjs && npm run verify` ✅
- Git:
  - latest commit: `7c5ecfd` — `batch54: mark autopilot finished`
  - working tree: bẩn (batch 55 ready to commit)
- Blocker: none
- Next: commit batch 55 friend graph slice, then move to next narrow MVP seam: moment posting with image + caption shell
- Context rule: mỗi lane dùng 1 agent cố định (`pikamen`, `pikachu-web`, `pikame-ios`); khi mở batch mới, main agent phải clear context của session lane đó bằng handoff note ngắn, không kéo full history cũ
- Batch 55 outcome:
  - override cũ `finished/paused` theo chỉ đạo mới của Vinh: tiếp tục autopilot qua các seam MVP product, không dừng ở auth/session
  - seam product đầu tiên sau auth/session đã mở được: friend requests / friend graph shell
  - backend hiện có list contracts `GET /friends/requests?user_id=<uuid>` và `GET /friends?user_id=<uuid>` với user summaries để web shell render data thật
  - web `app/profile/page.tsx` hiện đọc seam này qua `?user=<uuid>` và show pending requests + accepted friendships
  - trạng thái hiện tại đủ để đánh dấu **MVP-testable** cho seam social đầu tiên beyond auth
- Run/test path:
  - backend run: `cd apps/backend-python && ./.venv/bin/uvicorn app.main:app --reload`
  - web run: `cd apps/web-nextjs && npm run dev`
  - seed/test seam:
    1. register 2 users via `POST /auth/register`
    2. create request via `POST /friends/requests`
    3. optionally accept via `POST /friends/requests/{request_id}/accept`
    4. open `http://localhost:3000/profile?user=<requester-or-receiver-uuid>` to inspect friend graph shell
