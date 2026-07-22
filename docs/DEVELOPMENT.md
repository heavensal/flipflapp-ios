# Development

## Requirements

- A supported macOS/Xcode pair for the project's selected SDK.
- Command Line Tools selected for that Xcode.
- Access to the Rails API environment being used.

Do not silently change the deployment target or Swift language mode to match the locally installed Xcode. The current project settings require review during native migration.

## Inspect the project

```bash
xcodebuild -project flipflapp-ios.xcodeproj -list
xcodebuild -project flipflapp-ios.xcodeproj -showBuildSettings -scheme flipflapp-ios
xcrun simctl list devices available
```

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
