# Rails API Integration

FlipFlapp iOS consumes the versioned JSON API at `/api/v1`. The generated artifact in `../../flipflapp-rails/swagger/v1/swagger.yaml` is the machine-readable contract.

## Environments

Centralize base URLs in configuration selected at build/composition time:

| Environment | Base URL |
|---|---|
| Local simulator | explicitly configured developer URL |
| Staging | product decision; never infer from production |
| Production | `https://flipflapp.fr` |

Do not scatter URLs across views or targets. Do not weaken App Transport Security globally for local development.

## Preferred client strategy

Use Apple's Swift OpenAPI Generator with its `URLSession` transport after explicit dependency approval. It generates typed operations at build time from the Rails schema and reduces drift.

Expected packages:

- `apple/swift-openapi-generator`
- `apple/swift-openapi-runtime`
- `apple/swift-openapi-urlsession`

Keep a reviewed copy or deterministic synchronization of `swagger.yaml` in the iOS target. Never fetch the schema during an app build. Generated code is not hand-edited.

If generation is temporarily blocked, use a small `URLSession` client behind the same feature-facing API protocols. Do not create a generic networking framework.

## Authentication

1. `POST /api/v1/users/sign_in` with the nested `user` payload.
2. Decode the current user.
3. Read `Authorization: Bearer <jwt>` from the HTTP response headers.
4. Store the token in Keychain.
5. Attach it to every protected request.
6. `DELETE /api/v1/users/sign_out`, then clear local credentials even if remote revocation cannot complete after an explicit user sign-out.

The auth coordinator has three stable states: `.restoring`, `.signedOut`, and `.signedIn(CurrentUser)`.

## HTTP and error mapping

Map transport results once at the API boundary:

| Status/condition | App meaning |
|---|---|
| `200`, `201` | decoded success |
| `204` | successful operation with no body |
| `401` | invalid/missing session, or invalid credentials on sign-in |
| `403` | authenticated but not permitted |
| `404` | missing or deliberately hidden resource |
| `422` | validation/business rejection with optional field details |
| cancellation | silent cancellation unless the user needs feedback |
| timeout/offline | recoverable connectivity state |
| decoding/contract mismatch | nonrecoverable client/API compatibility error with safe user copy and diagnostic logging |

Devise authentication errors currently use `{ "error": "…" }`. Application errors use `{ "error": { "message": "…", "details": { ... } } }`.

Never show raw server messages as the only localized user copy. Preserve structured field details for forms and map known cases to localization keys.

## Request behavior

- Use `async`/`await` and propagate cancellation.
- Validate `HTTPURLResponse` before decoding success bodies.
- Set `Accept: application/json`; set content type only when a body is present.
- Do not retry writes automatically.
- Retry idempotent reads only with an explicit bounded policy and only for transient failures.
- Prevent duplicate mutations at the feature-state layer while a request is in flight.
- Use request identifiers in logs, never tokens or sensitive bodies.

## Data mapping

- Transport DTOs match OpenAPI exactly.
- Feature/domain models expose the semantics the UI needs without copying Rails business logic.
- Use explicit `JSONDecoder` strategies for dates.
- Preserve `Decimal` values losslessly.
- Treat nullable and absent as distinct when OpenAPI distinguishes them.
- Unknown enum values require an intentional compatibility strategy; generated exhaustive enums must be reviewed when the backend adds values.

## API evolution workflow

1. Identify the missing or changed mobile behavior.
2. Update Rails domain/controller/serializer/request specs.
3. Regenerate and review Rails OpenAPI.
4. Synchronize the schema into iOS.
5. Regenerate the client.
6. Update adapters, feature state, fixtures, and tests.
7. Verify backward compatibility or coordinate a versioned `/api/v2` migration.

Do not silently patch generated types or decode undocumented fields.

## Current resources

The v1 contract contains authentication, users, events, event teams, event participants, invitations, friendships, and notifications. Consult the schema for exact methods, paths, request bodies, response models, and operation identifiers; do not duplicate the full generated surface here.
