# GenGate Team Dispatch

## Coordinator
- Eyna điều phối nhịp 15 phút/lần.
- Nguồn điều hành chung: `WORKFLOW_STATUS.md` + file này.
- Mục tiêu: chia scope hẹp, không đạp nhau, ưu tiên chốt batch nhanh.

## Active batch
- Batch workflow chính thức hiện tại: 28
- Trục công việc: profiles contract locking

## Worker slices

### pikamen
- Scope đã chốt: upsert create path cho user mới register chưa có profile; commit `ff14b7b`.
- Trạng thái: done.

### pikachu
- Scope đang chốt: display_name max length validation + verify long bio vẫn được persist.
- Trạng thái: verify_then_push.

### pikame
- Scope đã chốt: invalid UUID get-profile 422 contract; commit `d8f79e3`.
- Trạng thái: done.

## Conflict rule
- Mỗi worker chỉ làm scope được giao.
- Không tự mở scope mới nếu coordinator chưa ghi rõ scope tiếp theo.
- Sau khi lane `pikachu` push xong, coordinator phải quyết định ngay: khép batch 28 hay mở scope hẹp kế tiếp.
