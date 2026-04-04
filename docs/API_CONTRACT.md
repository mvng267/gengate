# GenGate — API Contract

## 1. Principles
- API theo domain
- Authenticated endpoints tách rõ public/private
- Validation ở backend
- Response shape nhất quán

## 2. Auth
### POST /auth/register
- input: email/phone, password or otp-init payload
- output: pending verification or created account

### POST /auth/verify
- input: otp code
- output: access token, refresh token, user summary

### POST /auth/login
- input: credential payload
- output: access token, refresh token, user summary

### POST /auth/refresh
- input: refresh token / device context
- output: new token pair

### POST /auth/logout
- input: current session
- output: success

## 3. Users / Profiles
### GET /me
- output: current user + profile + settings summary

### PATCH /me/profile
- input: displayName, bio, avatarUrl, privacyLevel
- output: updated profile

### GET /users/:id/profile
- output: filtered profile by viewer permissions

## 4. Friend graph
### POST /friends/requests
- input: target user
- output: pending friend request

### POST /friends/requests/:id/accept
- output: friendship summary

### POST /friends/requests/:id/reject
- output: updated status

### GET /friends
- output: list of friendships

### DELETE /friends/:id
- output: success

## 5. Moments
### POST /moments
- input: caption, visibility, locationSnapshotId?, media[]
- output: created moment

### GET /moments/feed
- output: paginated private feed

### GET /moments/:id
- output: moment detail if permitted

### DELETE /moments/:id
- output: success

### POST /moments/:id/reactions
- input: reactionType
- output: reaction summary

## 6. Conversations / Messages
### GET /conversations
- output: inbox list

### POST /conversations/direct
- input: target user id
- output: direct conversation

### GET /conversations/:id/messages
- output: paginated messages

### POST /conversations/:id/messages
- input: body, attachments[]
- output: created message

### POST /conversations/:id/read
- input: lastReadMessageId
- output: success

## 7. Location
### POST /locations/share-state
- input: isActive, sharingMode
- output: share state

### POST /locations/snapshot
- input: lat, lng, accuracyMeters, capturedAt
- output: stored snapshot

### GET /locations/friends
- output: visible friend location states/snapshots

## 8. Notifications
### GET /notifications
- output: paginated notifications

### POST /notifications/:id/read
- output: success

## 9. Realtime events
### Client subscribe
- `message.created`
- `message.read`
- `moment.created`
- `friend.request.created`
- `location.updated`
- `notification.created`

### Event payload rule
All realtime events should carry:
- `type`
- `entityId`
- `timestamp`
- `actorId` if relevant
- minimal domain payload

## 10. Versioning
- Start with `/v1` prefix optionally behind gateway
- Keep DTOs in shared package
- Avoid breaking response shapes casually
