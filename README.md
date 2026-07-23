# FlipFlapp iOS

Native SwiftUI client for the FlipFlapp football-event MVP. The Rails application provides the `/api/v1` JSON API and remains authoritative for domain rules and authorization.

The runtime is fully native: a SwiftUI session root consumes every operation in the current OpenAPI contract through an actor-isolated `URLSession` client. Authentication tokens are stored in Keychain and no Rails HTML route is rendered.

## Source layout

| Folder | Responsibility |
|---|---|
| `App/` | Composition root, session state, tabs and shared badges |
| `Core/API/` | HTTP transport, error mapping and the complete v1 operation surface |
| `Core/Models/` | Typed resource identifiers and OpenAPI-aligned DTOs |
| `Core/Security/` | Keychain-backed bearer token storage |
| `Core/DesignSystem/` | Reusable native cards, loading states, avatars and status components |
| `Features/` | Authentication, events, event details/editor, friendships, notifications and profiles |

The obsolete Hotwire package reference is intentionally left in the Xcode project until the separately approved cleanup step described in [docs/HOTWIRE_MIGRATION.md](docs/HOTWIRE_MIGRATION.md). No app source imports or executes it.

## Documentation

| Topic | Document |
|---|---|
| Agent rules | [AGENTS.md](AGENTS.md) |
| Product scope | [docs/PROJECT.md](docs/PROJECT.md) |
| Mobile domain | [docs/DOMAIN.md](docs/DOMAIN.md) |
| Rails API integration | [docs/API.md](docs/API.md) |
| Native architecture | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Swift conventions | [docs/SWIFT_STYLEGUIDE.md](docs/SWIFT_STYLEGUIDE.md) |
| Apple-native design | [docs/DESIGN.md](docs/DESIGN.md) |
| Security/privacy | [docs/SECURITY.md](docs/SECURITY.md) |
| Testing | [docs/TESTING.md](docs/TESTING.md) |
| Local development | [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) |
| Hotwire removal | [docs/HOTWIRE_MIGRATION.md](docs/HOTWIRE_MIGRATION.md) |
| Codex workflow/prompts | [docs/CODEX_PLAYBOOK.md](docs/CODEX_PLAYBOOK.md) |

## Authoritative backend references

When both repositories are checked out as siblings:

- `../flipflapp-rails/docs/DOMAIN.md`
- `../flipflapp-rails/docs/API.md`
- `../flipflapp-rails/swagger/v1/swagger.yaml`

Do not implement against Rails HTML routes. Native features consume the versioned JSON contract.
