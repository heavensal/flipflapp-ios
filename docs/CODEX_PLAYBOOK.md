# Codex Playbook

Operational guide for Codex work in FlipFlapp iOS. Durable policy lives in [../AGENTS.md](../AGENTS.md).

## Default protocol

1. **Orient** — read `AGENTS.md`, `PROJECT.md`, relevant `DOMAIN.md`, `API.md`, and nested instructions.
2. **Inspect** — inspect project settings, nearby Swift, tests, assets, localization, and the Rails OpenAPI operation involved.
3. **Classify** — identify domain/API/UI/security/project/dependency impact.
4. **Clarify** — surface missing behavior, platform-version assumptions, API gaps, and irreversible project changes.
5. **Choose native mechanics** — prefer SwiftUI, Foundation, Security, Observation, structured concurrency, and system components.
6. **Design state first** — enumerate loading/content/empty/failure/auth/cancellation states and user recovery.
7. **Test behavior** — add the smallest useful Swift Testing or XCTest coverage.
8. **Implement vertically** — API boundary, state model, UI, localization, accessibility.
9. **Verify proportionally** — diff/static checks always; build/tests only when approved.
10. **Report honestly** — delivered behavior, decisions, checks, and remaining approvals.

## Research order

1. Installed SDK and repository code.
2. Apple Developer Documentation and Human Interface Guidelines.
3. Swift Evolution or official Apple Swift package repositories for language/package behavior.
4. Third-party sources only when primary sources do not answer the question.

Use the configured `apple-docs` MCP server for current Apple API/design lookup when available. Never invent availability for the selected deployment target.

## Change boundaries

| Action | Default |
|---|---|
| Read/search/status/diff | Allowed |
| Requested in-scope docs/source/test edits | Allowed |
| Package add/remove/update | Ask first |
| Xcode target/build/signing/capability changes | Ask first |
| Deployment target or Swift mode change | Ask first |
| Delete Hotwire files/references | Ask first and follow migration plan |
| Run build/test/formatter/generator | Ask for exact command |
| Change Rails/OpenAPI | Propose and coordinate first |
| Commit/push/release | Ask first |

## Feature prompt

```text
Build [feature] as native SwiftUI using AGENTS.md and docs/TESTING.md.
Read PROJECT.md, the relevant DOMAIN.md section, API.md, and the exact Rails
OpenAPI operation first. Model every user-visible state and recovery path.
Prefer Apple frameworks and structured concurrency. Add focused tests before
production behavior. Do not add dependencies or change Xcode settings without
approval. Include localization, Dynamic Type, VoiceOver, cancellation, and
server error handling in the definition of done.
```

## UI prompt

```text
Design and implement [screen] using docs/DESIGN.md and current Apple HIG.
Use semantic SwiftUI controls, system navigation, Dynamic Type, SF Symbols,
dark mode, VoiceOver, Reduce Motion, loading/empty/failure states, and localized
copy. Preserve Rails domain terms below the presentation layer. Do not reproduce
the Rails web layout or add custom chrome before the native flow is complete.
```

## API prompt

```text
Implement [operation] from the reviewed Rails OpenAPI schema. Keep transport
DTOs aligned with the contract, use async/await with cancellation, inject the
client, map HTTP/auth/validation/decoding errors once, protect sensitive data,
and add deterministic request/response tests. If the schema cannot express the
required behavior, stop and propose the Rails contract change.
```

## Review prompt

```text
Review this change against AGENTS.md, PROJECT.md, DOMAIN.md, API.md, DESIGN.md,
SECURITY.md, and TESTING.md. Prioritize contract drift, incorrect authorization
assumptions, actor/cancellation bugs, state ownership, sensitive-data leakage,
accessibility, localization, missing failure states, unnecessary dependencies,
and untested behavior. List actionable findings with file references. Do not edit.
```

## Completion template

- User outcome:
- Architecture/API decisions:
- Files and targets changed:
- Accessibility/localization covered:
- Build/tests run (exact command and result):
- Not run:
- Dependencies/configuration changed:
- API assumptions or backend work remaining:
- Next approved slice:
