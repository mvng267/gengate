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
- Batch workflow chính thức hiện tại: 109
- Trục công việc: iOS inbox seam hardening — add inline cursor ordering + unread-behind hints để đọc trạng thái nhanh hơn.

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
- Scope hiện tại: giữ ổn định backend read-cursor contract vừa chốt ở batch 101.
- Kết quả gần nhất: `PATCH /conversations/{conversation_id}/members/{user_id}/read-cursor` + contract tests pass.
- Trạng thái: stable_after_batch101.

### pikachu-web — frontend web
- Scope hiện tại: tạm dừng theo chỉ đạo user.
- Kết quả gần nhất: batch 84 web direct-message attachment hardening đã xong.
- Trạng thái: paused_by_directive.

### pikame-ios — iOS
- Scope hiện tại: batch 109 iOS inbox read-status UX hardening.
- Kết quả gần nhất: Member summary hiển thị `cursor_order_hint` + `unread_behind_cursor` cho từng user để phát hiện cursor lag nhanh hơn.
- Trạng thái: verify_batch109_ios.

## Conflict rule
- Backend chỉ đụng `apps/backend-python/**`.
- Frontend chỉ đụng `apps/web-nextjs/**` và config liên quan web.
- iOS chỉ đụng `apps/ios-swift/**` và config liên quan iOS.
- Không worker nào được sửa `WORKFLOW_CHECKLIST.md` trừ main/coordinator.
- Nếu cần sửa root docs/config chung, phải ghi rõ trong báo cáo để coordinator kiểm tra conflict.
