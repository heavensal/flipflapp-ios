# Security and Privacy

## Session credentials

- Store the bearer JWT with Keychain Services.
- Use a stable service/account namespace tied to the app, not the user's email as an unprotected lookup key.
- Choose Keychain accessibility intentionally; default to a device-only class appropriate for a session token.
- Clear the token and authenticated memory state on sign-out and invalid-session `401` responses.
- Never persist passwords, confirmation tokens, or password-reset tokens beyond the active flow.

Apple reference: [Keychain Services](https://developer.apple.com/documentation/security/keychain-services).

## Networking

- Production uses HTTPS with App Transport Security.
- No `NSAllowsArbitraryLoads`.
- Local development exceptions, if unavoidable, are narrow, debug-only, documented, and separately approved.
- Validate status and content type before decoding.
- Do not implement custom certificate pinning without an operational rotation and incident plan.

Apple reference: [URLSession](https://developer.apple.com/documentation/foundation/urlsession).

## Logging

Use OSLog categories with privacy annotations. Never log:

- `Authorization` headers or JWTs;
- passwords/reset/confirmation tokens;
- full user payloads, notification payloads, or request bodies;
- Keychain query results;
- precise location unless explicitly required and redacted.

Log stable operation names, status classes, durations, cancellation, and redacted request IDs.

## App data

- Treat API data as private unless the product explicitly says it is public.
- Store only what the active product flow needs.
- Clear user-scoped caches when the session changes.
- Do not include production user data in previews, fixtures, screenshots, or tests.
- Use synthetic emails, names, tokens, coordinates, and payloads.

## Permissions and platform capabilities

- Do not add location, notifications, contacts, camera, photos, or background capabilities preemptively.
- Explain the value before the system permission prompt.
- Provide a useful degraded state after denial.
- Keep `Info.plist` purpose strings specific and localized.

## Threat checklist

- Can crafted navigation expose content not returned by the server?
- Can a stale user session leak data after account switching?
- Can logs or crash reports contain credentials or personal data?
- Can duplicate taps repeat a destructive mutation?
- Can a malicious/invalid response crash decoding or rendering?
- Can copied source or configuration expose secrets?
- Can a URL/deep link invoke privileged UI without authenticated fetching?

Server authorization remains mandatory even when every client control is hidden correctly.
