# Using Xcode and Swift in FlipFlapp

This guide explains how to work on the iOS app when coming from a JavaScript
toolchain such as Node, `nvm`, and `pnpm`.

## Mental model

A typical JavaScript project puts scripts, dependencies, and runtime constraints
in `package.json`. An Xcode iOS app distributes those responsibilities:

| JavaScript concept | This iOS project's equivalent |
|---|---|
| Node runtime | Swift compiler and Apple SDK bundled with the active Xcode |
| `nvm use 24` | Select an Xcode installation with `xcode-select` |
| `package.json` scripts | Xcode schemes plus documented shell commands |
| `dependencies` | Swift Package Manager references in the Xcode project |
| lockfile | `Package.resolved` |
| workspace/package filter | `-project`, `-scheme`, and `-target` arguments |
| `pnpm dev` | `Command-R` in Xcode, or build/install/launch with Xcode tools |
| browser hot reload | SwiftUI Canvas previews; otherwise rebuild and run |
| ESLint | No direct built-in equivalent; SwiftLint is optional and not installed |
| Prettier | `swift-format`; available with the selected Xcode toolchain |

`Package.swift` is the manifest for a standalone Swift package. This repository
does not have one because its deliverable is an iOS application target managed
by `flipflapp-ios.xcodeproj`. Do not create a root `Package.swift` merely to make
the project resemble a JavaScript repository.

## Install the toolchain

### Required

1. Install the full Xcode application from Apple.
2. Launch it once, accept the license, and let it install platform components.
3. In `Xcode > Settings > Components`, install the iOS Simulator runtime needed
   by the project's deployment target.
4. Select Xcode's command-line tools in
   `Xcode > Settings > Locations > Command Line Tools`.

Confirm the active installation:

```bash
xcode-select -p
xcodebuild -version
swift --version
```

Xcode owns the compatible Swift compiler, iOS SDK, simulator tooling, debugger,
and signing support as one tested toolchain. Installing Swift separately from
Swift.org is useful for some server or package work, but it does not replace
Xcode for building and running an iOS app.

### Switching Xcode versions

This is the closest equivalent to `nvm use`:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

If several versions are installed, point to the intended application, for
example `/Applications/Xcode-26.6.app/Contents/Developer`. This changes the
machine-wide active developer directory, so it is not normally run before every
command. For a one-off shell command without changing the global selection:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project flipflapp-ios.xcodeproj -list
```

Do not change the project's Swift language mode or iOS deployment target just
because a different Xcode is installed. Those are product compatibility
decisions.

## Open and navigate the project

From the `flipflapp-ios` directory:

```bash
open flipflapp-ios.xcodeproj
```

The most useful Xcode areas are:

- Project navigator (`Command-1`): files and groups.
- Find navigator (`Command-3`): repository-wide search.
- Issue navigator (`Command-5`): compiler warnings and errors.
- Debug navigator (`Command-7`): threads, memory, CPU, and network activity.
- Inspector (`Option-Command-0`): settings for the selected item.
- Debug area (`Shift-Command-Y`): console, variables, and debugger controls.

The scheme chooses what to build and how to run it. The run destination chooses
where it runs. For this repository, select the `flipflapp-ios` scheme and an
iPhone Simulator.

## See the app live

There are three different feedback loops.

### 1. Run the complete app in Simulator

This is the reliable default:

1. Start the Rails API if using a local backend.
2. Choose `flipflapp-ios` and an installed iPhone Simulator in the toolbar.
3. Press `Command-R`.
4. Interact with the app in Simulator.
5. Edit code and press `Command-R` again to rebuild and relaunch.

Useful shortcuts:

| Action | Shortcut |
|---|---|
| Run | `Command-R` |
| Stop | `Command-.` |
| Build without running | `Command-B` |
| Clean build folder | `Shift-Command-K` |
| Show/hide debug area | `Shift-Command-Y` |
| Continue after breakpoint | `Control-Command-Y` |

The iOS Simulator is not a browser dev server: source edits do not automatically
hot-reload the whole running app.

### 2. Use the SwiftUI Canvas

SwiftUI previews provide the closest experience to a live component preview:

1. Open a SwiftUI view containing a `#Preview` block.
2. Choose `Editor > Canvas`.
3. Click `Resume`, then use Live mode to interact with the preview.

Minimal example:

```swift
#Preview {
    NotificationRow(notification: .preview)
}
```

Previews should receive deterministic sample values or injected fake services.
They should not depend on a live API, real Keychain credentials, or mutable
production data.

Current project status: no source file contains `#Preview` yet. The Canvas
therefore has nothing to render today. Adding preview fixtures is a useful
follow-up task, especially for reusable `Core/DesignSystem` components and
feature states such as loading, empty, populated, and failed.

### 3. Run on a physical iPhone

Connect or pair the device, sign in under `Xcode > Settings > Accounts`, select
your team under the target's Signing settings, choose the device, and press
`Command-R`.

Use a physical device for camera, notifications, Keychain behavior, performance,
and final interaction checks. Simulator is faster for everyday layout and
navigation work but does not reproduce every device capability.

## Configure the Rails API

`APIConfiguration.swift` reads `FLIPFLAPP_API_BASE_URL` in Debug builds and
falls back to the app's Info configuration, then to `https://flipflapp.fr`.

For local development:

1. Open `Product > Scheme > Edit Scheme…`.
2. Select `Run > Arguments`.
3. Add and enable:

```text
FLIPFLAPP_API_BASE_URL=http://127.0.0.1:3000
```

The Simulator can access the Mac through `127.0.0.1`. A physical phone cannot;
use the Mac's reachable LAN address. Plain HTTP may also require a narrow App
Transport Security exception. Do not add a broad production ATS exception.

Environment variables stored in a user scheme are local to that Mac. Do not put
secrets into schemes, source files, build settings, or the app bundle.

## Dependencies and the “package.json” equivalent

This app uses Swift Package Manager through Xcode.

### Inspect

In Xcode, select the blue project item, then `Package Dependencies`. From the
command line:

```bash
xcodebuild -project flipflapp-ios.xcodeproj -list
cat flipflapp-ios.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

At present, the lockfile contains Hotwire Native `1.2.2`. It is obsolete and not
imported by app code, but its removal is intentionally tracked in
`HOTWIRE_MIGRATION.md`.

### Install or restore locked dependencies

There is no `pnpm install` step after every checkout because Xcode resolves
packages automatically when opening or building the project. To do it explicitly:

```bash
xcodebuild \
  -resolvePackageDependencies \
  -project flipflapp-ios.xcodeproj
```

This fetches the versions selected by the project and recorded in
`Package.resolved`. Commit the lockfile so all contributors and CI use the same
revision.

### Add a dependency

Use `File > Add Package Dependencies…`, enter the trusted repository URL, choose
a semantic version rule, and attach the required product to the app target.
Review both `project.pbxproj` and `Package.resolved`.

Prefer Apple frameworks already in the SDK. Add a third-party dependency only
when its maintenance, security, binary size, licensing, and benefit are clear.
Project policy requires explicit approval before adding, removing, or updating a
dependency.

### Update dependencies

Use `File > Packages > Update to Latest Package Versions`, then review the
lockfile diff, build, and test. An update stays within the version requirement
stored in the Xcode project. Changing that requirement is a separate project
change.

Do not delete `Package.resolved` as a routine update strategy. It removes the
reviewable record of the previously working resolution.

## JavaScript-to-Swift command map

Run commands below from `flipflapp-ios`.

### Fast read-only health check

Comparable to checking the runtime, package graph, and available targets:

```bash
xcodebuild -version
swift --version
xcodebuild -project flipflapp-ios.xcodeproj -list
xcrun simctl list devices available
xcrun swift-format lint --recursive --strict flipflapp-ios
```

The last command only checks formatting. This repository does not yet contain a
shared `.swift-format` file, so do not mass-format and commit the project without
agreeing on a style configuration first.

### Build

First copy an exact name and OS version from `simctl list`:

```bash
xcodebuild \
  -project flipflapp-ios.xcodeproj \
  -scheme flipflapp-ios \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=<device>,OS=<version>' \
  build
```

For scripting, a device identifier avoids ambiguity:

```bash
xcodebuild \
  -project flipflapp-ios.xcodeproj \
  -scheme flipflapp-ios \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=<simulator-udid>' \
  build
```

### Test

The intended command is:

```bash
xcodebuild \
  -project flipflapp-ios.xcodeproj \
  -scheme flipflapp-ios \
  -destination 'platform=iOS Simulator,id=<simulator-udid>' \
  test
```

Current project status: only the application target exists; no unit or UI test
target is configured. The command will not become a meaningful project check
until test targets and a shared scheme containing them are added.

### Format

Check without edits:

```bash
xcrun swift-format lint --recursive --strict flipflapp-ios
```

Apply formatting:

```bash
xcrun swift-format format --in-place --recursive flipflapp-ios
```

Formatting rewrites source files. Review the diff, and establish a committed
`.swift-format` configuration before treating it as an automatic repository-wide
command.

### Lint

The Swift compiler catches type, concurrency, availability, and many correctness
issues during a build. `swift-format lint` checks formatting only. SwiftLint can
enforce additional style and correctness rules, but it is not installed or
configured in this project. Do not document `swiftlint` as a required check until
the team deliberately adopts it.

### Launch from the command line

For everyday development, `Command-R` is the efficient build-install-launch
workflow because it also attaches the debugger. Full command-line launch requires
building, starting a Simulator, installing the built `.app`, and launching its
bundle identifier; that is more brittle than Xcode unless wrapped in a
repository-owned script.

Avoid hardcoding a path inside `DerivedData`, because Xcode may change it. If CLI
automation becomes a team requirement, add an approved script that supplies a
dedicated `-derivedDataPath`, simulator UDID, and API environment consistently.

## A practical daily workflow

The closest current equivalent to
`nvm use 24 && pnpm --filter web format && pnpm --filter web lint && pnpm --filter web dev`
is:

```bash
# Usually once per machine or when changing Xcode, not once per run:
xcode-select -p
xcodebuild -version

# Before opening a PR:
xcrun swift-format lint --recursive --strict flipflapp-ios
xcodebuild \
  -project flipflapp-ios.xcodeproj \
  -scheme flipflapp-ios \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=<simulator-udid>' \
  build

# Interactive development:
open flipflapp-ios.xcodeproj
```

Then press `Command-R` in Xcode. Once test targets and formatting policy exist,
the repository can expose these commands behind a small `Makefile` or `justfile`
(`make check`, `make test`, `make dev`) to provide a stable, memorable interface.
Until then, copying a guessed simulator name or claiming unsupported checks would
hide useful failures.

## Troubleshooting

### “Unable to find a destination”

Run:

```bash
xcrun simctl list devices available
```

Install a compatible runtime in Xcode settings and use an exact listed
device/OS pair or UDID.

### Command-line tools point to the wrong Xcode

```bash
xcode-select -p
xcodebuild -version
```

Select the intended full Xcode installation with `xcode-select --switch`.

### Package resolution fails

Check network or private-repository credentials, then use
`File > Packages > Reset Package Caches` only when the local cache is genuinely
suspect. Keep `Package.resolved` and inspect the underlying error before resetting
caches.

### Canvas preview fails

Confirm that the file has a `#Preview`, the selected scheme builds, preview input
is deterministic, and all required environment values are injected. Build errors
anywhere in the target can prevent previews from compiling.

### The local API is unreachable

Confirm Rails is listening on the expected host and port and that the scheme's
environment variable is enabled. Remember that `127.0.0.1` means the Mac from
Simulator but means the phone itself from a physical iPhone.

## Official references

- [Running an app on simulated or physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)
- [Previewing an app interface in Xcode](https://developer.apple.com/documentation/xcode/previewing-your-apps-interface-in-xcode)
- [Adding package dependencies to an app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [Swift packages in Xcode](https://developer.apple.com/documentation/xcode/swift-packages)
- [Xcode command-line tool reference](https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference)
- [Installing the command-line tools](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools)
