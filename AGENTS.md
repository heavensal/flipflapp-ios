# FlipFlapp iOS Agent Guide

FlipFlapp iOS is the native Swift client for the FlipFlapp football-event MVP. It consumes the Rails JSON API; it is not a wrapper around the Rails website.

Technical text, code, tests, and commit messages are in English. User-facing copy is localized, with French shipping first.

## Mission

Build a production-quality native iOS app with SwiftUI and Apple frameworks. Preserve the Rails domain contract, make every important state explicit, and favor platform conventions, accessibility, security, and testability over custom infrastructure.

For every non-trivial change:

1. Read [docs/PROJECT.md](docs/PROJECT.md), the relevant section of [docs/DOMAIN.md](docs/DOMAIN.md), and [docs/API.md](docs/API.md).
2. Read the nearest code, tests, Xcode settings, and the closest nested `AGENTS.md` before editing.
3. Classify the work as domain, API, UI, persistence, project configuration, or documentation.
4. State ambiguities, API impact, dependency impact, deployment-target impact, and the smallest native approach.
5. Write or update tests before production behavior when practical.

## Product and backend truth

- Backend business rules live in the Rails repository: `../flipflapp-rails/docs/DOMAIN.md`.
- The mobile HTTP contract lives in `../flipflapp-rails/swagger/v1/swagger.yaml` and `../flipflapp-rails/docs/API.md`.
- This repository must not recreate authorization or domain invariants as an independent source of truth.
- Client-side checks improve UX only. The server remains authoritative.
- If an iOS feature needs an API change, stop and propose the Rails/OpenAPI change first.

## Native-only boundary

- SwiftUI is the default UI framework.
- Use UIKit only when a required capability has no adequate SwiftUI API, and isolate the adapter.
- Remove Hotwire Native through [docs/HOTWIRE_MIGRATION.md](docs/HOTWIRE_MIGRATION.md).
- Do not add `WKWebView`, web routes, HTML parsing, Turbo, Strada, or another hybrid navigation layer.
- Do not mirror Rails MVC in the app.

## Preferred stack

- SwiftUI for UI and navigation.
- Observation (`@Observable`) for reference state when supported by the chosen deployment target.
- Structured concurrency (`async`/`await`, task groups, actors) with explicit cancellation.
- Foundation `URLSession` for transport.
- Keychain Services for bearer tokens; never `UserDefaults` or source files.
- `Codable`, `Decimal`, `Date`, and typed identifiers at API boundaries.
- Swift Testing for new unit/integration tests; XCTest/XCUIAutomation for UI tests.
- OSLog for privacy-aware diagnostics.
- Swift Package Manager only for dependencies that materially reduce risk or generated boilerplate.

## Architecture rules

- Organize by feature, with small shared `Core` capabilities. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- Views render state and emit user intent. They do not build requests, decode JSON, access Keychain, or contain business workflows.
- Feature models own presentation state and orchestration; API clients own HTTP details.
- Prefer concrete types. Introduce protocols only at real substitution boundaries such as API clients, clocks, token stores, and test doubles.
- Use dependency injection from the app composition root; no service locator and no mutable global singleton.
- UI-observed state is `@MainActor`. Networking and decoding must not be forced onto the main actor.
- Model loading, empty, content, refreshing, and failure states explicitly.
- Never launch unstructured `Task` work without considering ownership and cancellation.

## Swift quality bar

- Enable strict concurrency intentionally and fix warnings; do not silence them with unchecked `Sendable` without a documented proof.
- Prefer value types and immutable values.
- Do not use force unwraps, `try!`, `fatalError`, or implicitly unwrapped optionals in production paths.
- Preserve server field names only in transport DTOs; map to clear Swift names at the boundary when needed.
- Decode server decimals without routing them through binary floating point.
- Centralize date encoding/decoding and locale-independent API formats.
- Keep files focused; split around one responsibility, not arbitrary line counts.
- Comments explain constraints and decisions, not syntax.

## Apple design rules

- Follow [docs/DESIGN.md](docs/DESIGN.md) and the current Apple Human Interface Guidelines.
- Use native navigation containers, controls, typography, materials, and SF Symbols.
- Do not hardcode device dimensions, safe-area offsets, Dynamic Type sizes, or light-mode colors.
- Every screen supports Dynamic Type, VoiceOver, sufficient contrast, Reduce Motion, and at least 44×44 pt default touch targets.
- Keep destructive actions explicit and confirm material irreversible effects.
- Loading must preserve context; errors must explain recovery; empty states must offer the next useful action.
- Add custom visual language only after the core flows work with system components.

## Security and privacy

- Production traffic uses HTTPS and App Transport Security; do not add broad ATS exceptions.
- Store the JWT in Keychain and remove it on sign-out or terminal authentication failure.
- Never log tokens, passwords, reset tokens, confirmation tokens, full request bodies, or private user data.
- Treat every server payload as untrusted input.
- Do not embed secrets, private keys, or environment credentials in the app bundle.
- Request system permissions only at the moment their value is clear to the user.

## Testing workflow

Follow [docs/TESTING.md](docs/TESTING.md):

1. Define observable behavior and edge cases.
2. Add focused tests for decoding, request construction, state transitions, cancellation, and error mapping.
3. Implement the smallest native change.
4. Add UI tests only for critical end-to-end journeys.
5. Build and test the changed scheme/destination before completion when command execution is approved.

## Approval gates

Explicit user approval is required before:

- adding, removing, or updating a package dependency;
- changing the deployment target, signing, bundle identifier, capabilities, entitlements, or build settings;
- modifying the Xcode project mechanically or running a project generator;
- deleting Hotwire files/package references;
- running commands, builds, tests, formatters, commits, pushes, or releases;
- changing the Rails API or generated OpenAPI artifact.

Read-only inspection and requested in-scope documentation/source edits are allowed.

## Required reading

| Task | Read first |
|---|---|
| Any feature | `PROJECT.md`, relevant `DOMAIN.md`, `API.md`, `TESTING.md` |
| App architecture | `ARCHITECTURE.md`, `SWIFT_STYLEGUIDE.md` |
| UI or navigation | `DESIGN.md`, nearest feature views |
| Networking/auth | `API.md`, Rails OpenAPI, `SECURITY.md` |
| Remove Hotwire | `HOTWIRE_MIGRATION.md` |
| Local commands | `DEVELOPMENT.md` |
| Codex workflow | `CODEX_PLAYBOOK.md` |

## Completion report

Report the delivered behavior, major decisions, files changed, verification run or omitted, dependency/configuration changes, API assumptions, and any remaining product decision. Never claim a build or test passed unless it was run.
