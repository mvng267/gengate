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

- Batch workflow chính thức mới nhất trong checklist/status: **264 — direct-message shell (web quick session-sender send action) đã complete**.

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

- Batch workflow chính thức hiện tại: **264**
- Scope hiện tại: direct-message shell — thêm quick action web `Use current session user as sender + send`.
- Trạng thái hiện tại: **complete**
- File đã đụng:
  - `apps/web-nextjs/components/direct-message-shell.tsx`
- Test-verify:
  - `cd apps/web-nextjs && npm run -s typecheck` → ✅
- Git mốc gần nhất:
  - commit gần nhất đã chốt: `93a12b5` — `batch264: add session-sender quick send action in web dm shell`
  - working tree hiện tại: bẩn (workflow docs update in progress)
- Blocker nếu có:
  - none
- Bước kế tiếp:
  - mở batch265 với 1 slice hẹp direct-message shell: thêm quick action iOS `Use current session user as User A + send` để parity thao tác gửi nhanh với web.
- MVP-testable run/test path (latest stable):
  - Backend: tạo request qua `POST /friends/requests` -> reject qua `POST /friends/requests/{id}/reject` -> list lại `GET /friends/requests?user_id=<id>` thấy `status: rejected`.
  - Web Feed: bấm quick action `Use current session user as viewer + load` -> verify status `viewer_source=session_user` + feed reload.
  - Web Inbox: nhập user A/B -> `Open direct thread` -> nhập message text -> bấm `Use current session user as sender + send` -> verify status chứa `sender_source=session_user` + message được gửi.
  - iOS Inbox: nhập User A/B -> `Load inbox thread` -> verify quick-copy conversation line `user_a/user_b/message_count/last_message_id`.

## Batch handoff note

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
