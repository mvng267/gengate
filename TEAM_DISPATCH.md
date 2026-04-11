# GenGate Team Dispatch

## Coordinator
- Eyna điều phối nhịp 15 phút/lần.
- Nguồn điều hành chung: `WORKFLOW_STATUS.md` + file này.
- Mục tiêu: chia scope hẹp, không đạp nhau, ưu tiên chốt batch nhanh.

## Active batch
- Batch workflow chính thức hiện tại: 29
- Trục công việc: profiles contract locking, one-lane nhanh để giữ mốc sạch sau khi batch 28 đã chốt.

## Worker slices

### pikamen
- Vai trò: coding owner cho scope chính.
- Scope mới batch 29: khóa contract khi `/profiles` nhận `avatar_url: null` để clear avatar nhưng vẫn preserve `display_name` + `bio` nếu hai field đó bị omit.
- Trạng thái hiện tại: dispatch_now.

### pikachu
- Trạng thái: idle.

### pikame
- Trạng thái: idle.

## Conflict rule
- Batch 29 mở bằng một scope hẹp, một worker duy nhất để giữ nhịp nhanh và mốc batch rõ.
- Chỉ mở lại multi-lane nếu scope mới tách file đủ sạch.
