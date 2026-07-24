# FlipFlapp iOS

Native SwiftUI client for the FlipFlapp football-event MVP. The Rails application
provides the `/api/v1` JSON API and remains authoritative for domain rules and
authorization.

## Quick start

You need a Mac with the full Xcode application installed. The standalone Command
Line Tools package is not enough to run iOS simulators.

```bash
cd flipflapp-ios
open flipflapp-ios.xcodeproj
```

In Xcode:

1. Select the `flipflapp-ios` scheme.
2. Select an installed iPhone Simulator as the run destination.
3. Press `Command-R` to build and run.
4. Press `Command-.` to stop.

The app uses `https://flipflapp.fr` by default. To use a local Rails API, edit the
scheme (`Product > Scheme > Edit Scheme… > Run > Arguments > Environment
Variables`) and add:

```text
FLIPFLAPP_API_BASE_URL=http://127.0.0.1:3000
```

Start the sibling Rails repository separately before launching the app. Use
`127.0.0.1`, not `localhost`, to make the intended host explicit. A physical
iPhone cannot reach the Mac through `127.0.0.1`; use the Mac's LAN address and
appropriate development networking configuration instead.

For the complete beginner-to-command-line workflow, read
[Using Xcode and Swift in this project](docs/XCODE_GUIDE.md).

## Common commands

Run these from this directory:

```bash
# Open the project.
open flipflapp-ios.xcodeproj

# Inspect schemes and available simulators.
xcodebuild -project flipflapp-ios.xcodeproj -list
xcrun simctl list devices available

# Resolve the exact Swift package versions recorded in Package.resolved.
xcodebuild -resolvePackageDependencies -project flipflapp-ios.xcodeproj

# Check formatting without changing files.
xcrun swift-format lint --recursive --strict flipflapp-ios

# Build after replacing the destination with one installed on this Mac.
xcodebuild \
  -project flipflapp-ios.xcodeproj \
  -scheme flipflapp-ios \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=<device>,OS=<version>' \
  build
```

There is no `nvm use` equivalent to run for each shell: this project uses the
Swift toolchain bundled with the active Xcode. There is also no repository
formatter configuration or test target yet, so formatting changes and
`xcodebuild test` should not be treated as established project checks. See the
[command mapping](docs/XCODE_GUIDE.md#javascript-to-swift-command-map) for the
closest equivalents to an `nvm`/`pnpm` workflow.

## Project structure

| Folder | Responsibility |
|---|---|
| `App/` | Composition root, session state, tabs, and shared badges |
| `Core/API/` | HTTP transport, error mapping, and the v1 operation surface |
| `Core/Models/` | Typed resource identifiers and OpenAPI-aligned DTOs |
| `Core/Security/` | Keychain-backed bearer-token storage |
| `Core/DesignSystem/` | Reusable native UI components |
| `Features/` | Authentication, events, friendships, notifications, and profiles |

This is an Xcode application project, not a standalone Swift package. Its targets
and build settings live in `flipflapp-ios.xcodeproj/project.pbxproj`; third-party
dependencies use Swift Package Manager, and their exact resolved revisions live
in `flipflapp-ios.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

The obsolete Hotwire package reference is intentionally left in the project
until the separately approved cleanup described in
[docs/HOTWIRE_MIGRATION.md](docs/HOTWIRE_MIGRATION.md). No app source imports or
executes it.

## Documentation

| Topic | Document |
|---|---|
| Xcode, live preview, packages, and commands | [docs/XCODE_GUIDE.md](docs/XCODE_GUIDE.md) |
| Local development reference | [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) |
| Product scope | [docs/PROJECT.md](docs/PROJECT.md) |
| Mobile domain | [docs/DOMAIN.md](docs/DOMAIN.md) |
| Rails API integration | [docs/API.md](docs/API.md) |
| Native architecture | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Swift conventions | [docs/SWIFT_STYLEGUIDE.md](docs/SWIFT_STYLEGUIDE.md) |
| Apple-native design | [docs/DESIGN.md](docs/DESIGN.md) |
| Security and privacy | [docs/SECURITY.md](docs/SECURITY.md) |
| Testing | [docs/TESTING.md](docs/TESTING.md) |
| Hotwire removal | [docs/HOTWIRE_MIGRATION.md](docs/HOTWIRE_MIGRATION.md) |
| Agent rules | [AGENTS.md](AGENTS.md) |

## Backend contract

When both repositories are checked out as siblings, the authoritative references
are:

- `../flipflapp-rails/docs/DOMAIN.md`
- `../flipflapp-rails/docs/API.md`
- `../flipflapp-rails/swagger/v1/swagger.yaml`

Do not implement against Rails HTML routes. Native features consume the versioned
JSON contract.
