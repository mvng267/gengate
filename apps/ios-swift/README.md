# GenGate iOS (Swift) — Foundation

Minimal native iOS foundation scaffold for Batch 29.

## What is included
- SwiftUI app entry (`GenGateApp`) and root tab shell.
- Placeholder screens for MVP routes:
  - Login
  - Feed
  - Inbox
  - Location
  - Profile
- Clear folder structure by app/core/features/resources.
- Swift Package manifest (`Package.swift`) so code can be typechecked in environments without full Xcode project generation.

## What is intentionally stubbed
- Auth/session flows and secure token storage.
- API client/data layer integration.
- Realtime messaging/moment updates.
- Camera/media upload flows.
- Location permission + map integration.
- Any production navigation/state architecture beyond root MVP shell.

## Runtime / build note
This environment currently lacks full Xcode toolchain for `xcodebuild` iOS builds:
- `xcodebuild` reports active developer directory is CommandLineTools only.

So this lane delivers a runnable code skeleton foundation, but not a verified iOS simulator build in this runtime.

## Next handoff
- Open `apps/ios-swift` in Xcode and create/bind an iOS app target using these source folders.
- Add Info.plist, signing settings, and real app icon assets.
- Implement domain vertical slices per backend contracts.
