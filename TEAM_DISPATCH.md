# GenGate Team Dispatch

## Coordinator
- Eyna chịu trách nhiệm điều phối flow và **tự cập nhật** `WORKFLOW_STATUS.md` + file này + `WORKFLOW_CHECKLIST.md` để worker chỉ việc bám theo.
- Dùng **3 coding agent cố định**, mỗi worker 1 lane rõ ràng:
  - backend → `pikamen`
  - web → `pikachu-web`
  - iOS → `pikame-ios`
- Session điều phối cho từng lane phải map theo 3 agent trên; không dùng lại lane cũ `pikachu` / `pikame`.
- Job chỉ có nhiệm vụ **nhắc/đẩy đúng lane theo flow file**, không tự bịa scope ngoài file điều phối.
- Khi chốt xong 1 batch, main agent phải **clear context của chính session lane đó** bằng cách mở nhịp mới chỉ mang handoff ngắn của batch vừa xong, không kéo full history cũ.
- Không dùng cron coordinator lặp dài dòng; chỉ dùng nhắc việc/ngòi nổ ngắn nếu thật sự cần.

## Active batch
- Batch workflow chính thức hiện tại: 329
- Trục công việc: friend graph shell — web+iOS add quick action `Use current session user as receiver + send friend request` for one-tap outbound request flow.
- Trạng thái: batch329_complete_friend_graph_session_receiver_quick_send_web_ios.

## Batch 235 handoff (closed)
- Batch vừa xong: **235**
- Commit đã chốt:
  - `2c4c637` — `batch235: clear stale read cursor when message is deleted`
  - `0bdd965` — `batch235: sync workflow docs after read-cursor cleanup`
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_batch7_conversations_api.py` ✅ (3 passed)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **236**
- Scope hẹp đầu tiên của batch kế tiếp:
  - location sharing state shell: stop-sharing contract parity cho list/state response.

## Batch 236 handoff (closed)
- Batch vừa xong: **236**
- Commit đã chốt:
  - `dae57a8` — `batch236: clear location audience when sharing stops`
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_location_audience_api.py` ✅ (4 passed)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **237**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: unread-only list parity cho minimal notification surface.

## Batch 237 handoff (closed)
- Batch vừa xong: **237**
- Commit đã chốt:
  - `99da484` — `batch237: add unread-only filter for notifications list`
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_notifications_security_api.py -k unread_only` ✅ (1 passed, 10 deselected)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **238**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: unread summary/count parity để client có tổng unread trực tiếp từ backend.

## Batch 329 handoff (closed)
- Batch vừa xong: **329**
- Commit đã chốt:
  - `3dd4fc9` — `batch329: add session-receiver quick-send actions in friend graph shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **330**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment posting shell (web+iOS): thêm quick action `Use current session user as author + create moment + reload feed` để one-tap verify seam post→feed.

## Batch 328 handoff (closed)
- Batch vừa xong: **328**
- Commit đã chốt:
  - `6be60e8` — `batch328: add session-requester auto-load friend graph actions`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **329**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web+iOS): thêm quick action `Use current session user as receiver + send friend request` để one-tap test chiều outbound request từ requester=session user.

## Batch 327 handoff (closed)
- Batch vừa xong: **327**
- Commit đã chốt:
  - `a5a973e` — `batch327: add session-requester quick action in friend graph shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **328**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web+iOS): thêm quick action `Use current session user as requester + load friend graph` để one-tap apply context + reload snapshot.

## Batch 326 handoff (closed)
- Batch vừa xong: **326**
- Commit đã chốt:
  - `c81893d` — `batch326: add snapshot source-line copied status markers on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **327**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web+iOS): thêm quick action `Use current session user as requester` để giảm nhập tay khi tạo friend request.

## Batch 325 handoff (closed)
- Batch vừa xong: **325**
- Commit đã chốt:
  - `09c7ee8` — `batch325: add snapshot source-line quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **326**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm status marker `last_source_state_snapshot_source_line_copied` khi copy source-marker line để QA scan log nhanh.

## Batch 324 handoff (closed)
- Batch vừa xong: **324**
- Commit đã chốt:
  - `927a297` — `batch324: add source markers for last snapshot recopy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **325**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho line `last_source_state_snapshot_source=...` để QA copy marker nguồn snapshot nhanh.

## Batch 323 handoff (closed)
- Batch vừa xong: **323**
- Commit đã chốt:
  - `e9fac07` — `batch323: add last source-state snapshot quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **324**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm source marker `last_source_state_snapshot_source=source_state_snapshot_copy|manual_recopy` để QA phân biệt token mới refresh vs re-copy.

## Batch 322 handoff (closed)
- Batch vừa xong: **322**
- Commit đã chốt:
  - `6f8fcbd` — `batch322: persist last source-state snapshot token on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **323**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho line `last_source_state_snapshot=...` để QA re-copy snapshot token nhanh.

## Batch 321 handoff (closed)
- Batch vừa xong: **321**
- Commit đã chốt:
  - `d8a2309` — `batch321: add source-state snapshot quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **322**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm token `last_source_state_snapshot=...` để lưu payload source-state vừa copy cho QA đối chiếu nhanh.

## Batch 320 handoff (closed)
- Batch vừa xong: **320**
- Commit đã chốt:
  - `f7f16a2` — `batch320: add delete copy audit ready-count source-state on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **321**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho source-state line có `ready_count` để QA copy readiness snapshot đầy đủ bằng 1 click.

## Batch 319 handoff (closed)
- Batch vừa xong: **319**
- Commit đã chốt:
  - `f876528` — `batch319: add first-ready source-line quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **320**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm source-state aggregate `ready_count=<n>/total=<n>` để QA scan nhanh mức readiness trước one-shot copy.

## Batch 318 handoff (closed)
- Batch vừa xong: **318**
- Commit đã chốt:
  - `84ab5b2` — `batch318: add first-ready source marker for delete copy audit on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **319**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho line `delete_copy_audit_first_ready_source=...` để QA copy marker trực tiếp khi report.

## Batch 317 handoff (closed)
- Batch vừa xong: **317**
- Commit đã chốt:
  - `74162dd` — `batch317: add first-ready delete copy audit quick action on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **318**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm status marker `delete_copy_audit_first_ready_source=<source|none>` khi chạy one-shot action để QA thấy rõ source đã auto-pick.

## Batch 316 handoff (closed)
- Batch vừa xong: **316**
- Commit đã chốt:
  - `bbe504c` — `batch316: add delete copy audit source-state line on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **317**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick action `Copy delete copy audit for first ready source` để QA lấy payload audit one-shot nhanh nhất.

## Batch 315 handoff (closed)
- Batch vừa xong: **315**
- Commit đã chốt:
  - `e035bba` — `batch315: add delete copy audit source chips on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **316**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm line `delete_copy_audit_source_state=quick_delete_parity:<ready|missing>/last_delete_result:<ready|missing>/copied_feedback:<ready|missing>` + copy action để QA thấy readiness của từng source trước khi copy.

## Batch 314 handoff (closed)
- Batch vừa xong: **314**
- Commit đã chốt:
  - `bb09591` — `batch314: add delete copy audit quick-copy line on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **315**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm `delete_copy_audit_source` quick filter chips (`quick_delete_parity` / `last_delete_result` / `copied_feedback`) để QA force-generate audit token theo từng source mà không phải nhớ thứ tự click.

## Batch 313 handoff (closed)
- Batch vừa xong: **313**
- Commit đã chốt:
  - `4bccf18` — `batch313: add delete summary copy-source markers on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **314**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): bổ sung quick-copy line `delete_copy_audit=source:.../value:...` để gom audit payload thành 1 token ngắn, tránh parse status dài.

## Batch 312 handoff (closed)
- Batch vừa xong: **312**
- Commit đã chốt:
  - `29edaca` — `batch312: add copied-delete-summary feedback quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **313**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm marker `delete_summary_copy_source=quick_delete_parity|last_delete_result|copied_feedback` vào status copy success để audit nguồn copy action ngay trong log/status.

## Batch 311 handoff (closed)
- Batch vừa xong: **311**
- Commit đã chốt:
  - `ea67e22` — `batch311: add delete snapshot source markers on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **312**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action riêng cho feedback token `Last copied delete summary`/`Copied delete summary` để QA re-copy payload vừa copy mà không cần delete lại.

## Batch 310 handoff (closed)
- Batch vừa xong: **310**
- Commit đã chốt:
  - `079f731` — `batch310: add delete summary quick-copy actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **311**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm `delete_snapshot_source=manual_input|preset_row|first_authored_quick_pick` marker vào quick delete parity summary để trace nguồn delete target rõ hơn.

## Batch 309 handoff (closed)
- Batch vừa xong: **309**
- Commit đã chốt:
  - `2b07ac7` — `batch309: add ios feed delete parity summary markers`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **310**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy action cho `Quick delete parity summary` + `Last delete result summary` để report create->delete tokens nhanh hơn.

## Batch 308 handoff (closed)
- Batch vừa xong: **308**
- Commit đã chốt:
  - `6091c72` — `batch308: add web feed delete moment parity shell`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **309**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell phía iOS: mirror delete-result quick summary marker parity (`delete_result/moment_id/deleted_at/author_loaded_count/feed_match_count`) để report đồng format với web.

## Batch 307 handoff (closed)
- Batch vừa xong: **307**
- Commit đã chốt:
  - `e7d337d` — `batch307: add gate snapshot source markers for feed parity`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **308**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell phía web: thêm delete moment action parity (`DELETE /moments/{id}`) + status summary để verify vòng create->delete ngay trên web.

## Batch 306 handoff (closed)
- Batch vừa xong: **306**
- Commit đã chốt:
  - `09c44f2` — `batch306: add feed visibility reason markers in status and quick copy`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **307**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm create-vs-reload gate parity marker `gate_snapshot_source=create_flow|reload_flow` để human tester đối chiếu nhanh nguồn snapshot trong report.

## Batch 305 handoff (closed)
- Batch vừa xong: **305**
- Commit đã chốt:
  - `2a12d7b` — `batch305: add feed-visibility gate quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **306**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm visibility gate context marker `viewer_access_reason=viewer_missing|empty_or_blocked|granted` vào status/copy payload để chẩn đoán nhanh nguyên nhân gate outcome.

## Batch 304 handoff (closed)
- Batch vừa xong: **304**
- Commit đã chốt:
  - `0ecd3fd` — `batch304: add lifecycle-pair transition markers in notification shell`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **305**
- Scope hẹp đầu tiên của batch kế tiếp:
  - feed shell (web+iOS): thêm quick-copy feed visibility gate summary `viewer_access + visible_count + first_moment_id` ngay sau reload để verify private feed contract nhanh hơn.

## Batch 303 handoff (closed)
- Batch vừa xong: **303**
- Commit đã chốt:
  - `0d74159` — `batch303: add lifecycle-pair subject markers in notification shell`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **304**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm transition marker `lifecycle_pair_transition=create_read_state->mutation_read_state` để đọc outcome nhanh hơn.

## Batch 302 handoff (closed)
- Batch vừa xong: **302**
- Commit đã chốt:
  - `729d3f4` — `batch302: add lifecycle-pair state markers in notification shell`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **303**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm guard marker `lifecycle_pair_subject=same_notification|cross_notification` để tách rõ matched/mismatched root cause.

## Batch 301 handoff (closed)
- Batch vừa xong: **301**
- Commit đã chốt:
  - `0db7546` — `batch301: add notification lifecycle-pair quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **302**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy lifecycle pair status marker `lifecycle_pair_state=matched|mismatched|missing` để report chain outcome rõ hơn.

## Batch 300 handoff (closed)
- Batch vừa xong: **300**
- Commit đã chốt:
  - `47deb98` — `batch300: add notification create-result delta quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **301**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy lifecycle pair line gộp `create_result + mutation_delta` để report liền mạch create->toggle trong 1 payload.

## Batch 299 handoff (closed)
- Batch vừa xong: **299**
- Commit đã chốt:
  - `707c8e2` — `batch299: add notification mutation-delta quick copy on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **300**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy create-result delta `notification_id/read_state/current_page_unread/total_unread_count` ngay sau create để verify lifecycle create->toggle nhanh hơn.

## Batch 298 handoff (closed)
- Batch vừa xong: **298**
- Commit đã chốt:
  - `b4d9981` — `batch298: add notification page-cursor summary copy actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **299**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy mutation delta sau mark read/unread `notification_id/read_state/current_page_unread/total_unread_count` để report toggle outcome nhanh hơn.

## Batch 297 handoff (closed)
- Batch vừa xong: **297**
- Commit đã chốt:
  - `985de64` — `batch297: add quick location state summary copy actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **298**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web+iOS): thêm quick-copy notification page cursor summary `user_id/limit/offset/filter_mode/count/unread_count/total_unread_count` để tăng khả năng test seam #6 theo priority.

## Batch 296 handoff (closed)
- Batch vừa xong: **296**
- Commit đã chốt:
  - `cf07bdc` — `batch296: add feed-visibility delta copy actions after moment create`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **297**
- Scope hẹp đầu tiên của batch kế tiếp:
  - location shell (web+iOS): thêm quick-copy location state summary `owner/share_id/is_active/sharing_mode/audience_count/snapshot_count` để tăng khả năng test seam #5 theo priority.

## Batch 295 handoff (closed)
- Batch vừa xong: **295**
- Commit đã chốt:
  - `4e1b033` — `batch295: add friend-graph quick delta copy actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **296**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment posting shell (web+iOS): thêm quick-copy feed-visibility delta `viewer/feed_count/first_moment_id` ngay sau create để tăng khả năng test seam #2 theo priority.

## Batch 294 handoff (closed)
- Batch vừa xong: **294**
- Commit đã chốt:
  - `63107e8` — `batch294: add web quick page-meta copy action in notification shell`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **295**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend graph shell (web+iOS): thêm quick-copy delta line `accepted_count/pending_inbound/pending_outbound` sau accept/reject để tăng khả năng test social seam theo priority #1.

## Batch 293 handoff (closed)
- Batch vừa xong: **293**
- Commit đã chốt:
  - `18cf958` — `batch293: add ios quick page-meta copy action in notification shell`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **294**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web): thêm quick-copy page meta line (`count/unread_count/total_unread_count/limit/offset/filter_mode`) để parity report đầy đủ web+iOS khi paging/filter.

## Batch 292 handoff (closed)
- Batch vừa xong: **292**
- Commit đã chốt:
  - `70c6749` — `batch292: add web quick unread summary copy action`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **293**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (iOS): thêm quick copy page meta line (`count/unread_count/total_unread_count/limit/offset/filter_mode`) để parity report nhanh khi paging/filter.

## Batch 291 handoff (closed)
- Batch vừa xong: **291**
- Commit đã chốt:
  - `5d9a0a5` — `batch291: add ios quick unread summary copy action`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **292**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web): thêm one-tap copy action cho quick unread summary line (`current_page_unread / total_unread_count`) để parity report đồng bộ với iOS.

## Batch 290 handoff (closed)
- Batch vừa xong: **290**
- Commit đã chốt:
  - `de5a40c` — `batch290: add web quick unread summary line in notification shell`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **291**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (iOS): thêm one-tap copy quick unread summary line (`current_page_unread / total_unread_count`) để report parity nhanh.

## Batch 289 handoff (closed)
- Batch vừa xong: **289**
- Commit đã chốt:
  - `00cbf0d` — `batch289: add ios quick unread summary line in notification shell`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **290**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell (web): thêm quick unread summary line (`current_page_unread / total_unread_count`) để parity scan nhanh với iOS/backend payload.

## Batch 288 handoff (closed)
- Batch vừa xong: **288**
- Commit đã chốt:
  - `1de4e8d` — `batch288: add ios focus-user first-unread preset action`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **289**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: hiển thị quick unread summary line (`current_page_unread / total_unread_count`) trên iOS để parity scan nhanh với web/backend payload.

## Batch 287 handoff (closed)
- Batch vừa xong: **287**
- Commit đã chốt:
  - `6593ba2` — `batch287: add read-cursor triage quick-copy line on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **288**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap preset `apply focus user + first unread candidate` trên iOS parity với web jump action status-copy flow.

## Batch 286 handoff (closed)
- Batch vừa xong: **286**
- Commit đã chốt:
  - `d6bb3a4` — `batch286: add current-member cursor snapshot to apply quick copy`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **287**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap `copy read-cursor triage line` (tokenized previous/applied/current/apply_state) để report parity nhanh hơn trên web+iOS.

## Batch 285 handoff (closed)
- Batch vừa xong: **285**
- Commit đã chốt:
  - `8d61ece` — `batch285: add previous-cursor baseline to read-cursor apply quick copy`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **286**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy token cho current member cursor snapshot (`current_member_cursor`) để đối chiếu trực tiếp với previous/applied trong cùng dòng trên web+iOS.

## Batch 284 handoff (closed)
- Batch vừa xong: **284**
- Commit đã chốt:
  - `3c09772` — `batch284: add read-cursor apply-state markers on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **285**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy note cho last-read baseline (`previous_cursor_message`) để explain tại sao apply_state=noop trên web+iOS.

## Batch 283 handoff (closed)
- Batch vừa xong: **283**
- Commit đã chốt:
  - `0578cae` — `batch283: add first-unread guard quick-copy markers on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **284**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm read-cursor no-op apply marker (`read_cursor_apply_state=noop|updated`) để tách rõ no-op guard và apply result trên web+iOS.

## Batch 282 handoff (closed)
- Batch vừa xong: **282**
- Commit đã chốt:
  - `4eb2db4` — `batch282: add first-unread no-op guard status markers on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **283**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy snapshot marker cho no-op guard (`first_unread_guard_state`) để report parity một dòng trên web+iOS.

## Batch 281 handoff (closed)
- Batch vừa xong: **281**
- Commit đã chốt:
  - `a690ecf` — `batch281: add first-unread jump quick-copy markers on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **282**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm guard/status khi first-unread candidate không đổi (already_at_latest_or_no_unread) để testers đỡ nhầm kết quả no-op trên web+iOS.

## Batch 280 handoff (closed)
- Batch vừa xong: **280**
- Commit đã chốt:
  - `c71f16b` — `batch280: add member first-unread focus auto-mark actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **281**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm status hint/read-state copy marker sau jump-first-unread để giảm ambiguity khi verify multi-user parity trên web+iOS.

## Batch 279 handoff (closed)
- Batch vừa xong: **279**
- Commit đã chốt:
  - `bcaf55f` — `batch279: add member latest-loaded focus auto-mark actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **280**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap action set member focus + first unread candidate rồi auto-mark read trên web+iOS để cover parity jump-first-unread.

## Batch 278 handoff (closed)
- Batch vừa xong: **278**
- Commit đã chốt:
  - `69ed4b4` — `batch278: add member-cursor context-focus auto-mark actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **279**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap auto-mark action dùng latest loaded message cho focus user trên web+iOS để cover case member cursor message trống.

## Batch 277 handoff (closed)
- Batch vừa xong: **277**
- Commit đã chốt:
  - `58eedff` — `batch277: add member-cursor context-focus one-tap actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **278**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action one-tap apply member cursor context+focus rồi trigger read-cursor update ngay trên web+iOS để giảm thêm 1 bước thao tác.

## Batch 276 handoff (closed)
- Batch vừa xong: **276**
- Commit đã chốt:
  - `982018b` — `batch276: add member-cursor context one-tap actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **277**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action one-tap apply member cursor context + focus user đồng thời trên web+iOS để rút ngắn verify read_state.

## Batch 275 handoff (closed)
- Batch vừa xong: **275**
- Commit đã chốt:
  - `c827afa` — `batch275: add member-cursor message-target one-tap actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **276**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap action apply đồng thời member user + member cursor message vào read-cursor target form trên web+iOS.

## Batch 274 handoff (closed)
- Batch vừa xong: **274**
- Commit đã chốt:
  - `514f34e` — `batch274: add member-row one-tap target-focus actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **275**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm one-tap action dùng selected member cursor message làm read-cursor target message trên web+iOS để rút ngắn setup mark-read case.

## Batch 273 handoff (closed)
- Batch vừa xong: **273**
- Commit đã chốt:
  - `e1820a0` — `batch273: add member-row quick read-cursor target actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **274**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action one-tap apply member row cho cả read-cursor target + read focus trên web+iOS để rút ngắn thao tác retest.

## Batch 272 handoff (closed)
- Batch vừa xong: **272**
- Commit đã chốt:
  - `a34edcc` — `batch272: add member-row quick focus-user actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **273**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action set read-cursor target user theo member row chọn sẵn (web+iOS) để mark-read parity nhanh hơn.

## Batch 271 handoff (closed)
- Batch vừa xong: **271**
- Commit đã chốt:
  - `0a0ff0d` — `batch271: add read-cursor apply-result quick-copy summaries on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **272**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action set read focus user từ member row chọn sẵn trên web+iOS để giảm nhập tay khi retest read-state transitions.

## Batch 270 handoff (closed)
- Batch vừa xong: **270**
- Commit đã chốt:
  - `3313396` — `batch270: add session-user read-cursor target and focus quick actions`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **271**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy line chuẩn hóa read-cursor apply result (`target_user + applied_message + focus_user + read_state`) trên web+iOS để report parity sau thao tác mark-read.

## Batch 269 handoff (closed)
- Batch vừa xong: **269**
- Commit đã chốt:
  - `e2c2765` — `batch269: add session-user read-focus quick action on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **270**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action web+iOS đồng bộ apply session user cho cả `Member user UUID` (read-cursor update target) cùng `Read-status focus user` để retest read-cursor parity không cần nhập tay.

## Batch 268 handoff (closed)
- Batch vừa xong: **268**
- Commit đã chốt:
  - `da1c27a` — `batch268: add dm read-cursor quick-copy summaries on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **269**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action web+iOS dùng current session user làm focus user cho read-state summary để giảm nhập tay khi retest.

## Batch 267 handoff (closed)
- Batch vừa xong: **267**
- Commit đã chốt:
  - `2efcf86` — `batch267: add quick copy send-result clipboard actions on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **268**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy read-cursor focus summary (`focus_user + resolved_message + read_state`) trên web+iOS.

## Batch 266 handoff (closed)
- Batch vừa xong: **266**
- Commit đã chốt:
  - `e35e51e` — `batch266: add dm send-result quick-copy summaries on web and ios`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **267**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action copy `Quick copy send result` vào clipboard cho web+iOS.

## Batch 265 handoff (closed)
- Batch vừa xong: **265**
- Commit đã chốt:
  - `36333ac` — `batch265: add session-user quick send action in ios dm shell`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **266**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy send status line chuẩn hóa sender + message_id trên web+iOS.

## Batch 264 handoff (closed)
- Batch vừa xong: **264**
- Commit đã chốt:
  - `93a12b5` — `batch264: add session-sender quick send action in web dm shell`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **265**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action iOS `Use current session user as User A + send` để parity thao tác gửi nhanh với web.

## Batch 263 handoff (closed)
- Batch vừa xong: **263**
- Commit đã chốt:
  - `2e3ab8b` — `batch263: add direct-message quick-copy conversation summaries`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **264**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick action web `Use current session user as sender + send` để parity thao tác nhanh với iOS sender mặc định User A.

## Batch 262 handoff (closed)
- Batch vừa xong: **262**
- Commit đã chốt:
  - `47cb6df` — `batch262: add session-viewer quick load action in web feed shell`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **263**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct-message shell: thêm quick-copy conversation summary (user_a + user_b + message_count + last_message_id) trên web+iOS.

## Batch 261 handoff (closed)
- Batch vừa xong: **261**
- Commit đã chốt:
  - `4c02683` — `batch261: add private-feed quick-copy summaries in moment shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **262**
- Scope hẹp đầu tiên của batch kế tiếp:
  - private-feed shell: thêm quick action `Use current session user as viewer + load` trên web.

## Batch 260 handoff (closed)
- Batch vừa xong: **260**
- Commit đã chốt:
  - `9614a3b` — `batch260: add session-user author quick preset in moment shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **261**
- Scope hẹp đầu tiên của batch kế tiếp:
  - private-feed shell: thêm quick-copy list summary (viewer + feed_count + first_moment_id) trên web+iOS.

## Batch 259 handoff (closed)
- Batch vừa xong: **259**
- Commit đã chốt:
  - `f42dc59` — `batch259: add quick-copy moment payload summaries`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **260**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment-posting shell: thêm quick preset dùng session user làm author + status copy nguồn author.

## Batch 258 handoff (closed)
- Batch vừa xong: **258**
- Commit đã chốt:
  - `16a8ff4` — `batch258: add quick-copy friend graph summary line`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **259**
- Scope hẹp đầu tiên của batch kế tiếp:
  - moment-posting shell: thêm quick-copy payload summary (author + image_url + caption).

## Batch 257 handoff (closed)
- Batch vừa xong: **257**
- Commit đã chốt:
  - `35c63e9` — `batch257: add pending direction breakdown to friend graph load status`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **258**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend-graph shell: thêm quick-copy line chứa user + pending inbound/outbound + accepted count.

## Batch 256 handoff (closed)
- Batch vừa xong: **256**
- Commit đã chốt:
  - `a8ff434` — `batch256: add inbound outbound pending summaries to friend graph shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **257**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend-graph shell: thêm inbound/outbound breakdown vào status text sau load để copy/paste test result nhanh.

## Batch 255 handoff (closed)
- Batch vừa xong: **255**
- Commit đã chốt:
  - `b073147` — `batch255: replace unread_only booleans with mode labels`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **256**
- Scope hẹp đầu tiên của batch kế tiếp:
  - friend-graph shell: thêm pending summary line (`Inbound pending`/`Outbound pending`) trên web+iOS Profile.

## Batch 254 handoff (closed)
- Batch vừa xong: **254**
- Commit đã chốt:
  - `3ac1d12` — `batch254: show current unread filter mode near presets`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **255**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: đổi summary mode hiển thị từ boolean sang nhãn dễ đọc (`All`/`Unread only`).

## Batch 253 handoff (closed)
- Batch vừa xong: **253**
- Commit đã chốt:
  - `f9081ef` — `batch253: show status hint when unread preset is selected`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **254**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm tiny selected-state marker gần preset controls để dễ nhận biết mode hiện tại.

## Batch 252 handoff (closed)
- Batch vừa xong: **252**
- Commit đã chốt:
  - `721661f` — `batch252: add unread filter quick presets in notification shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **253**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm status hint tức thì khi bấm preset (`All`/`Unread only`) trước bước Load.

## Batch 251 handoff (closed)
- Batch vừa xong: **251**
- Commit đã chốt:
  - `a445633` — `batch251: add read-state legend near notification lists`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **252**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm filter quick presets (`All`/`Unread only`) dạng segmented buttons để giảm toggle ambiguity.

## Batch 250 handoff (closed)
- Batch vừa xong: **250**
- Commit đã chốt:
  - `e35cde6` — `batch250: include read-state symbols in toggle status copy`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **251**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm tiny legend line `● read` / `○ unread` gần danh sách row.

## Batch 249 handoff (closed)
- Batch vừa xong: **249**
- Commit đã chốt:
  - `0b196ed` — `batch249: add row read-state symbols near toggle action`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **250**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm status copy sau toggle để nhắc rõ ký hiệu `● read` / `○ unread`.

## Batch 248 handoff (closed)
- Batch vừa xong: **248**
- Commit đã chốt:
  - `dde8939` — `batch248: clarify quick-apply copy when session user unchanged`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **249**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm lightweight row-level read-state symbol gần nút để scan read/unread nhanh hơn khi paging.

## Batch 247 handoff (closed)
- Batch vừa xong: **247**
- Commit đã chốt:
  - `997d2c2` — `batch247: show explicit pending-window hints in notification shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **248**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: normalize copy cho quick apply khi session-user trùng draft hiện tại.

## Batch 246 handoff (closed)
- Batch vừa xong: **246**
- Commit đã chốt:
  - `67a6ea0` — `batch246: quick-apply session user and reset offset on user change`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **247**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm explicit pending-window hint line để tester thấy mismatch ngay cả khi không nhìn thấy nút load.

## Batch 245 handoff (closed)
- Batch vừa xong: **245**
- Commit đã chốt:
  - `2334e34` — `batch245: add load-window change guard in web and ios notification shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **246**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm quick apply current user + auto-reset page offset khi user id đổi.

## Batch 244 handoff (closed)
- Batch vừa xong: **244**
- Commit đã chốt:
  - `79adb18` — `batch244: add quick paging presets to web and ios notification shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **245**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm auto-load guard theo page window change (optional quick reload button copy/state).

## Batch 243 handoff (closed)
- Batch vừa xong: **243**
- Commit đã chốt:
  - `ac02f36` — `batch243: add unread-only filter controls to web and ios notification shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **244**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm preset quick offsets (first/next/prev) trên web/iOS list controls.

## Batch 242 handoff (closed)
- Batch vừa xong: **242**
- Commit đã chốt:
  - `d594ffa` — `batch242: add pagination controls to web and ios notification shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **243**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm `unread_only` toggle trên web/iOS list controls.

## Batch 241 handoff (closed)
- Batch vừa xong: **241**
- Commit đã chốt:
  - `b033484` — `batch241: adopt total unread summary in web and ios notification shells`
- Test/verify cuối:
  - web: `cd apps/web-nextjs && npm run -s typecheck` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **242**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: thêm pagination controls (`limit`/`offset`) trên web/iOS.

## Batch 240 handoff (closed)
- Batch vừa xong: **240**
- Commit đã chốt:
  - `b6fc2e5` — `batch240: add total unread summary for paged notifications`
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_notifications_security_api.py -k "pagination_and_sorting_parity or notifications_list_unread"` ✅ (3 passed, 10 deselected)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **241**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: web/iOS contract adoption cho `total_unread_count`.

## Batch 239 handoff (closed)
- Batch vừa xong: **239**
- Commit đã chốt:
  - `15f5c35` — `batch239: add notification list pagination and stable sorting`
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_notifications_security_api.py -k "pagination_and_sorting_parity or notifications_list_unread"` ✅ (3 passed, 10 deselected)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **240**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: total unread summary parity cho paged list response.

## Batch 238 handoff (closed)
- Batch vừa xong: **238**
- Commit đã chốt:
  - `f2540dc` — `batch238: add unread count to notifications list response`
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_notifications_security_api.py -k "notifications_list_unread"` ✅ (2 passed, 10 deselected)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **239**
- Scope hẹp đầu tiên của batch kế tiếp:
  - notification shell: sorting/pagination parity cho list contract.

## Batch 234 handoff (closed)
- Batch vừa xong: **234**
- Commit đã chốt:
  - `910a899` — `batch234: hide soft-deleted moments from list and feed`
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_moments_api.py` ✅ (4 passed)
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **235**
- Scope hẹp đầu tiên của batch kế tiếp:
  - direct messaging shell: parity check deleted-message visibility path ở list/read backend.

## Batch 233 handoff (closed)
- Batch vừa xong: **233**
- Commit đã chốt:
  - `17ca17b` — `batch233: improve ios moment posting error clarity`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **234**
- Scope hẹp đầu tiên của batch kế tiếp:
  - private friend feed shell: backend lọc bỏ moment đã soft-delete khỏi `/moments` và `/moments/feed` + test hồi quy.

## Batch 232 handoff (closed)
- Batch vừa xong: **232**
- Commit đã chốt:
  - `3738b54` — `batch232: wire friend-request reject flow across backend and ios`
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_friendships_api.py` ✅ (7 passed)
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **233**
- Scope hẹp đầu tiên của batch kế tiếp:
  - lấy 1 friction point của moment posting shell (image + caption) để tăng độ human-testable beyond friend graph.

## Batch 231 handoff (closed)
- Batch vừa xong: **231**
- Commit đã push:
  - `d3a491f` — `batch231: align row lock-state copy with toggle status text`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **232**
- Scope hẹp đầu tiên của batch kế tiếp:
  - lấy 1 friction point ở social seam hiện có (ưu tiên friend graph hoặc moment posting shell) để tăng độ end-to-end testable beyond auth.

## Batch 230 handoff (closed)
- Batch vừa xong: **230**
- Commit đã push:
  - `a53dc6d` — `batch230: add row lock-state badge near delete action`
  - `2f308f0` — `batch230: sync workflow docs after lock-state badge`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **231**
- Scope hẹp đầu tiên của batch kế tiếp:
  - tune lại copy/style badge (`Locked`/`Unlocked`) để đồng bộ ngắn gọn hơn với status copy unlock/re-lock.

## Batch 229 handoff (closed)
- Batch vừa xong: **229**
- Commit đã push:
  - `df805ad` — `batch229: tint row delete readiness hint by lock state`
  - `0cc3a22` — `batch229: sync workflow docs after lock tint hint`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **230**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm lock-state badge ngắn (`Locked`/`Unlocked`) ngay gần row delete CTA để state không bị chìm khi scroll dài.

## Batch 228 handoff (closed)
- Batch vừa xong: **228**
- Commit đã push:
  - `af92ad2` — `batch228: show status when row delete lock toggles`
  - `35ab051` — `batch228: sync workflow docs after row delete lock status hint`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **229**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm emphasis UI nhẹ cho trạng thái unlock/re-lock để tester bắt tín hiệu nhanh hơn khi thao tác liên tiếp.

## Batch 227 handoff (closed)
- Batch vừa xong: **227**
- Commit đã push:
  - `19198e9` — `batch227: add inline hint for row delete unlock path`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **228**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm status hint ngắn khi toggle vừa chuyển sang unlock để tránh tester bấm lại row trước khi nhìn thấy CTA đổi trạng thái.

## Batch 226 handoff (closed)
- Batch vừa xong: **226**
- Commit đã push:
  - `a96ada2` — `batch226: add unlock hint copy for row delete lock`
  - `b1aaadf` — `batch226: sync workflow docs after row delete unlock hint`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **227**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm inline hint ngay vùng row actions để operator thấy rõ cần tắt toggle `Require confirmation for row delete` trước khi row delete.

## Batch 225 handoff (closed)
- Batch vừa xong: **225**
- Commit đã push:
  - `cdb8cb6` — `batch225: gate row delete behind confirmation toggle`
  - `de012f8` — `batch225: sync workflow docs after delete safety toggle`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **226**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm safety copy `Unlock to delete` cho row button khi toggle lock đang bật để operator hiểu lý do disabled ngay tại chỗ.

## Batch 224 handoff (closed)
- Batch vừa xong: **224**
- Commit đã push:
  - `a2dc93f` — `batch224: add ios one-tap delete from feed row`
  - `387e3f5` — `batch224: sync workflow docs after ios one-tap delete`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **225**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm confirm safety toggle cho one-tap row delete để chỉ enable delete khi tester bật xác nhận chủ động.

## Batch 223 handoff (closed)
- Batch vừa xong: **223**
- Commit đã push:
  - `9bfc007` — `batch223: add ios quick presets for delete target`
  - `45ee0c5` — `batch223: sync workflow docs after ios delete presets`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **224**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm row-level action `Delete this moment` one-tap từ row context, hạn chế nhập tay lại khi tester đã chọn đúng row.

## Batch 222 handoff (closed)
- Batch vừa xong: **222**
- Commit đã push:
  - `acda01f` — `batch222: add ios feed row shortcut for moment delete`
  - `1f5a0aa` — `batch222: sync workflow docs after ios delete shortcut`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **223**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm selected-state feedback cho preset delete id + status copy rõ ràng hơn cho delete retest liên tiếp.

## Batch 221 handoff (closed)
- Batch vừa xong: **221**
- Commit đã push:
  - `129619a` — `batch221: add ios feed row action to fill create author`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **222**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm row-level shortcut `Use row id for delete` để fill nhanh `Moment ID` cho delete flow từ context moment row.

## Batch 220 handoff (closed)
- Batch vừa xong: **220**
- Commit đã push:
  - `13d7a42` — `batch220: show ios pending pair mode in snapshot summary`
  - `71a42b3` — `batch220: sync workflow docs after ios pair mode summary`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **221**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm row-level action `Use author for create` trên Feed moment row để giảm copy/paste author UUID khi test create flow.

## Batch 219 handoff (closed)
- Batch vừa xong: **219**
- Commit đã push:
  - `e01f7ea` — `batch219: show selected state for ios pending pair presets`
  - `dad9ec4` — `batch219: sync workflow docs for ios preset selection feedback`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **220**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm mode marker vào status summary (`pending pair mode: same|reverse`) để tester thấy mode active mà không cần đọc từng nút.

## Batch 218 handoff (closed)
- Batch vừa xong: **218**
- Commit đã push:
  - `ef9152c` — `batch218: add ios pending request pair preset modes`
  - `727715a` — `batch218: sync workflow docs after ios preset mode slice`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **219**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm selected-state feedback (`Using same pair` / `Using reverse pair`) để operator nhìn phát biết mode đang active.

## Batch 217 handoff (closed)
- Batch vừa xong: **217**
- Commit đã push:
  - `7bbd5cd` — `batch217: preset ios friend request pair from pending row`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **218**
- Scope hẹp đầu tiên của batch kế tiếp:
  - tách preset pending request thành 2 mode `Use same pair` / `Use reverse pair` để thao tác đúng chiều nhanh hơn.

## Batch 216 handoff (closed)
- Batch vừa xong: **216**
- Commit đã push:
  - `90d0dc0` — `batch216: add ios friend request swap quick action`
  - `42e42d5` — `batch216: guard ios self friend request draft`
  - `b46705d` — `batch216: keep receiver id for dedupe retest`
- Test/verify cuối:
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - none
- Batch kế tiếp: **217**
- Scope hẹp đầu tiên của batch kế tiếp:
  - thêm nút preset requester/receiver từ một pending request row để test accept/retry flow nhanh hơn trong Profile tab.

## Batch 54 handoff (closed)
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
- Test/verify cuối:
  - backend: `cd apps/backend-python && ./.venv/bin/pytest -q tests/test_auth_api.py` ✅
  - web: `cd apps/web-nextjs && npm run verify` ✅
  - iOS: `cd apps/ios-swift && swift build` ✅
- Blocker/rủi ro còn lại:
  - không còn blocker trực tiếp trong seam batch 54
  - chưa có batch 55 chính thức vì chưa xác nhận được seam end-to-end auth/session mới thực sự còn thiếu
- Batch kế tiếp: **55**
- Scope hẹp đầu tiên của batch kế tiếp:
  - backend friend-request/friendship listing + web profile friend graph shell đọc contract đó; giữ slice hẹp, chưa nhảy sang moments/feed/inbox

## Worker slices

### pikamen — backend
- Scope hiện tại: đã chốt batch 235 direct messaging backend slice cho stale read-cursor cleanup.
- Kết quả gần nhất: delete message sẽ clear `last_read_message_id` references + regression test pass.
- Trạng thái: batch235_complete_direct_read_cursor_deleted_message_parity_backend.

### pikachu-web — frontend web
- Scope hiện tại: tạm dừng theo chỉ đạo user.
- Kết quả gần nhất: batch 84 web direct-message attachment hardening đã xong.
- Trạng thái: paused_by_directive.

### pikame-ios — iOS
- Scope hiện tại: đã chốt batch 233 moment posting UX trên Feed shell.
- Kết quả gần nhất: đã thêm error-code parsing + hint mapping cho create moment/media fail path.
- Trạng thái: batch233_complete_moment_posting_error_clarity_ios.

## Conflict rule
- Backend chỉ đụng `apps/backend-python/**`.
- Frontend chỉ đụng `apps/web-nextjs/**` và config liên quan web.
- iOS chỉ đụng `apps/ios-swift/**` và config liên quan iOS.
- Không worker nào được sửa `WORKFLOW_CHECKLIST.md` trừ main/coordinator.
- Nếu cần sửa root docs/config chung, phải ghi rõ trong báo cáo để coordinator kiểm tra conflict.
