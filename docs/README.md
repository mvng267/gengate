# GenGate Docs Index

GenGate là một mạng xã hội riêng tư lấy cảm hứng từ Locket, tập trung vào chia sẻ khoảnh khắc, nhắn tin, vị trí và hồ sơ cá nhân cho nhóm quan hệ gần.

## Bộ tài liệu
- `PRODUCT_REQUIREMENTS.md` — mục tiêu sản phẩm, phạm vi, tính năng, MVP
- `ARCHITECTURE.md` — kiến trúc hệ thống và monorepo
- `PLATFORM_STRATEGY.md` — chiến lược triển khai web/mobile/desktop/iOS/macOS/Windows
- `APP_FLOW.md` — luồng người dùng và hành vi sản phẩm
- `DATA_MODEL.md` — mô hình dữ liệu và quan hệ domain
- `API_CONTRACT.md` — hợp đồng API theo domain
- `ROADMAP.md` — roadmap triển khai theo phase
- `plans/2026-04-03-gengate-social-platform.md` — implementation plan cho coding agent

## Quy tắc triển khai
1. Chốt docs trước khi code business logic sâu.
2. MVP ưu tiên backend + auth + profile + friendships + moments + messaging + location state.
3. Không tách 5 codebase độc lập từ đầu.
4. Web, mobile, desktop phải cùng bám một backend và shared domain model.
5. Ưu tiên privacy-first và realtime.

## Trạng thái hiện tại
- Đã có skeleton monorepo batch 1.
- Tài liệu dưới đây là nguồn sự thật để tiếp tục triển khai.
