# GenGate — Implementation Checklist

> File này là checklist tiến độ chính để theo dõi triển khai GenGate.
> Quy ước trạng thái:
> - `[ ]` chưa làm
> - `[-]` đang làm
> - `[x]` đã xong

---

## 0. Documentation lock
- [x] Chốt `SYSTEM_SPEC.md`
- [x] Chốt `PRODUCT_REQUIREMENTS.md`
- [x] Chốt `DECISIONS.md`
- [x] Chốt `ARCHITECTURE.md`
- [x] Chốt `PLATFORM_STRATEGY.md`
- [x] Chốt `APP_FLOW.md`
- [x] Chốt `SCREEN_FLOW.md`
- [x] Chốt `DATA_MODEL.md`
- [x] Chốt `DB_SCHEMA_DETAIL.md`
- [x] Chốt `API_CONTRACT.md`
- [x] Chốt `API_EXAMPLES.md`
- [x] Chốt `SECURITY_AND_ENCRYPTION.md`
- [x] Chốt `MESSAGE_ENCRYPTION_PROTOCOL.md`
- [x] Chốt `USER_STORIES.md`
- [x] Chốt `PHASE_1_FOUNDATION.md`
- [x] Chốt `LOCAL_DEVELOPMENT.md`
- [x] Chốt `NON_FUNCTIONAL_REQUIREMENTS.md`
- [x] Chốt `FEATURE_MATRIX.md`
- [x] Tạo `OPENCODE_SYSTEM_PROMPT.md`
- [x] Tạo plan cho OpenCode: `docs/plans/2026-04-03-phase-1-foundation-implementation.md`

## 1. Active workspace / execution prep
- [x] Tạo active workspace `generated/gengate`
- [x] Tạo `AGENTS.md` cho workspace
- [x] Tạo `CLAUDE.md` cho workspace
- [x] Cài skill FastAPI
- [x] Cài skill SwiftUI
- [x] Cài skill Android Kotlin
- [x] Cài skill Jetpack Compose
- [x] Đóng băng hoặc cô lập scaffold cũ
- [x] Chốt rõ folder active cuối cùng để OpenCode chỉ làm trong đó
- [x] Giao batch 1 chính thức cho OpenCode

## 2. Backend Python foundation
- [x] Tạo `apps/backend-python/`
- [x] Tạo `pyproject.toml`
- [x] Tạo app bootstrap FastAPI
- [x] Tạo `app/main.py`
- [x] Tạo `app/core/config.py`
- [x] Tạo `app/core/db.py`
- [x] Tạo `app/core/redis.py`
- [x] Tạo `app/core/storage.py`
- [x] Tạo router gốc
- [x] Tạo `GET /health`
- [ ] Tạo module folders:
  - [x] auth
  - [x] profiles
  - [x] friendships
  - [x] moments
  - [x] messages
  - [x] locations
- [x] Tạo `.env.example`
- [x] Chạy backend local được
- [x] `GET /health` trả OK

## 3. Schema baseline / migrations
- [ ] Tạo SQLAlchemy base models
- [ ] Tạo Alembic config
- [ ] Tạo migration baseline đầu tiên
- [ ] Tạo bảng `users`
- [ ] Tạo bảng `profiles`
- [ ] Tạo bảng `devices`
- [ ] Tạo bảng `sessions`
- [ ] Tạo bảng `friend_requests`
- [ ] Tạo bảng `friendships`
- [ ] Tạo bảng `blocks`
- [ ] Tạo bảng `moments`
- [ ] Tạo bảng `moment_media`
- [ ] Tạo bảng `moment_reactions`
- [ ] Tạo bảng `conversations`
- [ ] Tạo bảng `conversation_members`
- [ ] Tạo bảng `messages`
- [ ] Tạo bảng `message_device_keys`
- [ ] Tạo bảng `message_attachments`
- [ ] Tạo bảng `device_keys`
- [ ] Tạo bảng `user_recovery_material`
- [ ] Tạo bảng `location_shares`
- [ ] Tạo bảng `location_share_audience`
- [ ] Tạo bảng `user_location_snapshots`
- [ ] Tạo bảng `notifications`
- [ ] Chạy migration thành công trên local DB

## 4. API skeleton
- [ ] Tạo route group `/auth`
- [ ] Tạo route group `/profiles`
- [ ] Tạo route group `/friends`
- [ ] Tạo route group `/moments`
- [ ] Tạo route group `/messages`
- [ ] Tạo route group `/locations`
- [ ] Tạo route group `/notifications`
- [ ] Tạo response/request skeleton cơ bản
- [ ] Bám đúng `API_CONTRACT.md`
- [ ] Bám đúng `API_EXAMPLES.md`

## 5. Web Next.js foundation
- [ ] Tạo `apps/web-nextjs/`
- [ ] Bootstrap Next.js app thật
- [ ] Tạo mobile-first layout
- [ ] Tạo route `/login`
- [ ] Tạo route `/feed`
- [ ] Tạo route `/inbox`
- [ ] Tạo route `/location`
- [ ] Tạo route `/profile`
- [ ] Tạo route `/settings`
- [ ] Tạo API client placeholder
- [x] Tạo `.env.example`
- [ ] Chạy web local được

## 6. iOS Swift foundation
- [ ] Tạo `apps/ios-swift/`
- [ ] Tạo Xcode project
- [ ] Tạo SwiftUI app shell
- [ ] Tạo screen Login
- [ ] Tạo screen Feed
- [ ] Tạo screen Inbox
- [ ] Tạo screen Location
- [ ] Tạo screen Profile
- [ ] Tạo screen Settings
- [ ] Tạo screen Security / Passphrase
- [ ] Tạo API service placeholder
- [ ] Project mở/build được ở mức shell

## 7. Android Kotlin foundation
- [ ] Tạo `apps/android-kotlin/`
- [ ] Tạo Android project
- [ ] Tạo Compose app shell
- [ ] Tạo screen Login
- [ ] Tạo screen Feed
- [ ] Tạo screen Inbox
- [ ] Tạo screen Location
- [ ] Tạo screen Profile
- [ ] Tạo screen Settings
- [ ] Tạo screen Security / Passphrase
- [ ] Tạo API service placeholder
- [ ] Project mở/build được ở mức shell

## 8. Local development foundation
- [ ] Tạo `infra/docker-compose.yml`
- [ ] Cấu hình Postgres local
- [ ] Cấu hình Redis local
- [ ] Ghi rõ env variables cần dùng
- [ ] Viết startup steps backend
- [ ] Viết startup steps web
- [ ] Viết startup steps iOS
- [ ] Viết startup steps Android
- [ ] Verify local dev story end-to-end ở mức foundation

## 9. Secure messaging foundation (Phase 1-safe)
- [ ] Chuẩn bị message model cho encrypted payload
- [ ] Chuẩn bị device key model
- [ ] Chuẩn bị recovery material model
- [ ] Chuẩn bị passphrase setup flow ở docs/client shell
- [ ] Không implement crypto production hoàn chỉnh quá sớm
- [ ] Bám đúng `MESSAGE_ENCRYPTION_PROTOCOL.md`

## 10. Review gates before Phase 2
- [ ] Review backend foundation xong
- [ ] Review schema baseline xong
- [ ] Review web shell xong
- [ ] Review iOS shell xong
- [ ] Review Android shell xong
- [ ] Review local dev foundation xong
- [ ] Chỉ sau đó mới sang Auth/Profile vertical slice

## 11. Phase 2 candidates (chưa làm ngay)
- [ ] Auth/Profile vertical slice
- [ ] Friendship vertical slice
- [ ] Moments vertical slice
- [ ] Messaging vertical slice
- [ ] Location vertical slice

---

## Current summary
- Documentation: **done**
- Skills/tooling: **ready**
- Active coding on new stack: **backend-python foundation started**
- Recommended next action: **review backend-python foundation, then move to schema baseline**
