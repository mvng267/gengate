# GenGate — Locked Product & Technical Decisions

## 1. Authentication
Chosen for MVP:
- registration uses email + OTP verification
- after verification, user can optionally set a password
- login supports both OTP and password
- social login is not included in Phase 1

Interpretation:
- email is the primary identity channel
- OTP is the trust/bootstrap mechanism
- password is optional but supported after account setup

## 2. Moments media
Chosen for MVP:
- image
- text/caption
- no video in Phase 1

## 3. Location mode
Chosen for MVP:
- snapshot location only
- not continuous live tracking in Phase 1

## 4. Messaging scope
Chosen for MVP:
- direct message 1-1 only
- no group chat in Phase 1
- DM attachments limited to text + image

## 5. Friendship model
Chosen for MVP:
- two-way friendship required

Interpretation:
- users must become friends before private social visibility rules unlock

## 6. Moment visibility
Chosen for MVP:
- friends only

## 7. Location visibility
Chosen for MVP:
- custom list

Interpretation:
- user chooses exactly which friends can view location state/snapshots

## 8. Reactions
Chosen for MVP:
- one simple reaction only
- recommended symbol: heart

## 9. User identity fields
Chosen for MVP:
- username
- display name
- friend discovery should prioritize username first

## 10. Profile fields in MVP
Chosen for MVP:
- avatar
- display name
- username
- bio

## 11. Notifications
Chosen for Phase 1 / MVP foundation:
- in-app notification center only
- no full push delivery required in the first implementation pass

## 12. Realtime events required early
Chosen:
- new message
- read receipt
- friend request
- new moment
- location can be semi-realtime / snapshot-based first

## 13. Admin / moderation
Chosen:
- placeholder only
- basic user block support exists in MVP

## 14. Media storage
Chosen:
- Cloudflare R2

## 15. API style
Chosen:
- REST + WebSocket

## 16. Python backend stack
Chosen:
- FastAPI
- SQLAlchemy
- Alembic

## 17. Web UI direction
Chosen:
- mobile-first

## 18. Mobile UI stack
Chosen:
- iOS: SwiftUI
- Android: Jetpack Compose

## 19. Repo structure
Chosen:
- one monorepo containing everything

## 20. Implementation order
Chosen:
- backend → web → iOS → Android

## 21. Messaging security requirement
Chosen direction:
- DM 1-1 is end-to-end encrypted by default
- no separate secret mode in MVP
- multi-device sync uses per-device encrypted delivery
- server stores only minimal metadata and encrypted payloads
- content and message keys are not stored as plaintext on server
- key management uses per-device keys + key versioning
- key rotation happens on add-device, security events, and periodic key-version epochs
- recovery uses encrypted key backup protected by a user-created 6-digit passphrase
- user must create, store, and manage the 6-digit passphrase personally
- the system must provide a place to rotate/change the passphrase later

Practical interpretation:
- private direct messages must be designed with end-to-end encryption from the start
- each device owns key material
- message payloads must be encrypted for destination devices
- recovery must not expose plaintext content to the server

## 22. Passphrase UX
Chosen direction:
- users can use the app normally without passphrase at first
- when a user starts encrypted DM for the first time, the app must require passphrase setup
- Settings > Security must include passphrase change/rotation

## 23. Moment retention
Chosen for MVP:
- moments are long-lived by default
- no story-like auto-expiration in MVP

Important note:
- the exact cryptographic protocol is documented separately in `MESSAGE_ENCRYPTION_PROTOCOL.md` and must be respected during implementation
