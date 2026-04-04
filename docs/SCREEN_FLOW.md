# GenGate — Screen Flow

## 1. Global navigation map
Main surfaces for MVP:
- Auth
- Feed
- Capture / Post Moment
- Inbox
- Conversation Detail
- Location
- Profile
- Settings
- Notifications
- Friend Requests
- Security / Passphrase Setup

## 2. Auth screen flow
### Screens
- Splash / Launch
- Welcome / Entry
- Email input
- OTP verify
- Optional password setup
- Password login
- Profile setup

### Registration flow
1. User opens app
2. App checks session
3. If no valid session -> Welcome
4. User enters email
5. App sends OTP
6. User verifies OTP
7. App creates account/session
8. User sets up profile basics
9. User may optionally set password
10. User lands on Feed

### Login flow
1. User opens login
2. User enters email
3. User chooses one of 2 login paths:
   - OTP login
   - password login
4. If valid, user lands on Feed

## 3. Feed screen flow
### Feed screen contains
- friend moments list
- quick access to capture/post
- friend request / notification entry points
- entry points to Inbox / Location / Profile

### Flow
1. User opens Feed
2. App loads long-lived friend moments
3. User taps a moment to view detail
4. User reacts with a single simple reaction
5. User opens author profile or starts chat if friendship exists
6. User can start capture/post from feed

## 4. Capture / Post Moment flow
### Screens
- Capture source picker
- Camera or media picker
- Caption editor
- Visibility confirm
- Optional location attach
- Submit / success state

### Flow
1. User taps Create Moment
2. Chooses camera or gallery
3. Selects image
4. Adds text/caption
5. Optionally attaches snapshot location
6. Confirms visibility (friends only)
7. Upload completes
8. Feed updates

## 5. Inbox flow
### Screens
- Inbox list
- Conversation detail
- Message composer
- First-time secure messaging setup

### Flow
1. User opens Inbox
2. Sees direct conversations only
3. Taps one conversation
4. If user has not configured recovery passphrase and this is the first encrypted DM usage, app forces passphrase setup
5. User reads messages
6. User sends text or image attachment
7. Read receipt syncs when recipient opens

## 6. First-time encrypted DM flow
### Screens
- Passphrase intro
- Create 6-digit passphrase
- Confirm 6-digit passphrase
- Passphrase saved success

### Flow
1. User tries to enter/send encrypted DM for the first time
2. App blocks message send until passphrase is configured
3. User creates 6-digit passphrase
4. User confirms passphrase
5. App stores encrypted recovery material flow state
6. User continues into conversation

## 7. Start chat flow
User can start DM from:
- friend profile
- friend moment detail
- inbox search/entry

Flow:
1. User selects friend
2. App creates or opens existing direct conversation
3. If first secure DM usage -> passphrase setup required
4. User lands in conversation detail

## 8. Location flow
### Screens
- Location home
- Permission prompt state
- Share settings
- Allowed friends picker
- Current snapshot state

### Flow
1. User opens Location tab
2. App checks permission
3. User grants permission if needed
4. User enables location sharing
5. User selects custom list of allowed friends
6. App uploads snapshot when requested/allowed
7. Authorized friends can view latest visible location state

## 9. Profile flow
### Own profile screens
- Profile summary
- Edit profile
- Privacy/settings
- My moments list

### Friend profile screens
- Friend profile
- Add/remove/block friend actions
- Start chat
- View visible moments

### Flow
1. User opens Profile
2. Sees avatar, display name, username, bio
3. Can edit profile
4. Can manage privacy/settings
5. Can block another user from relevant user/friend profile surfaces

## 10. Friend request flow
### Screens
- Friend requests list
- User profile preview

### Flow
1. User receives friend request notification
2. Opens requests list
3. Accepts or rejects
4. If accepted, friendship is created
5. Feed/profile/message/location rules update accordingly

## 11. Notification flow
### Screens
- Notification center

### Event types in MVP
- friend request received
- friend request accepted
- new moment from friend
- new message

## 12. Settings flow
### Screens
- Account settings
- Security/session management
- Passphrase settings
- Privacy settings
- Location settings
- Block list

### Flow
1. User opens Settings
2. Manages email/password/otp path
3. Reviews active sessions/devices
4. Changes privacy rules
5. Updates location visibility list
6. Views block list
7. Changes/rotates 6-digit recovery passphrase from Security settings

## 13. Platform navigation recommendation
### Web Next.js
- mobile-first shell with bottom navigation for Feed / Inbox / Location / Profile
- modal or dedicated route for Post Moment

### iOS SwiftUI
- TabView with Feed / Inbox / Location / Profile
- modal flow for Capture/Post
- dedicated Security screen under Settings

### Android Compose
- bottom navigation with same domain grouping
- separate compose route for Conversation Detail and Post flow
- dedicated Security screen under Settings
