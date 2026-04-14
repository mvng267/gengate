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
- Batch workflow chính thức hiện tại: 218
- Trục công việc: iOS profile friend graph UX hardening — split pending-request preset into same/reverse pair modes.

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
- Scope hiện tại: ổn định sau batch 214 dedupe guard.
- Kết quả gần nhất: duplicate friend-request đã bị chặn nhất quán với mã lỗi domain rõ ràng.
- Trạng thái: stable_after_batch214_backend.

### pikachu-web — frontend web
- Scope hiện tại: tạm dừng theo chỉ đạo user.
- Kết quả gần nhất: batch 84 web direct-message attachment hardening đã xong.
- Trạng thái: paused_by_directive.

### pikame-ios — iOS
- Scope hiện tại: batch 218 iOS profile friend graph UX hardening.
- Kết quả gần nhất: batch 218 thêm 2 preset mode (`Use same pair` / `Use reverse pair`) trên pending request row.
- Trạng thái: verify_batch218_ios.

## Conflict rule
- Backend chỉ đụng `apps/backend-python/**`.
- Frontend chỉ đụng `apps/web-nextjs/**` và config liên quan web.
- iOS chỉ đụng `apps/ios-swift/**` và config liên quan iOS.
- Không worker nào được sửa `WORKFLOW_CHECKLIST.md` trừ main/coordinator.
- Nếu cần sửa root docs/config chung, phải ghi rõ trong báo cáo để coordinator kiểm tra conflict.
