# GenGate — Security and Encryption Notes

## 1. Security goals
- protect user identity and private social graph
- protect direct-message contents
- protect location visibility
- minimize plaintext exposure of sensitive content

## 2. MVP security baseline
Even before full secure messaging is complete, the system must include:
- hashed passwords if password auth is enabled
- secure session tokens
- device/session tracking
- transport encryption (HTTPS/WSS)
- access control in backend
- signed media upload/access patterns where needed

## 3. Direct-message privacy requirement
The product direction requires a two-way encrypted direct messaging system inspired by secure-chat systems.

### Practical meaning
- DM content should be designed for end-to-end encryption
- server should not rely on plaintext message storage as the target long-term design
- encryption keys must be tied to devices or secure user key material

## 4. Recommended implementation approach
### Phase 1
- document crypto design only
- keep message architecture ready for encrypted payloads
- define message envelope structure
- define device/session key ownership model

### Phase 2+
- implement secure key exchange
- implement encrypted payload storage
- implement message decryption on client
- add recovery / multi-device strategy

## 5. Critical design questions still pending
These must be specified before full DM implementation:
1. Is encryption mandatory for all DMs or optional?
2. How will multi-device sync work?
3. What metadata remains visible to server?
4. How will key rotation work?
5. How will lost-device recovery work?

## 6. Recommended documentation rule
OpenCode must not invent the encryption protocol casually. It should implement only the non-crypto message foundation until the secure-message protocol is separately locked.
