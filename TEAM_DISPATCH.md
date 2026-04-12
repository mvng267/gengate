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
- Batch workflow chính thức hiện tại: 30
- Trục công việc: 3-lane song song quanh auth/login vertical slice đầu tiên.

## Batch 29 handoff (closed)
- Batch vừa xong: **29**
- Commit cuối đã push:
  - backend: `e1e4026` — `test(profiles): lock bio null preserve omitted display/avatar`
  - web: `b3700f5` — `bootstrap web-nextjs foundation shell`
  - iOS: `37a4e87` — `batch29 ios: bootstrap swift foundation skeleton`
- Test/verify cuối:
  - backend focused: `./.venv/bin/pytest -q tests/test_profiles_api.py -k "updates_bio_to_null_and_preserves_omitted_display_name_and_avatar_url"` ✅ (2 passed)
  - backend full file: `./.venv/bin/pytest -q tests/test_profiles_api.py` ✅ (47 passed)
  - web: `cd apps/web-nextjs && npm run verify` ✅
- Blocker/rủi ro còn lại:
  - chưa có blocker code rõ ràng; iOS mới ở mức foundation skeleton, chưa có verify/runtime note tương đương web/backend
- Batch kế tiếp: **30**
- Scope hẹp đầu tiên của batch 30:
  - scaffold backend auth/session shell trong `apps/backend-python` để tạo trục tích hợp đầu tiên cho web/iOS foundation

## Worker slices

### pikamen — backend
- Scope hiện tại: batch 30 auth/session shell backend đã verify xanh.
- Kết quả hiện tại: `/auth/login` + schema/service wiring + test hẹp đã có trong repo.
- Trạng thái: pushed_batch30.

### pikachu-web — frontend web
- Scope hiện tại: batch 30 login/auth shell web đã verify xanh.
- Kết quả hiện tại: login page shell thật + auth client/env stub đã có trong repo.
- Trạng thái: pushed_batch30.

### pikame-ios — iOS
- Scope hiện tại: batch 30 login/session placeholder flow iOS đã verify xanh.
- Kết quả hiện tại: `AppSessionStore`, `SessionEntryView`, auth-gated root tabs, app root update + SwiftPM resource fix đã có trong repo.
- Trạng thái: pushed_batch30.

## Conflict rule
- Backend chỉ đụng `apps/backend-python/**`.
- Frontend chỉ đụng `apps/web-nextjs/**` và config liên quan web.
- iOS chỉ đụng `apps/ios-swift/**` và config liên quan iOS.
- Không worker nào được sửa `WORKFLOW_CHECKLIST.md` trừ main/coordinator.
- Nếu cần sửa root docs/config chung, phải ghi rõ trong báo cáo để coordinator kiểm tra conflict.
