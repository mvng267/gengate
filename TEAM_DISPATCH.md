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
- Batch workflow chính thức hiện tại: 235
- Trục công việc: direct messaging shell — backend clear stale read-cursor khi message đã soft-delete.
- Trạng thái: batch235_complete_direct_read_cursor_deleted_message_parity.

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
