# Development

For an onboarding guide covering Xcode, SwiftUI live previews, Swift Package
Manager, and JavaScript-to-Swift command equivalents, start with
[XCODE_GUIDE.md](XCODE_GUIDE.md). This document is the compact command reference.

## Requirements

- The full Xcode application on a supported macOS version.
- Command Line Tools selected for that Xcode.
- A compatible iOS Simulator runtime installed through Xcode.
- Access to the Rails API environment being used.

Do not silently change the deployment target or Swift language mode to match the locally installed Xcode. The current project settings require review during native migration.

## Inspect the project

```bash
xcode-select -p
xcodebuild -version
swift --version
xcodebuild -project flipflapp-ios.xcodeproj -list
xcodebuild -project flipflapp-ios.xcodeproj -showBuildSettings -scheme flipflapp-ios
xcrun simctl list devices available
```

## Packages

Xcode resolves the Swift package versions locked in `Package.resolved`
automatically. To resolve them explicitly:

```bash
xcodebuild \
  -resolvePackageDependencies \
  -project flipflapp-ios.xcodeproj
```

Adding, removing, or updating a package requires approval and a review of both
the Xcode project and `Package.resolved`.

## Formatting

The selected Xcode toolchain includes `swift-format`. Check formatting without
modifying files:

```bash
xcrun swift-format lint --recursive --strict flipflapp-ios
```

The repository does not yet have a shared `.swift-format` configuration. Do not
apply repository-wide formatting until that policy is agreed and committed.

## Build

Choose an installed simulator explicitly:

```bash
xcodebuild \
  -project flipflapp-ios.xcodeproj \
  -scheme flipflapp-ios \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=<installed device>,OS=<installed version>' \
  build
```

## Test

After test targets exist:

```bash
xcodebuild \
  -project flipflapp-ios.xcodeproj \
  -scheme flipflapp-ios \
  -destination 'platform=iOS Simulator,name=<installed device>,OS=<installed version>' \
  test
```

Never use a guessed destination in CI. Pin a supported runtime/device and update it intentionally.

The project currently has no unit or UI test target, so this is not yet an
operational check.

## OpenAPI synchronization proposal

After Swift OpenAPI Generator is approved and configured:

1. Regenerate Rails `swagger/v1/swagger.yaml` in the Rails repository.
2. Review its diff.
3. Copy it deterministically into the iOS API source directory.
4. Build, which regenerates typed client code.
5. Run decoding/client tests.

The exact sync command belongs in the repository only after the destination path and package integration are implemented.

## Project hygiene

- Commit shared schemes; do not commit `xcuserdata`.
- Keep secrets and local endpoints out of source control.
- Review `project.pbxproj` diffs carefully.
- Resolve packages deterministically and review `Package.resolved` changes.
- Do not add capabilities, entitlements, signing changes, or packages as incidental build fixes.

## Before handoff

- Inspect `git diff --check` and `git status`.
- Build the changed scheme when approved.
- Run targeted tests when approved.
- Confirm no Hotwire/WebKit import remains after the migration phase that removes it.
- Confirm no token, password, or private endpoint entered the diff.
