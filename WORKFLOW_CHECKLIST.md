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

- Batch workflow chính thức mới nhất trong checklist/status: **đã chốt batch 46**.

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

- Batch workflow chính thức hiện tại: **46**
- Scope hiện tại: batch 46 local clear outcome signal complete — web + iOS parity done.
- Trạng thái hiện tại: **complete**
- File đã đụng:
  - `apps/web-nextjs/app/login/page.tsx`
  - `apps/ios-swift/GenGate/Core/Session/AppSessionStore.swift`
  - `apps/ios-swift/GenGate/Features/Auth/SessionEntryView.swift`
- Test-verify:
  - `cd apps/web-nextjs && npm run verify` → ✅ pass
  - `cd apps/ios-swift && swift build` → ✅ pass
- Git mốc gần nhất:
  - commit code cuối của batch: `1f2ea9a` — `batch46: add ios local clear outcome signal`
  - working tree: sạch trước khi ghi workflow-only closeout marker
- Blocker nếu có:
  - none
- Bước kế tiếp:
  - mở batch 47 với 1 scope hẹp backend: thêm endpoint/detail contract để shell đọc rõ hơn auth/session-clear intent từ backend-facing flow khi verify end-to-end

## Batch handoff note

- Batch vừa xong: **46**
- Commit cuối đã chốt:
  - `b841f1e` — `batch46: add web local clear outcome signal`
  - `1f2ea9a` — `batch46: add ios local clear outcome signal`
- Test-verify cuối:
  - web: `cd apps/web-nextjs && npm run verify` → pass
  - iOS: `cd apps/ios-swift && swift build` → pass
- Blocker/rủi ro còn lại:
  - chưa có blocker code; next leverage là backend-facing detail contract để auth/session actions dễ đối chiếu end-to-end hơn thay vì chỉ nhìn local shell outcomes
- Batch kế tiếp: **47**
- Scope hẹp đầu tiên của batch 47:
  - backend auth/session contract follow-up để surface detail rõ hơn cho shell verify path, không mở rộng sang UI lớn hay refactor ngang
