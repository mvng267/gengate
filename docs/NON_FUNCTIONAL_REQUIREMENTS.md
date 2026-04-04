# GenGate — Non-Functional Requirements

## 1. Privacy
- Private social graph must be enforced on backend.
- Moment visibility must honor friendship state.
- Location visibility must honor custom audience list.
- DM content must not rely on plaintext server storage as the intended final design.

## 2. Security
- All client-server traffic uses HTTPS / WSS.
- Sessions are device-aware.
- Passwords are hashed securely.
- Encrypted DM architecture must support per-device keys and recovery backup.
- Sensitive actions should be auditable.

## 3. Reliability
- Backend should tolerate reconnect/retry behavior for realtime clients.
- New messages and read receipts should sync predictably after reconnect.
- Location snapshot failures should fail safely rather than expose stale incorrect visibility.

## 4. Performance
- Feed loading should be paginated.
- Inbox lists should be query-efficient.
- Media uploads should use direct-to-object-storage flow where practical.
- API responses should avoid oversized payloads.

## 5. Scalability
- Backend modules should be separable by domain.
- Redis should support cache/pubsub/realtime helpers.
- Object storage should scale independently from API servers.
- Websocket/realtime infrastructure should be isolatable later if traffic grows.

## 6. Maintainability
- One monorepo remains the source of truth.
- API contracts and product docs must stay aligned.
- Platform-specific clients must not invent backend behavior.
- Schema changes must go through migration discipline.

## 7. Observability
- Health endpoint required.
- Structured logging recommended.
- Error events should be diagnosable by domain.
- Realtime failures and auth failures should be traceable.

## 8. Product consistency
- Web, iOS, and Android must implement the same domain rules.
- Differences in UI are acceptable; differences in business rules are not.
- First-time encrypted DM passphrase flow must be consistent across clients.

## 9. Recovery / supportability
- Users must be able to revoke lost devices.
- Recovery passphrase change must be supported in Settings > Security.
- If secure history cannot be recovered without passphrase, the product must say so clearly.
