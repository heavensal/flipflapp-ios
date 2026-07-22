# Hotwire Native Removal Plan

## Goal

Replace the current website navigator with a native SwiftUI app consuming `/api/v1`, then remove every Hotwire dependency and source artifact. No `WKWebView` fallback remains.

## Current state

- `flipflapp_iosApp.swift` imports/configures `HotwireNative`.
- `ContentView.swift` renders `HotwireRootView`.
- `HotwireRootView.swift` wraps a Hotwire `Navigator` starting at `https://flipflapp.fr`.
- The Xcode project links the `hotwire-native-ios` package/product.
- `Package.resolved` pins Hotwire Native.
- There are no test targets or native feature/API layers yet.

## Safe migration sequence

### Phase 0 — project decisions

Before code changes, explicitly decide:

- minimum iOS deployment target;
- Swift language mode and strict-concurrency rollout;
- bundle identifier/signing configuration;
- local/staging/production API configuration;
- approval to add Swift OpenAPI Generator packages;
- initial tab/information architecture.

The current deployment target and bundle identifier look provisional and must not become accidental production decisions.

### Phase 1 — native foundation

- Add unit and UI test targets.
- Add app composition, environment configuration, API error model, token store, and session state.
- Integrate the reviewed OpenAPI schema and typed client, or a temporary small URLSession client.
- Add synthetic fixtures and client/auth tests.

### Phase 2 — authentication root

- Implement native session restoration, sign-in, registration, confirmation, and password-reset screens.
- Switch app root between signed-out and signed-in SwiftUI trees.
- Store JWT only in Keychain.
- Verify `401`, offline, validation, cancellation, and sign-out behavior.

### Phase 3 — signed-in shell

- Add native tab/navigation structure.
- Build native Events list and details first.
- Add explicit loading/empty/failure states and accessibility acceptance.

### Phase 4 — complete MVP features

- Event create/edit/delete.
- Teams and participation.
- Invitations.
- Friendships/search.
- Notifications.
- Profile/update/sign-out.

Each vertical slice includes API mapping, feature state, SwiftUI, localization, unit tests, and proportionate UI coverage.

### Phase 5 — remove Hotwire atomically

After the native signed-in root and required MVP route replacements exist:

- remove `import HotwireNative` and all Hotwire configuration;
- replace `ContentView` with the native app root;
- delete `HotwireRootView.swift`;
- remove the Hotwire package product and remote package reference from the Xcode project;
- resolve packages so `Package.resolved` no longer pins Hotwire;
- search for `Hotwire`, `Turbo`, `Strada`, `WKWebView`, and `flipflapp.fr` navigation remnants;
- build and test the app.

Do not delete the dependency first if it leaves the branch without a runnable root experience.

## Definition of done

- No Hotwire/Turbo/Strada/WebKit dependency or source reference.
- No screen loads Rails HTML.
- Every supported user journey calls `/api/v1` through the typed/native client.
- Authentication uses bearer JWT in Keychain.
- The app launches into native SwiftUI for both signed-out and signed-in states.
- Targeted unit/UI tests and simulator build pass.
- VoiceOver and large Dynamic Type checks pass for migrated screens.
- Rails web UI changes cannot alter native iOS navigation or rendering.

## Rollback

Keep migration commits small and vertical. Roll back a feature slice through Git history; do not maintain a permanent runtime switch between Hotwire and native implementations.
