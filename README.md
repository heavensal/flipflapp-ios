# FlipFlapp iOS

Native SwiftUI client for the FlipFlapp football-event MVP. The Rails application provides the `/api/v1` JSON API and remains authoritative for domain rules and authorization.

The current app is an initial Hotwire Native shell. The target is a fully native SwiftUI application; follow [docs/HOTWIRE_MIGRATION.md](docs/HOTWIRE_MIGRATION.md).

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
