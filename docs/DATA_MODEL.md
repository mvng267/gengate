# GenGate — Data Model

## 1. Core entities

### User
- id
- username
- email / phone
- status
- createdAt
- updatedAt

### Profile
- userId
- displayName
- bio
- avatarUrl
- coverUrl (optional later)
- privacyLevel

### Device
- id
- userId
- platform
- appVersion
- pushToken
- lastActiveAt

### Session
- id
- userId
- deviceId
- refreshTokenHash
- expiresAt
- revokedAt

### FriendRequest
- id
- requesterId
- receiverId
- status
- createdAt

### Friendship
- id
- userAId
- userBId
- state
- createdAt

### Moment
- id
- authorId
- caption
- visibility
- locationSnapshotId (nullable)
- createdAt
- deletedAt

### MomentMedia
- id
- momentId
- mediaType
- storageKey
- width
- height
- durationMs (nullable)

### MomentReaction
- id
- momentId
- userId
- reactionType
- createdAt

### Conversation
- id
- type (MVP: direct only)
- createdAt
- updatedAt

### ConversationMember
- id
- conversationId
- userId
- joinedAt
- lastReadMessageId

### Message
- id
- conversationId
- senderId
- messageType
- body
- createdAt
- editedAt
- deletedAt

### MessageAttachment
- id
- messageId
- mediaType
- storageKey
- metadataJson

### LocationShare
- id
- ownerId
- sharingMode
- isActive
- updatedAt

### UserLocationSnapshot
- id
- ownerId
- lat
- lng
- accuracyMeters
- capturedAt
- expiresAt

### Notification
- id
- userId
- type
- payloadJson
- readAt
- createdAt

## 2. Relationship summary
- User 1-1 Profile
- User 1-N Device
- User 1-N Session
- User N-N User via Friendship
- User 1-N Moment
- Moment 1-N MomentMedia
- Moment 1-N MomentReaction
- Conversation 1-N Message
- Conversation N-N User via ConversationMember
- Message 1-N MessageAttachment
- User 1-N UserLocationSnapshot
- User 1-N Notification

## 3. Key rules
- Friendship phải unique theo cặp user
- Direct conversation unique theo cặp bạn chat trong MVP
- Message read state theo member, không nhét vào message global
- Location snapshot có TTL
- Session gắn với device để revoke chính xác

## 4. Privacy rules to enforce in backend
- Chỉ bạn bè hoặc đúng scope mới xem được moment
- Chỉ người được phép mới xem location
- Blocked user không thấy profile/moment/location tùy rule
- Message access phải check conversation membership
