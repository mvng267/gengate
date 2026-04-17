# GenGate Workflow Checklist

Dùng checklist này làm nguồn phối hợp chung giữa main agent và `pikamen`.

## Mỗi nhịp bắt buộc phải cập nhật

1. **Batch workflow chính thức**
   - số batch thật đang làm
   - không lấy từ tên test/function

2. **Scope hiện tại**
   - mô tả cực ngắn phần việc hẹp đang làm

3. **Trạng thái hiện tại**
   - one of:
     - `planned`
     - `in_progress`
     - `verify`
     - `pushed`
     - `blocked`
     - `complete`
     - `finished`

4. **File đã đụng**
   - danh sách file chính của nhịp hiện tại

5. **Test-verify**
   - lệnh test gần nhất
   - kết quả gần nhất

6. **Git mốc gần nhất**
   - commit gần nhất đã push
   - working tree sạch hay bẩn

7. **Blocker nếu có**
   - ghi ngắn theo loại: code / test / env / git / runtime

8. **Bước kế tiếp**
   - đúng 1 scope hẹp kế tiếp, đủ cụ thể để làm ngay

## Quy tắc phối hợp

- Main agent không được chỉ suy đoán từ git log nếu chưa đối chiếu checklist này.
- `pikamen` xong một nhịp phải cập nhật checklist này trước hoặc ngay sau khi push.
- Nếu repo sạch, không blocker, và checklist đang ở `pushed`, main agent phải kiểm tra `Bước kế tiếp` rồi đẩy `pikamen` làm tiếp ngay.
- Nếu checklist đang ở `blocked`, main agent phải báo blocker đúng loại, không bịa tiến độ.
- Không dùng số batch trong tên test như `test_batchNN_*` làm batch workflow.

## Current canonical state

- Batch workflow chính thức mới nhất trong checklist/status: **424 — web location parity now resets stale quick-copy feedback when location state/audience context changes.**

## Reporting hard rule

- Mọi báo cáo gửi cho Vinh về GenGate phải có dòng đầu: `Batch workflow chính thức hiện tại: <N>`.
- Không được báo cáo tiến độ mà thiếu số batch workflow chính thức.
- Nếu chưa chắc số batch, phải kiểm tra memory + WORKFLOW_STATUS + repo rồi mới báo.

## Batch handoff rule

- Khi một batch workflow được chốt xong, main agent phải ghi một handoff/compact note trước khi mở batch kế tiếp.
- Handoff note tối thiểu phải có:
  1. batch vừa xong,
  2. commit cuối đã push,
  3. test-verify cuối,
  4. blocker/rủi ro còn lại,
  5. batch kế tiếp + scope hẹp đầu tiên.
- Mỗi worker dùng **1 session cố định** theo lane; không đổi session liên tục qua từng batch.
- Nhưng khi sang batch mới, main agent phải **clear context của session lane đó**: nhịp mới chỉ mang handoff note ngắn, không kéo full history batch trước sang.
- Job nhắc việc nếu có phải bám đúng flow file do main agent cập nhật; worker không tự suy batch/scope ngoài file điều phối.
- Team coding cố định hiện tại là: `pikamen` (backend), `pikachu-web` (web), `pikame-ios` (iOS). Không dùng lại lane legacy `pikachu` / `pikame`.
- `pikamen` / `pikachu-web` / `pikame-ios` không được tự coi là đã sang batch mới nếu chưa thấy handoff note này trong checklist/status hoặc lệnh trực tiếp từ main agent.

## Status freshness rule

- `WORKFLOW_STATUS.md` là bảng trạng thái để Vinh tự check trực tiếp.
- `pikamen` phải cập nhật file này thường xuyên, tối thiểu ở 4 thời điểm:
  1. bắt đầu nhịp mới,
  2. sau khi chạy verify,
  3. sau khi push,
  4. khi có blocker.
- Main agent khi kiểm tra tiến độ phải đọc file này trước khi báo.

## Speed rule

- Mục tiêu điều hành hiện tại: đẩy tiến độ nhanh, ít token, không sa vào micro-cleanup kéo dài batch.
- Mỗi nhịp nên ưu tiên thay đổi nhỏ nhưng giúp đóng batch nhanh hơn.
- Báo cáo/WORKFLOW_STATUS ghi ngắn gọn, không văn dài.

## Current batch slice

- Batch workflow chính thức hiện tại: **424**
- Scope hiện tại: web location parity — reset stale quick-copy feedback khi location state/audience context đổi.
- Trạng thái hiện tại: **complete**
- File đã đụng:
  - `apps/web-nextjs/components/location-shell.tsx`
- Test-verify:
  - `cd apps/web-nextjs && npm run typecheck` → ✅
  - `cd apps/backend-python && make test-friendships` → ✅ (`8 passed in 0.46s`)
- Git mốc gần nhất:
  - commit đã chốt:
    - `c04e21f` — `batch424: reset web location quick-copy feedback on state refresh`
  - working tree hiện tại: dirty (workflow docs đang cập nhật trong nhịp hiện tại)
- Blocker nếu có:
  - none.
- Bước kế tiếp:
  - mở batch425 với 1 micro-slice product seam (ưu tiên notifications/location/feed parity follow-up) + giữ verify tối thiểu `make test-friendships`.
- MVP-testable run/test path (latest stable):
  - Backend: tạo request qua `POST /friends/requests` -> reject qua `POST /friends/requests/{id}/reject` -> list lại `GET /friends/requests?user_id=<id>` thấy `status: rejected`.
  - Web Feed (`/feed`): set `Author user UUID` + `Feed viewer UUID` -> `Create moment + image shell` -> `Reload private friend feed` -> verify line `Quick feed visibility gate summary: viewer_access=... / viewer_access_reason=... / gate_snapshot_source=... / visible_count=... / first_moment_id=...` + line `Quick create + feed-gate bundle: moment_create_marker={author=... | image_url=... | caption=...} | feed_gate_summary={viewer_access=... / viewer_access_reason=... / gate_snapshot_source=... / visible_count=... / first_moment_id=...}` + line `Last create feed-visibility delta: created_moment_id=... / viewer=... / feed_count=... / first_moment_id=...` + line `Last create + feed-gate bundle: last_create_feed_visibility_delta={created_moment_id=... / viewer=... / feed_count=... / first_moment_id=...} | feed_gate_summary={viewer_access=... / viewer_access_reason=... / gate_snapshot_source=... / visible_count=... / first_moment_id=...}`; status sau reload/create phải có `Gate summary: ... viewer_access_reason=... / gate_snapshot_source=...`. Bấm `Copy quick create + feed-gate bundle` để verify one-tap create bundle payload và bấm thêm `Copy last create + feed-gate bundle` để verify deterministic payload bundle cho lần create gần nhất; sau đó set `Moment ID to delete` (hoặc bấm `Use first authored moment as delete target`) -> `Delete moment (web parity)` -> verify line `Last delete result summary: delete_result=deleted / moment_id=... / author_user_id=... / deleted_at=... / author_loaded_count=... / feed_match_count=...` và line `Quick delete parity summary: delete_moment_id=... / authored_count=... / feed_count=... / gate_snapshot_source=... / delete_snapshot_source=manual_input|preset_row|first_authored_quick_pick`; bấm `Copy quick delete parity summary` + `Copy last delete result summary` + `Copy last copied delete summary feedback`, verify line source-state rồi bấm `Copy delete copy audit for first ready source` để one-shot copy `delete_copy_audit=source:.../value:...`; đối chiếu source được pick với line source-state.
  - iOS Feed: set `Author user UUID` + `Viewer user UUID` -> `Create moment + image` -> `Reload private feed` -> verify line `Quick feed visibility gate summary: viewer_access=... / viewer_access_reason=... / gate_snapshot_source=... / visible_count=... / first_moment_id=...` + line `Quick create + feed-gate bundle: moment_create_marker={author=... | image_url=... | caption=...} | feed_gate_summary={viewer_access=... / viewer_access_reason=... / gate_snapshot_source=... / visible_count=... / first_moment_id=...}` + line `Last create feed visibility delta: created_moment_id=... / viewer=... / feed_count=... / first_moment_id=...` + line `Last create + feed-gate bundle: last_create_feed_visibility_delta={created_moment_id=... / viewer=... / feed_count=... / first_moment_id=...} | feed_gate_summary={viewer_access=... / viewer_access_reason=... / gate_snapshot_source=... / visible_count=... / first_moment_id=...}`; status sau reload/create phải có `Gate summary: ... viewer_access_reason=... / gate_snapshot_source=...`. Bấm `Copy quick create + feed-gate bundle` để verify one-tap create bundle payload và bấm thêm `Copy last create + feed-gate bundle` để verify deterministic payload bundle cho lần create gần nhất; sau đó nhập `Moment ID to delete` (hoặc bấm `Use row id for delete`) -> `Delete moment` -> verify line `Last delete result summary: delete_result=deleted / moment_id=... / author_user_id=... / deleted_at=... / author_loaded_count=... / feed_match_count=...` và line `Quick delete parity summary: delete_moment_id=... / authored_count=... / feed_count=... / gate_snapshot_source=... / delete_snapshot_source=manual_input|preset_row|first_authored_quick_pick`; bấm `Copy quick delete parity summary` + `Copy last delete result summary` + `Copy copied delete summary feedback`, verify line source-state rồi bấm `Copy delete copy audit for first ready source` để one-shot copy `delete_copy_audit=source:.../value:...`; đối chiếu source được pick với line source-state.
  - Web Location (`/location`): nhập owner/share -> `Reload counts` -> verify line `Quick location state summary: owner=... / share_id=... / is_active=... / sharing_mode=... / audience_count=... / snapshot_count=...` -> bấm `Copy quick location state summary` và paste kiểm tra payload đúng format; sau đó tạo audience + remove audience và verify line `Quick audience remove parity summary: share_id=... / removed_audience_id=... / audience_count=...`, bấm `Copy quick audience remove parity summary` để kiểm tra payload deterministic.
  - iOS Location: nhập owner/share -> `Load location status` -> verify line `Quick location state summary: owner=... / share_id=... / is_active=... / sharing_mode=... / audience_count=... / snapshot_count=...` -> bấm `Copy quick location state summary` và paste kiểm tra payload đúng format; sau đó tạo audience + remove audience và verify line `Quick audience remove parity summary: share_id=... / removed_audience_id=... / audience_count=...`, bấm `Copy quick audience remove parity summary` để kiểm tra payload deterministic.
  - Web Friend graph (`/profile`): load snapshot -> bấm `Send friend request` và verify line `Quick copy friend-request create marker: request_id=... / action=created / requester=... / receiver=...` -> bấm `Reject` trên inbound pending request và verify line `Quick copy friend-request reject marker: request_id=... / action=rejected / accepted_count=... / pending_inbound=... / pending_outbound=...` -> bấm `Copy quick friend-request create + reject bundle` và paste kiểm tra payload dạng `friend_request_create_marker={...} | friend_request_reject_marker={...}` -> bấm thêm `Copy quick friend-request last-action summary bundle` và verify payload dạng `friend_request_create_marker={...} | friend_request_decision_marker={request_id=... / action=accepted|rejected / accepted_count=... / pending_inbound=... / pending_outbound=...} | friend_request_counts={accepted_count=... / pending_inbound=... / pending_outbound=...}`; đồng thời có thể bấm `Copy quick delta summary` hoặc `Copy last action delta` để kiểm tra payload cũ.
  - iOS Profile: load friend graph -> bấm `Send friend request` và verify line `Quick copy friend-request create marker: request_id=... / action=created / requester=... / receiver=...` -> bấm `Reject request` trên inbound pending request và verify line `Quick copy friend-request reject marker: request_id=... / action=rejected / accepted_count=... / pending_inbound=... / pending_outbound=...` -> bấm `Copy quick friend-request create + reject bundle` và paste kiểm tra payload dạng `friend_request_create_marker={...} | friend_request_reject_marker={...}`; vẫn có thể bấm `Copy quick delta summary` hoặc `Copy last action delta` để kiểm tra payload cũ.
  - Web Inbox: nhập user A/B -> `Open direct thread` (hoặc bấm `Use current session user as user_a + keep peer as user_b + open direct thread` / `Use current session user as user_b (peer) + keep user_a + open direct thread`; nếu thiếu peer context thì thấy marker `session_peer_user_missing_for_quick_apply`) -> nhập message text rồi bấm `Use current session user as sender + keep user_a/user_b pair + send` và verify status có marker `user_pair_source=kept_user_a+user_b` + `sender_source=session_user` -> bấm `Copy quick sender keep-pair marker` và verify payload marker -> bấm `Copy quick sender keep-pair + send result bundle` và verify payload bundle `sender_keep_pair_marker={...} | send_result={sender=... | message_id=...}` -> thao tác mark-read/jump-first-unread -> bấm `Copy quick read-cursor triage line` và verify payload dạng `read_cursor_triage=target_user:...,previous:...,applied:...,current:...,apply_state:...`.
  - iOS Inbox: nhập User A/B -> `Load inbox thread` (hoặc bấm `Use current session user as user_a + keep peer as user_b + open direct thread` / `Use current session user as user_b (peer) + keep user_a + open direct thread`; nếu thiếu peer context thì thấy marker `session_peer_user_missing_for_quick_apply`) -> nhập message text rồi bấm `Use current session user as sender + keep user_a/user_b pair + send` và verify status có marker `user_pair_source=kept_user_a+user_b` + `sender_source=session_user` -> bấm `Copy quick sender keep-pair marker` và verify payload marker -> bấm `Copy quick sender keep-pair + send result bundle` và verify payload bundle `sender_keep_pair_marker={...} | send_result={sender=... | message_id=...}` -> thao tác mark-read/jump-first-unread -> bấm `Copy quick read-cursor triage line` và verify payload tokenized cùng format với web.

## Batch handoff note

- Batch vừa xong: **424**
- Commit cuối đã chốt:
  - `c04e21f` — `batch424: reset web location quick-copy feedback on state refresh`
- Test-verify cuối:
  - Web: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend guardrail: `cd apps/backend-python && make test-friendships` → pass (`8 passed in 0.46s`)
- Blocker/rủi ro còn lại:
  - none.
- Batch kế tiếp:
  - **425**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/location/feed follow-up micro-slice (ưu tiên parity gap rõ nhất còn lại) + giữ verify bằng `make test-friendships`.

---

- Batch vừa xong: **423**
- Commit cuối đã chốt:
  - `db7e9f4` — `batch423: harden web location audience-remove copied feedback on failure`
- Test-verify cuối:
  - Web: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend guardrail: `cd apps/backend-python && make test-friendships` → pass (`8 passed in 0.45s`)
- Blocker/rủi ro còn lại:
  - none.
- Batch kế tiếp:
  - **424**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/location/feed follow-up micro-slice (ưu tiên parity gap rõ nhất còn lại) + giữ verify bằng `make test-friendships`.

---

- Batch vừa xong: **422**
- Commit cuối đã chốt:
  - `c737103` — `batch422: harden ios location audience-remove quick-copy failure feedback`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (1.73s)`)
  - Backend guardrail: `cd apps/backend-python && make test-friendships` → pass (`8 passed in 0.45s`)
- Blocker/rủi ro còn lại:
  - none.
- Batch kế tiếp:
  - **423**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/location/feed follow-up micro-slice (ưu tiên parity gap rõ nhất còn lại) + giữ verify bằng `make test-friendships`.

---

- Batch vừa xong: **421**
- Commit cuối đã chốt:
  - `6360a70` — `batch421: harden ios location state quick-copy failure feedback`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (2.53s)`)
  - Backend guardrail: `cd apps/backend-python && make test-friendships` → pass (`8 passed in 0.46s`)
- Blocker/rủi ro còn lại:
  - none.
- Batch kế tiếp:
  - **422**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/location/feed follow-up micro-slice (ưu tiên parity gap rõ nhất còn lại) + giữ verify bằng `make test-friendships`.

---

- Batch vừa xong: **420**
- Commit cuối đã chốt:
  - `0663937` — `batch420: clear web location copied-state feedback on copy failure`
- Test-verify cuối:
  - Web: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend guardrail: `cd apps/backend-python && make test-friendships` → pass (`8 passed in 0.46s`)
- Blocker/rủi ro còn lại:
  - none.
- Batch kế tiếp:
  - **421**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/location/feed follow-up micro-slice (ưu tiên parity gap rõ nhất còn lại) + giữ verify bằng `make test-friendships`.

---

- Batch vừa xong: **419**
- Commit cuối đã chốt:
  - `e3ef49b` — `batch419: gate web notifications lifecycle snapshot copied-feedback on successful copy`
- Test-verify cuối:
  - Web: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend guardrail: `cd apps/backend-python && make test-friendships` → pass (`8 passed in 0.45s`)
- Blocker/rủi ro còn lại:
  - none.
- Batch kế tiếp:
  - **420**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/location/feed follow-up micro-slice (ưu tiên parity gap rõ nhất còn lại) + giữ verify bằng `make test-friendships`.

---

- Batch vừa xong: **418**
- Commit cuối đã chốt:
  - `17be67b` — `batch418: harden ios notifications quick-copy failure tokens`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (21.44s)`)
  - Backend guardrail: `cd apps/backend-python && make test-friendships` → pass (`8 passed in 0.51s`)
- Blocker/rủi ro còn lại:
  - none.
- Batch kế tiếp:
  - **419**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/location/feed follow-up micro-slice (ưu tiên parity gap rõ nhất còn lại) + giữ verify bằng `make test-friendships`.

---

- Batch vừa xong: **417**
- Commit cuối đã chốt:
  - `27de141` — `batch417: add backend venv-backed friendships verify target`
- Test-verify cuối:
  - Backend: `cd apps/backend-python && make test-friendships` → pass (`8 passed in 0.51s`)
  - Backend sanity: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_friendships_api.py` → pass (`8 passed in 0.55s`)
- Blocker/rủi ro còn lại:
  - none cho targeted friendships verify path.
- Batch kế tiếp:
  - **418**
- Scope hẹp đầu tiên của batch kế tiếp:
  - product seam follow-up nhỏ (ưu tiên notifications/location/feed parity) + giữ verify bằng `make test-friendships`.

---

- Batch vừa xong: **416**
- Commit cuối đã chốt:
  - `0544a30` — `batch416: add web notifications error-hint token parity`
- Test-verify cuối:
  - Web: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend targeted verify: `cd apps/backend-python && pytest -q tests/test_friendships_api.py` → blocked (`zsh:1: command not found: pytest`)
- Blocker/rủi ro còn lại:
  - env: thiếu `pytest` trong môi trường hiện tại.
- Batch kế tiếp:
  - **417**
- Scope hẹp đầu tiên của batch kế tiếp:
  - backend env/runtime micro-slice để unblock `pytest` targeted verify path.

---

- Batch vừa xong: **412**
- Commit cuối đã chốt:
  - `4a12b07` — `batch412: prefer backend error tokens in ios inbox client`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (17.71s)`)
  - Web safety check: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend targeted verify: `cd apps/backend-python && pytest -q tests/test_friendships_api.py` → blocked (`zsh:1: command not found: pytest`)
- Blocker/rủi ro còn lại:
  - env: thiếu `pytest` trong môi trường hiện tại.
- Batch kế tiếp:
  - **413**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM contract follow-up nhỏ, ưu tiên token parity cho edge errors còn lệch giữa backend/web/iOS.

---

- Batch vừa xong: **411**
- Commit cuối đã chốt:
  - `41d7fa3` — `batch411: prefer backend error tokens in web inbox client`
- Test-verify cuối:
  - Web: `cd apps/web-nextjs && npm run typecheck` → pass
  - iOS safety check: `cd apps/ios-swift && swift build` → pass (`Build complete! (0.19s)`)
  - Backend targeted verify: `cd apps/backend-python && pytest -q tests/test_friendships_api.py` → blocked (`zsh:1: command not found: pytest`)
- Blocker/rủi ro còn lại:
  - env: thiếu `pytest` trong môi trường hiện tại.
- Batch kế tiếp:
  - **412**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity đối xứng cho error-code token handling theo web.

---

- Batch vừa xong: **410**
- Commit cuối đã chốt:
  - `3ad3b64` — `batch410: validate moment media dimensions as non-negative`
- Test-verify cuối:
  - iOS safety check: `cd apps/ios-swift && swift build` → pass (`Build complete! (0.18s)`)
  - Web safety check: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend verify bị block env:
    - `cd apps/backend-python && pytest -q tests/test_friendships_api.py` → blocked (`zsh:1: command not found: pytest`)
    - `python`/`uv` missing; `python3` binary unusable (`/usr/local/bin/python3` reports `empty`).
- Blocker/rủi ro còn lại:
  - env: thiếu backend runtime/test tooling trong môi trường hiện tại.
- Batch kế tiếp:
  - **411**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moments/feed/backend follow-up nhỏ vẫn compile-safe, tiếp tục ưu tiên parity semantics.

---

- Batch vừa xong: **409**
- Commit cuối đã chốt:
  - `6347274` — `batch409: align ios moments error-code token parity`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (5.34s)`)
  - Web safety check: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend friendships API targeted verify: `cd apps/backend-python && pytest -q tests/test_friendships_api.py` → blocked (`zsh:1: command not found: pytest`)
- Blocker/rủi ro còn lại:
  - env: thiếu `pytest` trong môi trường hiện tại.
- Batch kế tiếp:
  - **410**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moments/feed/backend contract follow-up nhỏ, tiếp tục giữ parity semantics web/iOS.

---

- Batch vừa xong: **408**
- Commit cuối đã chốt:
  - `9a65676` — `batch408: normalize web moments error-code fallback hints`
- Test-verify cuối:
  - Web: `cd apps/web-nextjs && npm run typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (0.18s)`)
  - Backend friendships API targeted verify: `cd apps/backend-python && pytest -q tests/test_friendships_api.py` → blocked (`zsh:1: command not found: pytest`)
- Blocker/rủi ro còn lại:
  - env: thiếu `pytest` trong môi trường hiện tại.
- Batch kế tiếp:
  - **409**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moments/feed parity micro-slice kế tiếp (ưu tiên iOS error-token parity follow-up hoặc backend contract follow-up nhỏ).

---

- Batch vừa xong: **407**
- Commit cuối đã chốt:
  - `51673dc` — `batch407: polish web friend-request not-pending fallback`
  - `ba79212` — `batch407: align ios friend-request not-pending fallback parity`
- Test-verify cuối:
  - Web: `cd apps/web-nextjs && npm run typecheck` → pass
  - Backend friendships API targeted verify: `cd apps/backend-python && pytest -q tests/test_friendships_api.py` → blocked (`zsh:1: command not found: pytest`)
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (3.49s)`)
- Blocker/rủi ro còn lại:
  - env: thiếu `pytest` trong môi trường hiện tại.
- Batch kế tiếp:
  - **408**
- Scope hẹp đầu tiên của batch kế tiếp:
  - backend/web moments/feed contract polish (1 slice hẹp), đồng thời giữ parity token semantics với iOS nếu có hành vi lỗi tương ứng.

---

- Batch vừa xong: **406**
- Commit cuối đã chốt:
  - `bcb300a` — `batch406: harden ios friend quick-copy failure tokens`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (2.81s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **407**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chuyển sang backend/web friend-graph contract polish hoặc mở seam moments/feed priority slice.

---

- Batch vừa xong: **405**
- Commit cuối đã chốt:
  - `acd49c3` — `batch405: harden ios friend last-action bundle quick-copy failures`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (3.47s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **406**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS friend graph parity micro-slice: align quick-copy failure token handling cho line/action còn lại hoặc chuyển backend/web friend-graph contract polish.

---

- Batch vừa xong: **404**
- Commit cuối đã chốt:
  - `87c184c` — `batch404: harden ios first-unread guard quick-copy failures`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (15.77s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **405**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chuyển từ iOS inbox micro-parity sang seam web/backend có giá trị MVP cao hơn (ưu tiên feed/friend-graph contract visibility).

---

- Batch vừa xong: **403**
- Commit cuối đã chốt:
  - `2527b08` — `batch403: harden ios first-unread jump quick-copy failures`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (14.61s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **404**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align first-unread-guard quick-copy failure token with web (`first_unread_guard_quick_copy_failed`).

---

- Batch vừa xong: **402**
- Commit cuối đã chốt:
  - `a7e772d` — `batch402: harden ios read-cursor triage quick-copy failures`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (15.12s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **403**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align first-unread-jump quick-copy failure token with web (`first_unread_jump_quick_copy_failed`).

---

- Batch vừa xong: **401**
- Commit cuối đã chốt:
  - `9619af6` — `batch401: harden ios read-cursor apply quick-copy failures`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (17.43s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **402**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align read-cursor-triage quick-copy failure token with web (`read_cursor_triage_quick_copy_failed`).

---

- Batch vừa xong: **400**
- Commit cuối đã chốt:
  - `477fe8f` — `batch400: harden ios read-cursor quick-copy failures`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (14.97s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **401**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align read-cursor-apply quick-copy failure token with web (`read_cursor_apply_quick_copy_failed`).

---

- Batch vừa xong: **399**
- Commit cuối đã chốt:
  - `f9b144a` — `batch399: harden ios sender bundle quick-copy failures`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (15.18s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **400**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align read-cursor quick-copy failure token with web (`read_cursor_quick_copy_failed`).

---

- Batch vừa xong: **398**
- Commit cuối đã chốt:
  - `1d9114c` — `batch398: harden ios sender keep-pair quick-copy failures`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (16.57s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **399**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align sender-keep-pair + send-bundle quick-copy failure token with web (`sender_keep_pair_send_bundle_quick_copy_failed`).

---

- Batch vừa xong: **397**
- Commit cuối đã chốt:
  - `ba5e9b4` — `batch397: harden ios send quick-copy failure tokens`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (26.81s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **398**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align sender-keep-pair quick-copy failure token with web (`sender_keep_pair_quick_copy_failed`).

---

- Batch vừa xong: **396**
- Commit cuối đã chốt:
  - `b0e4518` — `batch396: align ios dm delete quick-copy clipboard token`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (16.52s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **397**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align delete quick-copy success status prefix with web (`Copied delete-result quick copy to clipboard`).

---

- Batch vừa xong: **395**
- Commit cuối đã chốt:
  - `8bc8dc7` — `batch395: align ios dm delete quick-copy failure token`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (16.21s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **396**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align delete quick-copy clipboard unavailable token with web.

---

- Batch vừa xong: **394**
- Commit cuối đã chốt:
  - `55e635e` — `batch394: align ios dm delete target guard token`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (14.54s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **395**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align delete quick-copy failure token with web (`delete_result_quick_copy_failed`).

---

- Batch vừa xong: **393**
- Commit cuối đã chốt:
  - `7d490ca` — `batch393: align ios dm delete failure status token`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (15.09s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **394**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align delete target guard token with web (`message_delete_target_required`).

---

- Batch vừa xong: **392**
- Commit cuối đã chốt:
  - `f21c365` — `batch392: add ios dm delete-result quick copy parity`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (15.30s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **393**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: align delete failure status token with web (`message_delete_failed`).

---

- Batch vừa xong: **391**
- Commit cuối đã chốt:
  - `6c28180` — `batch391: add web dm delete-message parity`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck && echo "TYPECHECK_OK"` → pass (`TYPECHECK_OK`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **392**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox parity micro-slice: wire delete-message (soft-delete) summary/copy flow để match web batch391.

---

- Batch vừa xong: **390**
- Commit cuối đã chốt:
  - `d0518ef` — `batch390: add ios feed reaction quick summary copy parity`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (5.36s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **391**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chọn 1 seam hẹp ngoài moments reaction parity (ưu tiên DM/location/notifications) để tăng MVP breadth.

---

- Batch vừa xong: **389**
- Commit cuối đã chốt:
  - `44dc8bf` — `batch389: add web moment reaction shell wiring`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck && echo "TYPECHECK_OK"` → pass (`TYPECHECK_OK`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **390**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS feed parity micro-slice: wire moment reaction create/list + quick summary copy parity với web batch389.

---

- Batch vừa xong: **388**
- Commit cuối đã chốt:
  - `a92b422` — `batch388: add ios friend-request last-action copy feedback`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass (`Build complete! (4.72s)`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **389**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chọn 1 scope hẹp kế tiếp theo MVP seam ưu tiên (friend graph / moments-feed / DM / location / notifications) ngoài metadata churn.

---

- Batch vừa xong: **387**
- Commit cuối đã chốt:
  - `0104ce7` — `batch387: add web friend-request last-action copy feedback`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck && echo "TYPECHECK_OK"` → pass (`TYPECHECK_OK`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **388**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chọn 1 scope hẹp kế tiếp theo MVP seam ưu tiên (friend graph / moments-feed / DM / location / notifications) ngoài metadata churn.

---

- Batch vừa xong: **386**
- Commit cuối đã chốt:
  - `198daee` — `batch386: add web notification lifecycle snapshot copy feedback`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck && echo "TYPECHECK_OK"` → pass (`TYPECHECK_OK`)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **387**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chọn 1 scope hẹp kế tiếp theo MVP seam ưu tiên (friend graph / moments-feed / DM / location / notifications) ngoài metadata churn.

---

- Batch vừa xong: **385**
- Commit cuối đã chốt:
  - `96064f9` — `batch385: add ios location audience-remove parity summary copy`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **386**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications micro-polish parity slice (1 scope hẹp, ngoài DM).

---

- Batch vừa xong: **384**
- Commit cuối đã chốt:
  - `29dd3b2` — `batch384: add web location audience-remove parity summary copy`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck && echo "TYPECHECK_OK"` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **385**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS location parity hardening cho remove-audience quick summary + copy.

---

- Batch vừa xong: **383**
- Commit cuối đã chốt:
  - `284f8ee` — `batch383: add web location audience remove action`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck && echo "TYPECHECK_OK"` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **384**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chọn 1 slice parity hẹp (ưu tiên iOS location or notifications micro-polish) để giữ MVP breadth.

---

- Batch vừa xong: **382**
- Commit cuối đã chốt:
  - `4ba402b` — `batch382: harden ios inbox latest-message preview fallback`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **383**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chọn 1 slice hẹp ngoài DM polish để tăng MVP breadth (ưu tiên location/notifications parity hardening).

---

- Batch vừa xong: **381**
- Commit cuối đã chốt:
  - `9d4170c` — `batch381: show latest-message summary in ios inbox direct list`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **382**
- Scope hẹp đầu tiên của batch kế tiếp:
  - giữ 1 seam DM hẹp để parity polish (timestamp/preview guard parity web+iOS trong inbox direct list) trước khi quay sang seam MVP tiếp theo.

---

- Batch vừa xong: **380**
- Commit cuối đã chốt:
  - `2b5e7ff` — `batch380: show latest-message summary in web inbox direct list`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck && echo "TYPECHECK_OK"` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **381**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS inbox shell hiển thị latest-message summary fields (`id/created_at/preview`) từ `GET /conversations/direct?user_id=...` để parity với web batch380.

---

- Batch vừa xong: **379**
- Commit cuối đã chốt:
  - `cc9fc8a` — `batch379: include latest-message summary in direct conversation list`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_batch7_conversations_api.py -k "batch58_list_direct_conversations_for_user"` → pass
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_batch7_conversations_api.py` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **380**
- Scope hẹp đầu tiên của batch kế tiếp:
  - web inbox shell consume + render latest-message summary fields từ direct conversation list backend.

---

- Batch vừa xong: **377**
- Commit cuối đã chốt:
  - `3038b81` — `batch377: use backend pending-status filter in ios friend graph snapshot`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **378**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chọn 1 slice hẹp theo seam ưu tiên còn lại (moments/feed/DM/location/notifications), tránh metadata-only churn.

---

- Batch vừa xong: **376**
- Commit cuối đã chốt:
  - `aa9380f` — `batch376: use backend pending-status filter in web friend graph snapshot`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **377**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS friend graph shell chuyển pending snapshot sang backend-filtered query `status=pending` để parity với web/backend.

---

- Batch vừa xong: **375**
- Commit cuối đã chốt:
  - `bcdae27` — `batch375: add status filter for friend request listing`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_friendships_api.py -k "status_filter or reject_friend_request_updates_status"` → pass
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_friendships_api.py` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **376**
- Scope hẹp đầu tiên của batch kế tiếp:
  - web friend graph shell chuyển pending snapshot sang backend-filtered query `status=pending` để giảm mismatch dữ liệu pending/rejected sau mutate.

---

- Batch vừa xong: **370**
- Commit cuối đã chốt:
  - `8d5cc34` — `batch370: allow requester-side reject action in web friend graph shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **371**
- Scope hẹp đầu tiên của batch kế tiếp:
  - chọn 1 slice hẹp tiếp theo theo dispatch lane, ưu tiên seam còn lệch parity giữa web/iOS/backend.

---

- Batch vừa xong: **369**
- Commit cuối đã chốt:
  - `6c9913f` — `batch369: add notification delete quick summary in ios notification shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **370**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/friend-graph/moment/inbox/location slice tiếp theo theo dispatch lane (workflow-first), ưu tiên seam chưa parity hoàn toàn.

---

- Batch vừa xong: **368**
- Commit cuối đã chốt:
  - `c9c4f6f` — `batch368: add notification delete quick summary in web shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **369**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS notifications shell: thêm quick-copy `delete result summary` line + delete row action để parity với web batch368.

---

- Batch vừa xong: **366**
- Commit cuối đã chốt:
  - `2260dea` — `batch366: add lifecycle snapshot audit quick copy in web notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **367**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS notifications shell: thêm quick-copy `lifecycle snapshot audit` line để one-tap payload parity với web batch366.

---

- Batch vừa xong: **365**
- Commit cuối đã chốt:
  - `81d7832` — `batch365: add unread lifecycle mutation bundle quick copy in ios notification shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **366**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications/backend parity: thêm one-tap notification lifecycle snapshot audit line để human report deterministic across backend + web + iOS.

---

- Batch vừa xong: **364**
- Commit cuối đã chốt:
  - `329e5e3` — `batch364: add unread lifecycle mutation bundle quick copy in web notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **365**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS notifications shell: thêm quick-copy `unread lifecycle mutation bundle` để parity deterministic với web batch364.

---

- Batch vừa xong: **360**
- Commit cuối đã chốt:
  - `709ea10` — `batch360: add friend-request last-action summary bundle quick copy in web friend graph shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **361**
- Scope hẹp đầu tiên của batch kế tiếp:
  - iOS friend-graph shell: thêm quick-copy last-action request summary bundle (`create + decision + counts`) để parity deterministic report với web batch360.

---

- Batch vừa xong: **359**
- Commit cuối đã chốt:
  - `8170945` — `batch359: add last-create feed-gate bundle quick copy in ios feed shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **360**
- Scope hẹp đầu tiên của batch kế tiếp:
  - web friend-graph shell: thêm quick-copy last-action request summary bundle (`create + decision + counts`) để one-tap deterministic report sau mutate flow.

---

- Batch vừa xong: **358**
- Commit cuối đã chốt:
  - `92196fa` — `batch358: add last-create feed-gate bundle quick copy in web moment shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **359**
- Scope hẹp đầu tiên của batch kế tiếp:
  - private-feed shell (iOS): thêm quick-copy last-create + gate-summary bundle line (kèm created_moment_id) để parity với web batch358.

---

- Batch vừa xong: **357**
- Commit cuối đã chốt:
  - `93e8a14` — `batch357: add moment create-feed-gate bundle quick copy in ios shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **358**
- Scope hẹp đầu tiên của batch kế tiếp:
  - private-feed shell (web): thêm quick-copy last-create + gate-summary bundle line (kèm created_moment_id) để one-tap report deterministic sau create flow.

---

- Batch vừa xong: **356**
- Commit cuối đã chốt:
  - `95b6f3a` — `batch356: add moment create-feed-gate bundle quick copy in web shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **357**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment shell (iOS): thêm quick-copy create + feed-gate bundle line (image + caption + gate summary) để parity với web batch356.

---

- Batch vừa xong: **355**
- Commit cuối đã chốt:
  - `a19b4ae` — `batch355: add friend-request create-accept bundle quick copy in ios friend graph shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **356**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment shell (web): thêm quick-copy create + feed-gate bundle line (image + caption + gate summary) để one-tap report seam moment/private feed.

---

- Batch vừa xong: **354**
- Commit cuối đã chốt:
  - `e306089` — `batch354: add friend-request create-accept bundle quick copy in web friend graph shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **355**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (iOS): thêm quick-copy friend-request create+accept bundle line để parity với web batch354.

---

- Batch vừa xong: **353**
- Commit cuối đã chốt:
  - `b4db83c` — `batch353: add lifecycle pair mutation quick copy in ios notification shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **354**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web): thêm quick-copy friend-request create+accept bundle line để one-tap report happy-path create->accept parity.

---

- Batch vừa xong: **352**
- Commit cuối đã chốt:
  - `5df8099` — `batch352: add lifecycle pair mutation quick copy in web notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **353**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications shell (iOS): thêm quick-copy lifecycle pair mutation line để parity one-tap report create+mark-read/unread transition với web batch352.

---

- Batch vừa xong: **351**
- Commit cuối đã chốt:
  - `bc95c98` — `batch351: add friend-request create-reject bundle quick copy in ios friend graph shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **352**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notifications shell (web): thêm quick-copy last lifecycle pair mutation line để one-tap parity report create+mark-read/unread transition.

---

- Batch vừa xong: **350**
- Commit cuối đã chốt:
  - `bd7fe3e` — `batch350: add friend-request create-reject bundle quick copy in web friend graph shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **351**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (iOS): thêm one-tap quick copy marker + bundle cho friend-request create/reject parity với web vừa chốt.

---

- Batch vừa xong: **349**
- Commit cuối đã chốt:
  - `5afe2ce` — `batch349: add sender keep-pair plus send-result bundle quick copy in web dm shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **350**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web): thêm one-tap quick copy bundle cho friend-request create/reject parity line để tiếp tục ưu tiên seam friend graph theo objective.

---

- Batch vừa xong: **348**
- Commit cuối đã chốt:
  - `770589e` — `batch348: add sender keep-pair plus send-result bundle quick copy in ios dm shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **349**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM shell (web): thêm one-tap action `Copy quick sender keep-pair + send result bundle` để parity bundle copy path với iOS.

---

- Batch vừa xong: **347**
- Commit cuối đã chốt:
  - `dc919a8` — `batch347: add sender keep-pair quick-copy marker in web dm shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **348**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM shell (iOS): thêm one-tap action `Copy quick sender keep-pair + send result bundle` để copy cùng lúc send-result + keep-pair marker cho report parity nhanh.

---

- Batch vừa xong: **346**
- Commit cuối đã chốt:
  - `119d3c3` — `batch346: add sender keep-pair quick-copy marker in ios dm shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **347**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM shell (web): thêm quick-copy action cho sender keep-pair marker payload (`user_pair_source=kept_user_a+user_b` + `sender_source=session_user`) để parity one-tap copy-debug với iOS.

---

- Batch vừa xong: **345**
- Commit cuối đã chốt:
  - `7f8240d` — `batch345: add session-sender keep-pair quick send in web dm shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **346**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM shell (iOS): thêm explicit quick-copy line cho sender quick-send marker (`user_pair_source=kept_user_a+user_b` + `sender_source=session_user`) để parity copy-debug trực tiếp với web status marker.

---

- Batch vừa xong: **344**
- Commit cuối đã chốt:
  - `4975c0f` — `batch344: add session-sender keep-pair quick send in ios dm shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **345**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM shell (web): thêm quick action `Use current session user as sender + keep user_a/user_b pair + send` để one-tap sender quick-send parity với iOS path vừa bổ sung.

---

- Batch vừa xong: **343**
- Commit cuối đã chốt:
  - `e7d156c` — `batch343: add session-user-b keep-user-a quick open in ios dm shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **344**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM shell (iOS): thêm quick action `Use current session user as sender + keep user_a/user_b pair + send` để one-tap send parity với web sender quick-send path mà không đổi pair context.

---

- Batch vừa xong: **342**
- Commit cuối đã chốt:
  - `423f858` — `batch342: add session-user-b keep-user-a quick open in web dm shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **343**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM shell (iOS): thêm quick action `Use current session user as user_b (peer) + keep user_a + open direct thread` để one-tap parity với web DM peer-context apply path.

---

- Batch vừa xong: **341**
- Commit cuối đã chốt:
  - `3d328e2` — `batch341: add session-viewer keep-author quick load in ios moment shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **342**
- Scope hẹp đầu tiên của batch kế tiếp:
  - DM shell (web): thêm quick action `Use current session user as user_b (peer) + keep user_a + open direct thread` để hoàn thiện cặp one-tap context apply song song với path user_a hiện có.

---

- Batch vừa xong: **339**
- Commit cuối đã chốt:
  - `6faffce` — `batch339: add session-requester keep-receiver quick send in web friend graph shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **340**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment shell (web): thêm quick action `Use current session user as viewer + keep author + load private feed` để one-tap parity với hướng session-viewer verify feed gate mà không đụng create flow.

---

- Batch vừa xong: **338**
- Commit cuối đã chốt:
  - `eedda47` — `batch338: add session-requester keep-receiver quick send in ios friend graph shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **339**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web): thêm quick action `Use current session user as requester + keep receiver + send friend request` để giữ one-tap parity web/iOS cho session requester send path.

---

- Batch vừa xong: **337**
- Commit cuối đã chốt:
  - `20cdb3f` — `batch337: add payload-json validation marker in ios notification shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **338**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (iOS): thêm quick action `Use current session user as requester + keep receiver + send friend request` để one-tap send path parity với các session-user quick action khác.

---

- Batch vừa xong: **336**
- Commit cuối đã chốt:
  - `5c925e2` — `batch336: add session-user create-and-load quick action in ios notification shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **337**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (iOS): thêm payload JSON input + validation marker `notification_payload_json_invalid` để parity guard với web create flow.

---

- Batch vừa xong: **335**
- Commit cuối đã chốt:
  - `012ebe9` — `batch335: add session-user create-and-load quick action in web notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **336**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (iOS): thêm quick action `Use current session user + create notification + load` để one-tap lifecycle smoke path parity với web.

---

- Batch vừa xong: **334**
- Commit cuối đã chốt:
  - `8c1ee46` — `batch334: add session-owner load quick action in ios location shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **335**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web): thêm quick action `Use current session user + create notification + load` để one-tap lifecycle smoke path.

---

- Batch vừa xong: **333**
- Commit cuối đã chốt:
  - `902470c` — `batch333: add session-owner reload quick action in web location shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **334**
- Scope hẹp đầu tiên của batch kế tiếp:
  - location shell (iOS): thêm quick action `Use current session user as owner + load location status` để one-tap parity hoàn chỉnh với web quick action.

---

- Batch vừa xong: **332**
- Commit cuối đã chốt:
  - `0e5b109` — `batch332: keep session quick-open on valid direct peer pair`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **333**
- Scope hẹp đầu tiên của batch kế tiếp:
  - location shell (web): thêm quick action `Use current session user as owner + reload counts` để parity nhanh với iOS location shell.

---

- Batch vừa xong: **331**
- Commit cuối đã chốt:
  - `0a78bbc` — `batch331: add session viewer+author create-and-reload quick action`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **332**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct messaging shell (web+iOS): thêm quick action `Use current session user as user_a + user_b + open direct thread` để one-tap smoke DM open/load path không cần nhập tay cả 2 user field.

---

- Batch vừa xong: **330**
- Commit cuối đã chốt:
  - `3e2c17d` — `batch330: add session-author create-and-reload quick action`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **331**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment posting shell (web+iOS): thêm quick action `Use current session user as viewer + author + create moment + reload feed` để one-tap giảm dependency nhập tay viewer trong post→feed retest.

---

- Batch vừa xong: **329**
- Commit cuối đã chốt:
  - `3dd4fc9` — `batch329: add session-receiver quick-send actions in friend graph shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **330**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment posting shell (web+iOS): thêm quick action `Use current session user as author + create moment + reload feed` để one-tap verify seam post→feed.

---

- Batch vừa xong: **328**
- Commit cuối đã chốt:
  - `6be60e8` — `batch328: add session-requester auto-load friend graph actions`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **329**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web+iOS): thêm quick action `Use current session user as receiver + send friend request` để one-tap test chiều outbound request từ requester=session user.

---

- Batch vừa xong: **327**
- Commit cuối đã chốt:
  - `a5a973e` — `batch327: add session-requester quick action in friend graph shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **328**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web+iOS): thêm quick action `Use current session user as requester + load friend graph` để one-tap apply requester context rồi reload snapshot ngay.

---

- Batch vừa xong: **326**
- Commit cuối đã chốt:
  - `c81893d` — `batch326: add snapshot source-line copied status markers on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **327**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web+iOS): thêm quick action `Use current session user as requester` để giảm nhập tay khi tạo friend request.

---

- Batch vừa xong: **325**
- Commit cuối đã chốt:
  - `09c7ee8` — `batch325: add snapshot source-line quick copy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **326**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm status marker `last_source_state_snapshot_source_line_copied` khi copy source-marker line để QA scan log nhanh.

---

- Batch vừa xong: **324**
- Commit cuối đã chốt:
  - `927a297` — `batch324: add source markers for last snapshot recopy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **325**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho line `last_source_state_snapshot_source=...` để QA copy marker nguồn snapshot ngay khi report.

---

- Batch vừa xong: **323**
- Commit cuối đã chốt:
  - `e9fac07` — `batch323: add last source-state snapshot quick copy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **324**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm source marker `last_source_state_snapshot_source=source_state_snapshot_copy|manual_recopy` để QA phân biệt token mới vs re-copy từ snapshot đã lưu.

---

- Batch vừa xong: **322**
- Commit cuối đã chốt:
  - `6f8fcbd` — `batch322: persist last source-state snapshot token on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **323**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho line `last_source_state_snapshot=...` để QA re-copy snapshot token mà không cần copy source-state raw line lại.

---

- Batch vừa xong: **321**
- Commit cuối đã chốt:
  - `d8a2309` — `batch321: add source-state snapshot quick copy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **322**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm token `last_source_state_snapshot=...` để lưu payload source-state vừa copy cho QA đối chiếu history nhanh.

---

- Batch vừa xong: **320**
- Commit cuối đã chốt:
  - `f7f16a2` — `batch320: add delete copy audit ready-count source-state on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **321**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho source-state line có `ready_count` để QA copy snapshot readiness đầy đủ bằng 1 click.

---

- Batch vừa xong: **319**
- Commit cuối đã chốt:
  - `f876528` — `batch319: add first-ready source-line quick copy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **320**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm source-state aggregate `ready_count=<n>/total=<n>` để QA scan nhanh mức readiness trước one-shot copy.

---

- Batch vừa xong: **318**
- Commit cuối đã chốt:
  - `84ab5b2` — `batch318: add first-ready source marker for delete copy audit on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **319**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho line `delete_copy_audit_first_ready_source=...` để QA copy marker trực tiếp.

---

- Batch vừa xong: **317**
- Commit cuối đã chốt:
  - `74162dd` — `batch317: add first-ready delete copy audit quick action on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **318**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm status marker `delete_copy_audit_first_ready_source=<source|none>` khi chạy one-shot action để QA thấy rõ source đã auto-pick.

---

- Batch vừa xong: **315**
- Commit cuối đã chốt:
  - `e035bba` — `batch315: add delete copy audit source chips on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **316**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm line `delete_copy_audit_source_state=quick_delete_parity:<ready|missing>/last_delete_result:<ready|missing>/copied_feedback:<ready|missing>` + copy action để QA biết source nào đang có payload hợp lệ.

---

- Batch vừa xong: **314**
- Commit cuối đã chốt:
  - `bb09591` — `batch314: add delete copy audit quick-copy line on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **315**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm `delete_copy_audit_source` quick filter chips (`quick_delete_parity` / `last_delete_result` / `copied_feedback`) để QA force-generate audit token theo từng source mà không phải nhớ thứ tự click.

---

- Batch vừa xong: **313**
- Commit cuối đã chốt:
  - `4bccf18` — `batch313: add delete summary copy-source markers on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **314**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): bổ sung quick-copy line `delete_copy_audit=source:.../value:...` để gom audit payload thành 1 token ngắn, tránh phải parse status sentence dài khi report thủ công.

---

- Batch vừa xong: **312**
- Commit cuối đã chốt:
  - `29edaca` — `batch312: add copied-delete-summary feedback quick copy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **313**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm marker `delete_summary_copy_source=quick_delete_parity|last_delete_result|copied_feedback` vào status copy success để audit nguồn copy action ngay trong log/status.

---

- Batch vừa xong: **311**
- Commit cuối đã chốt:
  - `ea67e22` — `batch311: add delete snapshot source markers on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **312**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho feedback token `Last copied delete summary`/`Copied delete summary` để QA re-copy payload vừa copy mà không cần delete lại.

---

- Batch vừa xong: **310**
- Commit cuối đã chốt:
  - `079f731` — `batch310: add delete summary quick-copy actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **311**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm `delete_snapshot_source=manual_input|preset_row|first_authored_quick_pick` marker vào quick delete parity summary để trace nguồn delete target rõ hơn.

---

- Batch vừa xong: **309**
- Commit cuối đã chốt:
  - `2b07ac7` — `batch309: add ios feed delete parity summary markers`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **310**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action cho `Quick delete parity summary` + `Last delete result summary` để report create->delete tokens nhanh hơn.

---

- Batch vừa xong: **308**
- Commit cuối đã chốt:
  - `6091c72` — `batch308: add web feed delete moment parity shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **309**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell phía iOS: mirror delete-result quick summary marker parity (`delete_result/moment_id/deleted_at/author_loaded_count/feed_match_count`) để report đồng format với web.

---

- Batch vừa xong: **307**
- Commit cuối đã chốt:
  - `e7d337d` — `batch307: add gate snapshot source markers for feed parity`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **308**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell phía web: thêm delete moment action parity (`DELETE /moments/{id}`) + status summary để verify vòng create->delete ngay trên web.

---

- Batch vừa xong: **306**
- Commit cuối đã chốt:
  - `09c44f2` — `batch306: add feed visibility reason markers in status and quick copy`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **307**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm create-vs-reload gate parity marker `gate_snapshot_source=create_flow|reload_flow` để đối chiếu nhanh nguồn snapshot trong report.

---

- Batch vừa xong: **304**
- Commit cuối đã chốt:
  - `0ecd3fd` — `batch304: add lifecycle-pair transition markers in notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **305**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy feed visibility gate summary `viewer_access + visible_count + first_moment_id` ngay sau reload để verify private feed contract nhanh hơn.

---

- Batch vừa xong: **303**
- Commit cuối đã chốt:
  - `0d74159` — `batch303: add lifecycle-pair subject markers in notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **304**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm transition marker `lifecycle_pair_transition=create_read_state->mutation_read_state` để đọc outcome nhanh hơn.

---

- Batch vừa xong: **302**
- Commit cuối đã chốt:
  - `729d3f4` — `batch302: add lifecycle-pair state markers in notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **303**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm guard marker `lifecycle_pair_subject=same_notification|cross_notification` để tách rõ matched/mismatched root cause.

---

- Batch vừa xong: **301**
- Commit cuối đã chốt:
  - `0db7546` — `batch301: add notification lifecycle-pair quick copy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **302**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy lifecycle pair status marker `lifecycle_pair_state=matched|mismatched|missing` để report chain outcome rõ hơn.

---

- Batch vừa xong: **300**
- Commit cuối đã chốt:
  - `47deb98` — `batch300: add notification create-result delta quick copy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **301**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy lifecycle pair line gộp `create_result + mutation_delta` để report liền mạch create->toggle trong 1 payload.

---

- Batch vừa xong: **299**
- Commit cuối đã chốt:
  - `707c8e2` — `batch299: add notification mutation-delta quick copy on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **300**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy create-result delta `notification_id/read_state/current_page_unread/total_unread_count` ngay sau create để verify lifecycle create->toggle nhanh hơn.

---

- Batch vừa xong: **298**
- Commit cuối đã chốt:
  - `b4d9981` — `batch298: add notification page-cursor summary copy actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **299**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy mutation delta sau mark read/unread `notification_id/read_state/current_page_unread/total_unread_count` để report toggle outcome nhanh hơn.

---

- Batch vừa xong: **297**
- Commit cuối đã chốt:
  - `985de64` — `batch297: add quick location state summary copy actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **298**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy notification page cursor summary `user_id/limit/offset/filter_mode/count/unread_count/total_unread_count` để tăng khả năng test seam #6 theo priority.

---

- Batch vừa xong: **296**
- Commit cuối đã chốt:
  - `cf07bdc` — `batch296: add feed-visibility delta copy actions after moment create`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **297**
- Scope hẹp đầu tiên của batch kế tiếp:
  - location shell (web+iOS): thêm quick-copy location state summary `owner/share_id/is_active/sharing_mode/audience_count/snapshot_count` để tăng khả năng test seam #5 theo priority.

---

- Batch vừa xong: **295**
- Commit cuối đã chốt:
  - `4e1b033` — `batch295: add friend-graph quick delta copy actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **296**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment posting shell (web+iOS): thêm quick-copy feed-visibility delta `viewer/feed_count/first_moment_id` ngay sau create để tăng khả năng test seam #2 theo priority.

---

- Batch vừa xong: **294**
- Commit cuối đã chốt:
  - `63107e8` — `batch294: add web quick page-meta copy action in notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **295**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web+iOS): thêm quick-copy delta line `accepted_count/pending_inbound/pending_outbound` sau accept/reject để tăng khả năng test social seam theo priority #1.

---

- Batch vừa xong: **293**
- Commit cuối đã chốt:
  - `18cf958` — `batch293: add ios quick page-meta copy action in notification shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **294**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web): thêm quick-copy page meta line (`count/unread_count/total_unread_count/limit/offset/filter_mode`) để parity report đầy đủ web+iOS khi paging/filter.

---

- Batch vừa xong: **292**
- Commit cuối đã chốt:
  - `70c6749` — `batch292: add web quick unread summary copy action`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **293**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (iOS): thêm quick copy page meta line (`count/unread_count/total_unread_count/limit/offset/filter_mode`) để parity report nhanh khi paging/filter.

---

- Batch vừa xong: **291**
- Commit cuối đã chốt:
  - `5d9a0a5` — `batch291: add ios quick unread summary copy action`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **292**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web): thêm one-tap copy action cho quick unread summary line (`current_page_unread / total_unread_count`) để parity report đồng bộ với iOS.

---

- Batch vừa xong: **290**
- Commit cuối đã chốt:
  - `de5a40c` — `batch290: add web quick unread summary line in notification shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **291**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (iOS): thêm one-tap copy action cho quick unread summary line (`current_page_unread / total_unread_count`) để parity report nhanh.

---

- Batch vừa xong: **289**
- Commit cuối đã chốt:
  - `00cbf0d` — `batch289: add ios quick unread summary line in notification shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **290**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web): thêm quick unread summary line (`current_page_unread / total_unread_count`) để parity nhanh với iOS/backend.

---

- Batch vừa xong: **287**
- Commit cuối đã chốt:
  - `6593ba2` — `batch287: add read-cursor triage quick-copy line on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **288**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap preset `apply focus user + first unread candidate` trên iOS parity với web jump action status-copy flow.

---

- Batch vừa xong: **286**
- Commit cuối đã chốt:
  - `d6bb3a4` — `batch286: add current-member cursor snapshot to apply quick copy`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **287**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap `copy read-cursor triage line` (tokenized previous/applied/current/apply_state) để report parity nhanh hơn trên web+iOS.

---

- Batch vừa xong: **285**
- Commit cuối đã chốt:
  - `8d61ece` — `batch285: add previous-cursor baseline to read-cursor apply quick copy`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **286**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy token cho current member cursor snapshot (`current_member_cursor`) để đối chiếu trực tiếp với previous/applied trong cùng dòng trên web+iOS.

---

- Batch vừa xong: **284**
- Commit cuối đã chốt:
  - `3c09772` — `batch284: add read-cursor apply-state markers on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **285**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy note cho last-read baseline (`previous_cursor_message`) để explain tại sao apply_state=noop trên web+iOS.

---

- Batch vừa xong: **283**
- Commit cuối đã chốt:
  - `0578cae` — `batch283: add first-unread guard quick-copy markers on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **284**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm read-cursor no-op apply marker (`read_cursor_apply_state=noop|updated`) để tách rõ no-op guard và apply result trên web+iOS.

---

- Batch vừa xong: **282**
- Commit cuối đã chốt:
  - `4eb2db4` — `batch282: add first-unread no-op guard status markers on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **283**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy snapshot marker cho no-op guard (`first_unread_guard_state`) để report parity một dòng trên web+iOS.

---

- Batch vừa xong: **281**
- Commit cuối đã chốt:
  - `a690ecf` — `batch281: add first-unread jump quick-copy markers on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **282**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm guard/status khi first-unread candidate không đổi (already_at_latest_or_no_unread) để testers đỡ nhầm kết quả no-op trên web+iOS.

---

- Batch vừa xong: **280**
- Commit cuối đã chốt:
  - `c71f16b` — `batch280: add member first-unread focus auto-mark actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **281**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm status hint/read-state copy marker sau jump-first-unread để giảm ambiguity khi verify multi-user parity trên web+iOS.

---

- Batch vừa xong: **279**
- Commit cuối đã chốt:
  - `bcaf55f` — `batch279: add member latest-loaded focus auto-mark actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **280**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap action set member focus + first unread candidate rồi auto-mark read trên web+iOS để cover parity jump-first-unread.

---

- Batch vừa xong: **278**
- Commit cuối đã chốt:
  - `69ed4b4` — `batch278: add member-cursor context-focus auto-mark actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **279**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap auto-mark action dùng latest loaded message cho focus user trên web+iOS để cover case member cursor message trống.

---

- Batch vừa xong: **277**
- Commit cuối đã chốt:
  - `58eedff` — `batch277: add member-cursor context-focus one-tap actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **278**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action one-tap apply member cursor context+focus rồi trigger read-cursor update ngay trên web+iOS để giảm thêm 1 bước thao tác.

---

- Batch vừa xong: **276**
- Commit cuối đã chốt:
  - `982018b` — `batch276: add member-cursor context one-tap actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **277**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action one-tap apply member cursor context + focus user đồng thời trên web+iOS để rút ngắn verify read_state.

---

- Batch vừa xong: **275**
- Commit cuối đã chốt:
  - `c827afa` — `batch275: add member-cursor message-target one-tap actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **276**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap action apply đồng thời member user + member cursor message vào read-cursor target form trên web+iOS.

---

- Batch vừa xong: **274**
- Commit cuối đã chốt:
  - `514f34e` — `batch274: add member-row one-tap target-focus actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **275**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap action dùng selected member cursor message làm read-cursor target message (web+iOS) để rút ngắn setup mark-read case.

---

- Batch vừa xong: **273**
- Commit cuối đã chốt:
  - `e1820a0` — `batch273: add member-row quick read-cursor target actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **274**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action one-tap apply member row cho cả read-cursor target + read focus trên web+iOS để rút ngắn thao tác retest.

---

- Batch vừa xong: **272**
- Commit cuối đã chốt:
  - `a34edcc` — `batch272: add member-row quick focus-user actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **273**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action set read-cursor target user theo member row chọn sẵn (web+iOS) để mark-read parity nhanh hơn.

---

- Batch vừa xong: **271**
- Commit cuối đã chốt:
  - `0a0ff0d` — `batch271: add read-cursor apply-result quick-copy summaries on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **272**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action set read focus user từ member row chọn sẵn trên web+iOS để giảm nhập tay khi retest read-state transitions.

---

- Batch vừa xong: **270**
- Commit cuối đã chốt:
  - `3313396` — `batch270: add session-user read-cursor target and focus quick actions`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **271**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy line chuẩn hóa read-cursor apply result (`target_user + applied_message + focus_user + read_state`) trên web+iOS để report parity sau thao tác mark-read.

---

- Batch vừa xong: **269**
- Commit cuối đã chốt:
  - `e2c2765` — `batch269: add session-user read-focus quick action on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **270**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action web+iOS đồng bộ apply session user cho cả `Member user UUID` (read-cursor update target) cùng `Read-status focus user` để retest read-cursor parity không cần nhập tay.

---

- Batch vừa xong: **268**
- Commit cuối đã chốt:
  - `da1c27a` — `batch268: add dm read-cursor quick-copy summaries on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **269**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action web+iOS dùng current session user làm focus user cho read-state summary để giảm nhập tay khi retest.

---

- Batch vừa xong: **267**
- Commit cuối đã chốt:
  - `2efcf86` — `batch267: add quick copy send-result clipboard actions on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **268**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy read-cursor focus summary (`focus_user + resolved_message + read_state`) trên web+iOS.

---

- Batch vừa xong: **266**
- Commit cuối đã chốt:
  - `e35e51e` — `batch266: add dm send-result quick-copy summaries on web and ios`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **267**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action copy `Quick copy send result` vào clipboard cho web+iOS.

---

- Batch vừa xong: **265**
- Commit cuối đã chốt:
  - `36333ac` — `batch265: add session-user quick send action in ios dm shell`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **266**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy send status line chuẩn hóa sender + message_id trên web+iOS.

---

- Batch vừa xong: **264**
- Commit cuối đã chốt:
  - `93a12b5` — `batch264: add session-sender quick send action in web dm shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **265**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action iOS `Use current session user as User A + send` để parity thao tác gửi nhanh với web.

---

- Batch vừa xong: **263**
- Commit cuối đã chốt:
  - `2e3ab8b` — `batch263: add direct-message quick-copy conversation summaries`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **264**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action web `Use current session user as sender + send` để giảm nhập tay khi retest DM seam.

---

- Batch vừa xong: **262**
- Commit cuối đã chốt:
  - `47cb6df` — `batch262: add session-viewer quick load action in web feed shell`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **263**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy conversation summary (`user_a + user_b + message_count + last_message_id`) trên web+iOS.

---

- Batch vừa xong: **261**
- Commit cuối đã chốt:
  - `4c02683` — `batch261: add private-feed quick-copy summaries in moment shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **262**
- Scope hẹp đầu tiên của batch kế tiếp:
  - private-feed shell: thêm quick action `Use current session user as viewer + load` trên web.

---

- Batch vừa xong: **260**
- Commit cuối đã chốt:
  - `9614a3b` — `batch260: add session-user author quick preset in moment shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **261**
- Scope hẹp đầu tiên của batch kế tiếp:
  - private-feed shell: thêm quick-copy list summary (viewer + feed_count + first_moment_id) trên web+iOS.

---

- Batch vừa xong: **259**
- Commit cuối đã chốt:
  - `f42dc59` — `batch259: add quick-copy moment payload summaries`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **260**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment-posting shell: thêm quick preset dùng session user làm author + status copy nguồn author.

---

- Batch vừa xong: **258**
- Commit cuối đã chốt:
  - `16a8ff4` — `batch258: add quick-copy friend graph summary line`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **259**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment-posting shell: thêm quick-copy payload summary (author + image_url + caption).

---

- Batch vừa xong: **257**
- Commit cuối đã chốt:
  - `35c63e9` — `batch257: add pending direction breakdown to friend graph load status`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **258**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend-graph shell: thêm quick-copy line chứa user + pending inbound/outbound + accepted count.

---

- Batch vừa xong: **256**
- Commit cuối đã chốt:
  - `a8ff434` — `batch256: add inbound outbound pending summaries to friend graph shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **257**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend-graph shell: thêm inbound/outbound breakdown trực tiếp vào status message sau load để copy/paste kết quả test nhanh.

---

- Batch vừa xong: **255**
- Commit cuối đã chốt:
  - `b073147` — `batch255: replace unread_only booleans with mode labels`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **256**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend-graph shell: thêm pending summary line (`Inbound pending`/`Outbound pending`) trên web+iOS Profile.

---

- Batch vừa xong: **254**
- Commit cuối đã chốt:
  - `3ac1d12` — `batch254: show current unread filter mode near presets`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **255**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: đổi summary mode hiển thị từ boolean sang nhãn dễ đọc (`All`/`Unread only`).

---

- Batch vừa xong: **253**
- Commit cuối đã chốt:
  - `f9081ef` — `batch253: show status hint when unread preset is selected`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **254**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm tiny selected-state marker gần preset controls để dễ nhận biết mode hiện tại.

---

- Batch vừa xong: **252**
- Commit cuối đã chốt:
  - `721661f` — `batch252: add unread filter quick presets in notification shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **253**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm status hint tức thì khi bấm preset (`All`/`Unread only`) trước bước Load.

---

- Batch vừa xong: **251**
- Commit cuối đã chốt:
  - `a445633` — `batch251: add read-state legend near notification lists`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **252**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm filter quick presets (`All`/`Unread only`) dạng segmented buttons để giảm toggle ambiguity.

---

- Batch vừa xong: **250**
- Commit cuối đã chốt:
  - `e35cde6` — `batch250: include read-state symbols in toggle status copy`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **251**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm tiny legend line `● read` / `○ unread` gần danh sách row.

---

- Batch vừa xong: **249**
- Commit cuối đã chốt:
  - `0b196ed` — `batch249: add row read-state symbols near toggle action`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **250**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm status copy sau toggle để nhắc rõ ký hiệu `● read` / `○ unread`.

---

- Batch vừa xong: **248**
- Commit cuối đã chốt:
  - `dde8939` — `batch248: clarify quick-apply copy when session user unchanged`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **249**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm lightweight row-level read-state symbol gần nút để scan read/unread nhanh hơn khi paging.

---

- Batch vừa xong: **247**
- Commit cuối đã chốt:
  - `997d2c2` — `batch247: show explicit pending-window hints in notification shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **248**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: normalize copy cho quick apply khi session-user trùng draft hiện tại.

---

- Batch vừa xong: **246**
- Commit cuối đã chốt:
  - `67a6ea0` — `batch246: quick-apply session user and reset offset on user change`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **247**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm explicit pending-window hint line để tester thấy mismatch ngay cả khi không nhìn thấy nút load.

---

- Batch vừa xong: **245**
- Commit cuối đã chốt:
  - `2334e34` — `batch245: add load-window change guard in web and ios notification shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **246**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm quick apply current user + auto-reset page offset khi user id đổi.

---

- Batch vừa xong: **244**
- Commit cuối đã chốt:
  - `79adb18` — `batch244: add quick paging presets to web and ios notification shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **245**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm auto-load guard theo page window change (optional quick reload button copy/state).

---

- Batch vừa xong: **243**
- Commit cuối đã chốt:
  - `ac02f36` — `batch243: add unread-only filter controls to web and ios notification shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **244**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm preset quick offsets (first/next/prev) trên web/iOS list controls.

---

- Batch vừa xong: **242**
- Commit cuối đã chốt:
  - `d594ffa` — `batch242: add pagination controls to web and ios notification shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **243**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm `unread_only` toggle trên web/iOS list controls.

---

- Batch vừa xong: **241**
- Commit cuối đã chốt:
  - `b033484` — `batch241: adopt total unread summary in web and ios notification shells`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **242**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm pagination controls (`limit`/`offset`) trên web/iOS.

---

- Batch vừa xong: **240**
- Commit cuối đã chốt:
  - `b6fc2e5` — `batch240: add total unread summary for paged notifications`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_notifications_security_api.py -k "pagination_and_sorting_parity or notifications_list_unread"` → 3 passed, 10 deselected
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **241**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: web/iOS contract adoption cho `total_unread_count`.

---

- Batch vừa xong: **239**
- Commit cuối đã chốt:
  - `15f5c35` — `batch239: add notification list pagination and stable sorting`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_notifications_security_api.py -k "pagination_and_sorting_parity or notifications_list_unread"` → 3 passed, 10 deselected
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **240**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: total unread summary parity cho paged list response.

---

- Batch vừa xong: **238**
- Commit cuối đã chốt:
  - `f2540dc` — `batch238: add unread count to notifications list response`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_notifications_security_api.py -k "notifications_list_unread"` → 2 passed, 10 deselected
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **239**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: sorting/pagination parity cho list contract.

---

- Batch vừa xong: **237**
- Commit cuối đã chốt:
  - `99da484` — `batch237: add unread-only filter for notifications list`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_notifications_security_api.py -k unread_only` → 1 passed, 10 deselected
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **238**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: unread summary/count parity để client không phải tự count local.

---

- Batch vừa xong: **235**
- Commit cuối đã chốt:
  - `2c4c637` — `batch235: clear stale read cursor when message is deleted`
  - `0bdd965` — `batch235: sync workflow docs after read-cursor cleanup`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_batch7_conversations_api.py` → 3 passed
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **236**
- Scope hẹp đầu tiên của batch kế tiếp:
  - location sharing state shell: stop-sharing contract parity cho list/state response.

---

- Batch vừa xong: **233**
- Commit cuối đã chốt:
  - `17ca17b` — `batch233: improve ios moment posting error clarity`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **234**
- Scope hẹp đầu tiên của batch kế tiếp:
  - private friend feed shell: backend loại bỏ moment `deleted_at != null` khỏi list/feed response + test hồi quy.

---

- Batch vừa xong: **232**
- Commit cuối đã chốt:
  - `3738b54` — `batch232: wire friend-request reject flow across backend and ios`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_friendships_api.py` → 7 passed
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **233**
- Scope hẹp đầu tiên của batch kế tiếp:
  - wire 1 friction point cho moment posting shell (ưu tiên image+caption create/upload flow) để đẩy thêm một social seam sau friend graph.

---

- Batch vừa xong: **230**
- Commit cuối đã chốt:
  - `a53dc6d` — `batch230: add row lock-state badge near delete action`
  - `2f308f0` — `batch230: sync workflow docs after lock-state badge`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **231**
- Scope hẹp đầu tiên của batch kế tiếp:
  - đồng bộ style badge lock-state cho consistency với status copy (tone/copy gọn hơn khi scroll dày).

---

- Batch vừa xong: **229**
- Commit cuối đã chốt:
  - `df805ad` — `batch229: tint row delete readiness hint by lock state`
  - `0cc3a22` — `batch229: sync workflow docs after lock tint hint`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **230**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm lock-state badge ngắn ở row action để nhìn trạng thái tại chỗ ngay cả khi chưa đọc hint text.

---

- Batch vừa xong: **228**
- Commit cuối đã chốt:
  - `af92ad2` — `batch228: show status when row delete lock toggles`
  - `35ab051` — `batch228: sync workflow docs after row delete lock status hint`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **229**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm visual emphasis nhẹ cho trạng thái unlock (ví dụ caption tint theo lock/unlock) để giảm bỏ sót status text khi test nhanh.

---

- Batch vừa xong: **227**
- Commit cuối đã chốt:
  - `19198e9` — `batch227: add inline hint for row delete unlock path`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **228**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm trạng thái hint ngắn khi toggle vừa chuyển từ lock -> unlock (status copy) để tester biết row delete đã sẵn sàng.

---

- Batch vừa xong: **226**
- Commit cuối đã chốt:
  - `a96ada2` — `batch226: add unlock hint copy for row delete lock`
  - `b1aaadf` — `batch226: sync workflow docs after row delete unlock hint`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **227**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm trợ giúp tại chỗ (inline hint/footnote gần row actions) giải thích nhanh “tắt toggle trên form để mở khoá row delete” nhằm giảm chuyển ngữ cảnh khi test nhiều row.

---

- Batch vừa xong: **225**
- Commit cuối đã chốt:
  - `cdb8cb6` — `batch225: gate row delete behind confirmation toggle`
  - `de012f8` — `batch225: sync workflow docs after delete safety toggle`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **226**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm lightweight safety copy ở row button khi toggle đang bật (ví dụ `Unlock to delete`) để giảm mơ hồ vì disable-state.

---

- Batch vừa xong: **224**
- Commit cuối đã chốt:
  - `a2dc93f` — `batch224: add ios one-tap delete from feed row`
  - `387e3f5` — `batch224: sync workflow docs after ios one-tap delete`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **225**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm confirm safety toggle cho one-tap row delete để hạn chế nhầm thao tác trên môi trường test có data thật.

---

- Batch vừa xong: **223**
- Commit cuối đã chốt:
  - `9bfc007` — `batch223: add ios quick presets for delete target`
  - `45ee0c5` — `batch223: sync workflow docs after ios delete presets`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **224**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm row-level action `Delete this moment` (one-tap) để giảm 1 bước bấm riêng sau khi đã chọn đúng row.

---

- Batch vừa xong: **222**
- Commit cuối đã chốt:
  - `acda01f` — `batch222: add ios feed row shortcut for moment delete`
  - `1f5a0aa` — `batch222: sync workflow docs after ios delete shortcut`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **223**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm selected-state feedback cho preset delete id (`Delete id selected`) và sync status copy để giảm nhầm lẫn khi retest delete liên tiếp.

---

- Batch vừa xong: **221**
- Commit cuối đã chốt:
  - `129619a` — `batch221: add ios feed row action to fill create author`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **222**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm shortcut `Use row id for delete` trong iOS Feed để fill nhanh `Moment ID` cho flow delete moment từ row context.

---

- Batch vừa xong: **220**
- Commit cuối đã chốt:
  - `13d7a42` — `batch220: show ios pending pair mode in snapshot summary`
  - `71a42b3` — `batch220: sync workflow docs after ios pair mode summary`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **221**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm row-level action `Use author for create` để giảm copy/paste author UUID khi test create moment từ feed row context.

---

- Batch vừa xong: **217**
- Commit cuối đã chốt:
  - `7bbd5cd` — `batch217: preset ios friend request pair from pending row`
- Test-verify cuối:
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp:
  - **218**
- Scope hẹp đầu tiên của batch kế tiếp:
  - tách preset pending request thành 2 mode rõ ràng (`Use same pair` / `Use reverse pair`) để giảm nhầm chiều requester/receiver khi retest.

---

- Batch vừa xong: **54**
- Commit cuối đã chốt:
  - `5ddea98` — `batch54: expose failure cleanup cue`
  - `d26f65c` — `batch54: align ios failure cleanup cue`
  - `bf0583e` — `batch54: preserve auth cleanup cue metadata`
  - `6dd83ce` — `batch54: consume auth cleanup cue metadata`
  - `b53608a` — `batch54: consume ios cleanup cue metadata`
  - `41a269c` — `batch54: mark workflow complete`
  - `9646f1d` — `batch54: sync team dispatch state`
  - `e83f0d2` — `batch54: sync workflow git state`
  - `325b8c7` — `batch54: refresh workflow head`
- Test-verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_auth_api.py` → pass
  - web: `cd apps/web-nextjs && npm run verify` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - batch 54 không còn blocker trực tiếp; override mới từ Vinh yêu cầu tiếp tục autopilot qua seam MVP thật
- Batch kế tiếp:
  - **55**
- Scope hẹp đầu tiên của batch kế tiếp:
  - backend friend-request/friendship listing + web profile friend graph shell đọc contract đó để con người test seam social đầu tiên ngoài auth
