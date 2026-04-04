# GenGate — App Flow

## 1. Core navigation
Primary tabs/views:
- Feed
- Inbox
- Map / Location
- Profile
- Settings

## 2. Onboarding flow
1. Open app
2. Sign up / log in
3. Verify OTP
4. Create profile basics
5. Find or add friends
6. Optional: enable notifications
7. Optional: enable location sharing
8. Land on feed

## 3. Post a moment
1. User opens capture flow
2. Chooses camera or library
3. Adds caption
4. Optional: attach location
5. Chooses visibility scope
6. Uploads
7. Feed and relevant friends update

## 4. Messaging flow
1. User opens inbox or profile of a friend
2. Opens conversation
3. Sends message text or image
4. Realtime event updates receiver
5. Delivery/read states sync

## 5. Location flow
1. User opens location tab
2. Chooses sharing mode
3. Grants permission if needed
4. App sends location snapshot or live-sharing state
5. Authorized friends view latest state
6. User can pause or revoke immediately

## 6. Profile flow
1. User opens own profile
2. Sees avatar, bio, stats, recent moments
3. Edits profile fields
4. Changes privacy or account settings

## 7. Friend flow
1. Search or invite user
2. Send request
3. Receiver accepts/rejects
4. Friendship created
5. Moment/profile/location visibility updated by rules

## 8. Notification flow
- New friend request
- New message
- New moment from close friends
- Location share changes

## 9. Error/edge cases
- media upload fail
- location permission denied
- user blocked
- friendship revoked
- session expired
- weak connectivity and message retry
