# GenGate — API Examples

## 1. Auth
### POST /auth/register
Request:
```json
{
  "email": "user@example.com"
}
```

Response:
```json
{
  "status": "otp_sent",
  "email": "user@example.com"
}
```

### POST /auth/verify
Request:
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

Response:
```json
{
  "accessToken": "<token>",
  "refreshToken": "<token>",
  "user": {
    "id": "usr_123",
    "email": "user@example.com",
    "username": null,
    "displayName": null
  }
}
```

### POST /auth/set-password
Request:
```json
{
  "password": "strong-password"
}
```

Response:
```json
{
  "status": "password_set"
}
```

### POST /auth/login/password
Request:
```json
{
  "email": "user@example.com",
  "password": "strong-password"
}
```

### POST /auth/login/otp
Request:
```json
{
  "email": "user@example.com"
}
```

## 2. Profile
### PATCH /me/profile
Request:
```json
{
  "displayName": "Vinh",
  "username": "mvngbb",
  "bio": "Private social life"
}
```

Response:
```json
{
  "id": "usr_123",
  "profile": {
    "displayName": "Vinh",
    "username": "mvngbb",
    "bio": "Private social life",
    "avatarUrl": null
  }
}
```

## 3. Friend requests
### POST /friends/requests
Request:
```json
{
  "username": "friendname"
}
```

Response:
```json
{
  "requestId": "fr_123",
  "status": "pending"
}
```

### POST /friends/requests/:id/accept
Response:
```json
{
  "friendshipId": "fs_123",
  "status": "accepted"
}
```

## 4. Moments
### POST /moments
Request:
```json
{
  "captionText": "Đi cà phê nè",
  "visibility": "friends",
  "locationSnapshotId": "loc_123",
  "media": [
    {
      "storageKey": "moments/2026/04/03/abc.jpg",
      "mimeType": "image/jpeg"
    }
  ]
}
```

Response:
```json
{
  "id": "mom_123",
  "status": "created"
}
```

### GET /moments/feed
Response:
```json
{
  "items": [
    {
      "id": "mom_123",
      "author": {
        "username": "friendname",
        "displayName": "Friend"
      },
      "captionText": "Đi cà phê nè",
      "reactionCount": 1,
      "createdAt": "2026-04-03T08:00:00Z"
    }
  ],
  "nextCursor": null
}
```

## 5. Messaging
### POST /conversations/direct
Request:
```json
{
  "targetUserId": "usr_friend"
}
```

Response:
```json
{
  "conversationId": "conv_123"
}
```

### POST /conversations/:id/messages
Request:
```json
{
  "payloadType": "text",
  "encryptedPayloadBlob": "<ciphertext>",
  "messageKeyVersion": 1,
  "attachments": []
}
```

Response:
```json
{
  "messageId": "msg_123",
  "status": "sent"
}
```

### POST /security/passphrase/setup
Request:
```json
{
  "encryptedBackupBlob": "<encrypted-backup>",
  "passphraseVersion": 1
}
```

Response:
```json
{
  "status": "configured"
}
```

## 6. Location
### POST /locations/share-state
Request:
```json
{
  "isActive": true,
  "sharingMode": "custom_list",
  "allowedUserIds": ["usr_friend_1", "usr_friend_2"]
}
```

### POST /locations/snapshot
Request:
```json
{
  "lat": 10.762622,
  "lng": 106.660172,
  "accuracyMeters": 25,
  "capturedAt": "2026-04-03T08:10:00Z"
}
```

## 7. Realtime event example
### message.created
```json
{
  "type": "message.created",
  "entityId": "msg_123",
  "conversationId": "conv_123",
  "actorId": "usr_123",
  "timestamp": "2026-04-03T08:12:00Z"
}
```
