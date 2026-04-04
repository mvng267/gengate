# GenGate — Product Requirements Document

## 1. Product summary
GenGate là mạng xã hội riêng tư để người dùng chia sẻ khoảnh khắc gần như tức thời với những người thân thiết. Sản phẩm kết hợp 4 trục chính:
- khoảnh khắc cá nhân (moments)
- nhắn tin riêng (messaging)
- chia sẻ vị trí (location)
- hồ sơ cá nhân (profile)

Mục tiêu là tạo trải nghiệm gần gũi, nhanh, ít ồn ào hơn mạng xã hội công khai, nhưng vẫn có realtime và cảm giác sống động.

## 2. Product goals
### Business goals
- Tạo nền tảng social riêng tư có thể mở rộng dần từ MVP sang sản phẩm consumer hoàn chỉnh.
- Hỗ trợ đa nền tảng từ đầu để không bị khóa vào một thiết bị.
- Có kiến trúc đủ sạch để thêm notification, subscriptions, moderation, analytics sau này.

### User goals
- Đăng nhanh một khoảnh khắc để bạn bè thân xem.
- Nhắn tin trực tiếp ngay từ profile, feed hoặc moment.
- Chia sẻ vị trí khi muốn, tắt ngay khi không muốn.
- Có profile cá nhân gọn, riêng tư, dễ chỉnh sửa.

## 3. Target users
### Primary users
- Người dùng 16–30 tuổi, thích giao tiếp riêng tư với nhóm thân thiết.
- Người dùng chụp ảnh, chia sẻ khoảnh khắc thường xuyên nhưng không muốn đăng công khai.

### Secondary users
- Nhóm bạn nhỏ, couple, gia đình, nhóm close-friends.
- Người dùng cần nhắn tin + chia sẻ vị trí trong cùng một app.

## 4. Core product principles
- Privacy-first: mặc định riêng tư, không public by default.
- Close-circle first: ưu tiên quan hệ gần, không thiên về follower đại trà.
- Realtime by design: chat, moment updates, location state phải phản hồi nhanh.
- Media-first but lightweight: đăng ảnh phải nhanh; video chưa vào Phase 1.
- Cross-platform with shared core: một backend, nhiều client.
- Encrypted DM by default: DM 1-1 là vùng riêng tư mặc định.

## 5. Feature scope
### 5.1 Authentication
- Đăng ký bằng email + OTP verify
- Sau đó user có thể set password
- Login hỗ trợ cả OTP và password
- Session đa thiết bị
- Thiết bị tin cậy
- Refresh token

### 5.2 Profile
- Avatar
- Display name
- Username / handle
- Bio ngắn
- Cài đặt riêng tư cơ bản

### 5.3 Friend graph
- Gửi lời mời kết bạn
- Chấp nhận / từ chối / hủy
- Unfriend
- Block cơ bản
- Phân quyền ai được xem moment / location

### 5.4 Moments
- Đăng ảnh
- Caption/text
- Thời gian đăng
- Tùy chọn kèm location snapshot
- Feed riêng tư của bạn bè
- Một reaction cơ bản
- Xóa / ẩn moment
- Moments lưu lâu dài, không tự hết hạn như story trong MVP

### 5.5 Messaging
- Direct message 1-1 ở MVP
- Text message
- Ảnh đính kèm
- Trạng thái sent/delivered/read
- Danh sách hội thoại
- Mã hóa hai chiều mặc định cho DM 1-1

### 5.6 Location
- Bật / tắt chia sẻ vị trí
- Chọn custom list người được xem
- Hiển thị trạng thái vị trí gần nhất
- Snapshot-based sharing

### 5.7 Notifications
- Notification center trong app

## 6. MVP definition
### MVP must-have
- Auth
- Profile
- Friend request / friendship
- Username-based friend discovery
- Moments feed riêng tư
- Đăng moment với ảnh + caption
- DM 1-1 text + image
- Location sharing state
- In-app notification center
- Basic block support

### MVP nice-to-have
- Reactions nâng cao
- Search user/friend tốt hơn
- Push notification thật

### Out of scope
- Group chat
- Public feed
- Video moments
- Livestream
- Monetization
- Social login phase 1
- Desktop clients
- Recommendation ranking phức tạp

## 7. Non-functional requirements
- Khả năng mở rộng theo domain rõ ràng
- API typed và versionable
- Dễ test local/dev
- Audit log-ready
- Storage tách khỏi app server
- Realtime layer tách khỏi business service nếu cần scale
- Theo dõi thiết bị và session để tăng bảo mật
- Không lưu plaintext DM content như đích cuối

## 8. Success metrics for MVP
- User đăng ký và đăng nhập thành công trên ít nhất web + mobile.
- Người dùng đăng moment và bạn bè thấy trong feed gần realtime.
- DM 1-1 gửi/nhận ổn định với text + image.
- User tạo passphrase thành công khi bắt đầu dùng encrypted DM.
- Location snapshot bật/tắt được và hiển thị cho đúng đối tượng.
- Profile edit lưu và đồng bộ được giữa thiết bị.
