# GenGate Social App — System Spec

## Product goal
Build a private social app inspired by the core feeling of Locket: quick, personal sharing of moments between close connections, with messaging, location, and personal profile features.

## Current implementation scope
The user has narrowed the build scope for now to only these four surfaces:
- Backend: Python
- Frontend Web: Next.js
- iOS app: Swift
- Android app: Kotlin

Not in the current first implementation scope:
- Windows desktop app
- macOS desktop app
- shared React Native mobile app
- Tauri desktop shell

## Recommended implementation strategy
Do not build every platform at full feature depth at once.
Use one shared product definition and one shared backend platform, then implement clients in this order:
1. Python backend platform
2. Next.js web app
3. Native iOS app in Swift
4. Native Android app in Kotlin

## Recommended stack for the current phase
- Monorepo
- Backend: Python backend service (recommended: FastAPI) + PostgreSQL + Redis + object storage
- Realtime: WebSocket gateway
- Web: Next.js
- Mobile iOS: Swift
- Mobile Android: Kotlin
- Maps/location: provider abstraction layer
- Media: direct upload flow via object storage
- Auth: email OTP or phone OTP, session tokens, device-bound refresh tokens

## Core product domains
### 1. Auth and identity
- create account
- log in
- manage profile
- manage sessions/devices

### 2. Friend graph / close circle
- add friends / accept requests
- control who sees moments and location

### 3. Moments
- capture/upload a moment
- attach caption
- attach optional location
- private friend feed
- reactions

### 4. Messaging
- direct messaging
- text and image attachments
- delivery/read status

### 5. Location
- share current location with permissions
- choose visibility mode
- stop sharing instantly

### 6. Personal profile
- avatar
- display name
- bio
- privacy settings
- recent moments

## MVP scope
Required:
- auth
- user profile
- friend requests
- moment posting with image + caption
- private friend feed
- direct messaging
- optional location sharing state
- notification shell

Out of scope for now:
- group chat
- public feed
- livestream
- recommendation engine
- desktop clients
- advanced moderation AI

## Non-functional requirements
- Clean API boundaries by domain
- Realtime support for message delivery and moment updates
- Privacy-first defaults
- Device-aware auth
- Scalable media upload strategy
- Backend as source of truth for privacy rules

## Monorepo proposal
/apps
  /backend-python      -> FastAPI backend
  /web-nextjs          -> Next.js web app
  /ios-swift           -> native iOS app
  /android-kotlin      -> native Android app
/packages
  /contracts           -> shared API contracts / schemas / docs-generated artifacts
  /design              -> product design tokens / assets / references
  /docs                -> generated or shared references if needed
/docs
  /plans

## Core entities
- User
- Profile
- Session
- Device
- Friendship
- FriendRequest
- Moment
- MomentMedia
- MomentReaction
- Conversation
- ConversationMember
- Message
- MessageAttachment
- LocationShare
- UserLocationSnapshot
- Notification

## API surface (high level)
- /auth/*
- /users/*
- /profiles/*
- /friends/*
- /moments/*
- /messages/*
- /conversations/*
- /locations/*
- /notifications/*

## Delivery strategy
Phase 1:
- backend-python foundation
- web-nextjs foundation
- iOS project foundation
- Android project foundation
- auth/profile/friends/moments/messages/locations schema

Phase 2:
- auth/profile vertical slice
- moments vertical slice
- messaging vertical slice
- location state vertical slice

## Success criteria for first implementation pass
- Python backend starts with health endpoint
- database schema exists for core entities
- Next.js app renders shell routes
- iOS app builds project skeleton and route shell
- Android app builds project skeleton and route shell
- docs are clear enough for continued implementation by OpenCode
