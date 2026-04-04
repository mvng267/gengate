# GenGate — Feature Matrix

## Legend
- ✅ = included / expected in MVP or current plan
- 🟡 = partial / shell only / later in implementation order
- ❌ = not in current scope

| Feature | Backend | Web | iOS | Android | Notes |
|---|---|---|---|---|---|
| Email signup | ✅ | ✅ | ✅ | ✅ | Email-first identity |
| OTP verification | ✅ | ✅ | ✅ | ✅ | Required in signup/login path |
| Password login | ✅ | ✅ | ✅ | ✅ | Optional after OTP-based account setup |
| Social login | ❌ | ❌ | ❌ | ❌ | Out of Phase 1 |
| Profile edit | ✅ | ✅ | ✅ | ✅ | Avatar, display name, username, bio |
| Username discovery | ✅ | ✅ | ✅ | ✅ | Primary friend discovery path |
| Friend request | ✅ | ✅ | ✅ | ✅ | Two-way friendship model |
| Block user | ✅ | ✅ | ✅ | ✅ | Basic block support |
| Moment post (image + text) | ✅ | ✅ | ✅ | ✅ | No video in MVP |
| Moment feed | ✅ | ✅ | ✅ | ✅ | Friends-only visibility |
| Moment reaction (single) | ✅ | ✅ | ✅ | ✅ | Simple heart-style reaction |
| Long-lived moments | ✅ | ✅ | ✅ | ✅ | No story expiry in MVP |
| DM 1-1 | ✅ | ✅ | ✅ | ✅ | No group chat |
| DM image attachment | ✅ | ✅ | ✅ | ✅ | Text + image only |
| DM E2EE | ✅ | ✅ | ✅ | ✅ | Default for 1-1 DM |
| Passphrase setup | ✅ | ✅ | ✅ | ✅ | Required on first encrypted DM usage |
| Passphrase rotation | ✅ | ✅ | ✅ | ✅ | Settings > Security |
| Multi-device encrypted delivery | ✅ | ✅ | ✅ | ✅ | Per-device key wrapping |
| Notification center | ✅ | ✅ | ✅ | ✅ | In-app only |
| Push notification | 🟡 | ❌ | 🟡 | 🟡 | Later; not required for first foundation pass |
| Location snapshot sharing | ✅ | ✅ | ✅ | ✅ | Snapshot, not continuous live tracking |
| Custom location audience | ✅ | ✅ | ✅ | ✅ | User-selected friend list |
| Realtime new message | ✅ | ✅ | ✅ | ✅ | WebSocket-driven |
| Realtime read receipt | ✅ | ✅ | ✅ | ✅ | WebSocket-driven |
| Realtime friend request | ✅ | ✅ | ✅ | ✅ | WebSocket-driven |
| Realtime new moment | ✅ | ✅ | ✅ | ✅ | WebSocket-driven or event invalidation |
| Desktop app | ❌ | ❌ | ❌ | ❌ | Out of current scope |
| Group chat | ❌ | ❌ | ❌ | ❌ | Out of MVP |
| Video moments | ❌ | ❌ | ❌ | ❌ | Out of MVP |
| Story expiry | ❌ | ❌ | ❌ | ❌ | Out of MVP |
| Advanced moderation admin | 🟡 | 🟡 | ❌ | ❌ | Placeholder only |

## Phase 1 implementation expectation
In the first real coding phase:
- Backend: real foundations and schema
- Web: real Next.js shell
- iOS: native SwiftUI shell
- Android: native Compose shell

Business-complete feature behavior is not required in the first foundation pass.
