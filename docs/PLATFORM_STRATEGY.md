# GenGate — Platform Strategy

## 1. Current platform scope
Current build priority is limited to:
- Backend Python
- Frontend Next.js
- iOS native Swift
- Android native Kotlin

Desktop platforms are intentionally deferred.

## 2. Strategic decision
The correct approach now is:
- one shared backend platform
- one web app in Next.js
- one native iOS app in Swift
- one native Android app in Kotlin
- one shared source of truth for product contracts, flows, and data model

## 3. Why this strategy
### Backend Python
- good for fast product backend iteration
- rich ecosystem for API, async jobs, media, auth integrations
- FastAPI is a practical default for typed APIs and docs

### Web Next.js
- fast product iteration
- easy QA/demo/admin usage
- useful as the quickest surface to validate feed/profile/messaging flows

### iOS Swift
- native camera, permissions, push, location behavior
- better long-term quality than forcing cross-platform abstraction too early

### Android Kotlin
- native handling for permissions, push, background behavior, media and location
- avoids lowest-common-denominator compromises

## 4. Shared vs platform-specific
### Shared across all apps
- backend contracts
- product docs
- API schemas
- privacy rules
- domain model

### Platform-specific
- UI implementation
- navigation
- camera
- file/media picker
- background location behavior
- push registration

## 5. Rollout order
1. Backend foundation
2. Web shell
3. iOS shell
4. Android shell
5. Auth/profile vertical slice
6. Moments vertical slice
7. Messaging vertical slice
8. Location vertical slice

## 6. Risks
- separate iOS + Android clients increase client implementation cost
- contract drift can happen if backend API discipline is weak
- location and push behavior differ significantly by platform

## 7. Recommendation
- use FastAPI for backend
- keep OpenAPI / typed contract generation clean
- let web move fastest first, but do not let web dictate mobile UX compromises
