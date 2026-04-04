# GenGate — User Stories

## 1. Auth
- As a new user, I want to sign up with email and verify with OTP so that I can create my account securely.
- As a user, I want to optionally set a password after verification so that I can log in faster later.
- As a returning user, I want to log in with either OTP or password so that I have flexible access options.

## 2. Profile
- As a user, I want to set my avatar, display name, username, and bio so that my profile is recognizable.
- As a user, I want others to find me by username so that adding friends is simple.

## 3. Friendship
- As a user, I want to send and receive friend requests so that only mutual connections unlock private features.
- As a user, I want to block someone so that they can no longer interact with me normally.

## 4. Moments
- As a user, I want to post an image with text/caption so that I can share a moment with friends.
- As a user, I want my moments to remain visible over time so that they are not forced into story-style expiration.
- As a user, I want only friends to see my moments so that sharing stays private.
- As a user, I want to react to a friend’s moment with a simple reaction so that interaction stays lightweight.

## 5. Messaging
- As a user, I want to send direct messages to friends so that I can have private conversations.
- As a user, I want DM to support text and image attachments so that conversation is useful but still simple.
- As a user, I want encrypted DMs by default so that my private chats are protected.
- As a user, I want read receipts in direct messages so that I know when my message was seen.

## 6. Secure messaging recovery
- As a user, I want to create a 6-digit recovery passphrase the first time I use encrypted DM so that I can recover encrypted chat access later.
- As a user, I want to change that passphrase in Settings > Security so that I can rotate it when needed.
- As a user, I want my lost device to be revocable so that compromised devices no longer retain future access.

## 7. Location
- As a user, I want to share a location snapshot with selected friends so that I control who can see where I am.
- As a user, I want to stop sharing location at any time so that privacy remains under my control.

## 8. Notifications
- As a user, I want an in-app notification center so that I can catch up on friend requests, new messages, and new moments.

## 9. Platform expectations
- As a web user, I want a mobile-first responsive interface so that the app feels natural on phone-sized screens.
- As an iOS user, I want a native SwiftUI experience for privacy-sensitive flows like camera, messaging, and location.
- As an Android user, I want a native Compose experience for equivalent flows and permissions.
