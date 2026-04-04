# GenGate — Database Schema Detail

## 1. Identity and access
### users
- id
- email (unique)
- username (unique)
- status
- email_verified_at
- password_hash (nullable until user sets password)
- created_at
- updated_at

### profiles
- id
- user_id (unique fk -> users)
- display_name
- bio
- avatar_url
- created_at
- updated_at

### devices
- id
- user_id
- platform
- device_name
- device_trust_state
- push_token (nullable)
- created_at
- last_active_at

### sessions
- id
- user_id
- device_id
- refresh_token_hash
- expires_at
- revoked_at
- created_at

## 2. Friendship domain
### friend_requests
- id
- requester_user_id
- receiver_user_id
- status
- created_at
- responded_at

### friendships
- id
- user_a_id
- user_b_id
- state
- created_at

### blocks
- id
- blocker_user_id
- blocked_user_id
- created_at

## 3. Moments domain
### moments
- id
- author_user_id
- caption_text
- visibility_scope
- location_snapshot_id (nullable)
- created_at
- updated_at
- deleted_at (nullable)

### moment_media
- id
- moment_id
- media_type
- storage_key
- mime_type
- width
- height
- created_at

### moment_reactions
- id
- moment_id
- user_id
- reaction_type
- created_at

## 4. Messaging domain
### conversations
- id
- conversation_type (MVP: direct)
- created_at
- updated_at

### conversation_members
- id
- conversation_id
- user_id
- joined_at
- last_read_message_id (nullable)

### messages
- id
- conversation_id
- sender_user_id
- sender_device_id
- payload_type
- encrypted_payload_blob
- message_key_version
- created_at
- edited_at (nullable)
- deleted_at (nullable)

### message_device_keys
- id
- message_id
- recipient_user_id
- recipient_device_id
- wrapped_message_key_blob
- created_at

### message_attachments
- id
- message_id
- attachment_type
- encrypted_attachment_blob
- storage_key (nullable)
- created_at

## 5. Encryption / recovery domain
### device_keys
- id
- device_id
- public_key
- key_version
- created_at
- revoked_at (nullable)

### user_recovery_material
- id
- user_id
- encrypted_backup_blob
- recovery_hint (nullable)
- passphrase_version
- created_at
- updated_at

## 6. Location domain
### location_shares
- id
- owner_user_id
- is_active
- sharing_mode
- created_at
- updated_at

### location_share_audience
- id
- location_share_id
- allowed_user_id
- created_at

### user_location_snapshots
- id
- owner_user_id
- lat
- lng
- accuracy_meters
- captured_at
- expires_at

## 7. Notifications domain
### notifications
- id
- user_id
- notification_type
- payload_json
- read_at (nullable)
- created_at

## 8. Key schema rules
- `users.email` unique
- `users.username` unique
- friendship unique by unordered user pair
- direct conversation unique by user pair
- block unique by blocker + blocked pair
- message payload stored encrypted
- wrapped message keys stored per recipient device
- password hash nullable until user sets password
- recovery material versioned for passphrase rotation
