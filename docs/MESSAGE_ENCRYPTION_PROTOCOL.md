# GenGate — Message Encryption Protocol (Product-Level Design)

## 1. Goal
Define the product-level secure messaging rules for GenGate direct messages so implementation teams and coding agents do not invent inconsistent security behavior.

## 2. Scope
This document applies only to:
- DM 1-1 conversations
- encrypted message content
- encrypted attachment metadata/payload references where applicable
- device trust, key rotation, and recovery behavior

Not in scope:
- group chat encryption
- desktop clients
- public content encryption

## 3. Locked decisions
- DM 1-1 is end-to-end encrypted by default
- there is no separate secret mode in MVP
- multi-device delivery follows a per-device encrypted delivery model
- server stores encrypted payloads and minimal metadata only
- content and message keys are never stored as plaintext on server
- users can back up encrypted key material using a self-created 6-digit recovery passphrase
- users must have a place to change/rotate this passphrase later

## 4. Threat model target
The system should protect users against:
- routine server-side plaintext exposure
- accidental operator access to message content
- compromised old devices after revoke
- passive interception without valid session/device trust

This document does not claim resistance against every advanced nation-state-level attack in MVP.

## 5. Core model
### 5.1 Device-centric encryption
Each device has:
- a stable `device_id`
- device trust state
- a device key pair
- a relation to one user account and one or more active sessions

### 5.2 Message sending model
When user A sends a message to user B:
1. client creates message payload
2. payload is encrypted client-side
3. a message key is wrapped for each trusted recipient device
4. encrypted envelope is sent to backend
5. backend stores metadata + encrypted payload + wrapped keys per destination device
6. recipient devices decrypt locally

### 5.3 Server-visible metadata
Server may store and process:
- message id
- conversation id
- sender user id
- recipient user id(s)
- sender device id
- recipient device ids
- timestamps
- message status fields
- attachment type hints if required for delivery UX
- encrypted payload blob
- encrypted wrapped keys

Server should not store as plaintext:
- message body
- message key
- decrypted attachments
- decrypted secure payload content

## 6. Multi-device sync
### Decision
Use per-device encrypted delivery.

### Meaning
If a user owns multiple trusted devices, each device receives its own decryptable copy of the message envelope via wrapped key material.

### Benefits
- supports iPhone + Android tablet style usage
- avoids forcing one single “main device” model
- supports revoke and trust changes at device granularity

## 7. Key rotation
### Rotation triggers
Rotate or version keys when:
1. a new device is added
2. a device is revoked or suspected compromised
3. a major security event occurs
4. periodic key-version epoch changes happen
5. the user changes recovery/passphrase settings if protocol requires rewrapping

### Design direction
- keep per-device keys
- track key versions
- future messages use latest valid key version
- old compromised devices lose access after revoke and forward re-keying

## 8. Recovery model
### Locked decision
Recovery uses encrypted backup of key material protected by a user-created 6-digit passphrase.

### Product rules
- user creates the 6-digit passphrase deliberately
- app warns user to store it safely
- app provides a dedicated place to rotate/change the passphrase
- if a device is lost, user can:
  1. recover account via email auth flow
  2. revoke lost device
  3. restore encrypted key material using recovery passphrase on a new trusted device
  4. resume access if recovery succeeds

### UX warning
If the user loses all trusted devices and also loses the recovery passphrase, secure message history may become unrecoverable.

## 9. Passphrase rules
Recommended product rules for the 6-digit passphrase:
- exactly 6 digits
- user-created, not random forced by system
- must be confirmed twice when set
- can be changed from security settings
- changing it should trigger secure rewrap of encrypted backup material
- failed attempts should be rate-limited

## 10. Backend implementation constraints
OpenCode or any coding agent must follow these constraints:
- do not implement plaintext DM persistence as the intended final model
- structure message tables for encrypted payloads and wrapped keys
- structure device/session tables for trust and recovery support
- do not invent ad-hoc crypto shortcuts without documenting them

## 11. MVP engineering split
### Phase 1 foundation
- message data model prepared for encrypted payloads
- device model prepared for key ownership
- recovery passphrase screens/settings documented
- no full production crypto rollout required yet

### Phase 2 secure messaging implementation
- implement device keys
- implement envelope format
- implement wrapped per-device keys
- implement recovery backup and restore flow
- implement revoke/re-key behavior

## 12. Open questions still acceptable
The following may stay open short-term as long as the above locked decisions remain fixed:
- exact crypto primitives/library choice
- exact envelope serialization format
- exact attachment encryption packaging
- exact read-receipt encryption semantics

## 13. Non-negotiable rule
OpenCode must not downgrade the above secure messaging requirements for convenience unless the product docs are explicitly changed.
