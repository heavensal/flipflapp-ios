# Native iOS Architecture

## Direction

Use a feature-first SwiftUI architecture with a small dependency-injected core. This is not Rails MVC and not a web-navigation shell.

```text
App composition
  ├── Session
  ├── Core
  │   ├── API
  │   ├── Security
  │   ├── Logging
  │   └── DesignSystem
  └── Features
      ├── Authentication
      ├── Events
      ├── EventDetails
      ├── EventEditor
      ├── Friendships
      ├── Notifications
      └── Profile
```

## Suggested layout

```text
flipflapp-ios/
  App/
    FlipFlapp.swift
    AppEnvironment.swift
    AppRouter.swift
  Core/
    API/
    Security/
    Logging/
    DesignSystem/
    Models/
  Features/
    Events/
      EventsScreen.swift
      EventsModel.swift
      Components/
    ...
  Resources/
    Localizable.xcstrings
    Assets.xcassets
flipflapp-iosTests/
flipflapp-iosUITests/
```

Create folders incrementally as features arrive. Do not scaffold empty layers.

## Data flow

```text
User action → SwiftUI view → feature model → typed API client
                                      ↓
Rendered state ← observable state ← mapped response/error
```

- Views depend on feature state and intent methods.
- Feature models are `@MainActor` and own request lifecycle for their screen.
- The API client is concurrency-safe and does not depend on SwiftUI.
- Token storage is isolated behind a minimal `TokenStore` boundary.
- Navigation is driven by typed destinations, not URL strings from the website.

## State modeling

Prefer explicit state machines over unrelated booleans:

```swift
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(AppError)
}
```

Use a separate refresh marker when existing content stays visible. Avoid replacing useful content with a full-screen spinner during refresh.

## Observation and ownership

- The app composition root creates long-lived dependencies and session state.
- A feature container owns its `@Observable` feature model using `@State` where supported.
- Child views receive values, bindings, or narrowly scoped observable dependencies.
- Do not inject a single god environment object containing every feature.
- Do not store transient view concerns in global app state.

## Navigation

- Signed-out root: authentication flow.
- Signed-in root: stable top-level `TabView` with the smallest useful set of sections.
- Use `NavigationStack` and typed `Hashable` destinations inside each tab.
- Use sheets for focused temporary tasks such as creating/editing an event or inviting friends.
- Preserve each tab's navigation context.
- Deep links map to typed destinations after session restoration and authorization-aware fetching.

Initial information architecture proposal:

| Tab | Purpose |
|---|---|
| Events | Upcoming visible events and event creation |
| Friends | Accepted/pending/declined relationships and search |
| Notifications | Inbox with unread badge |
| Profile | Current-user profile and sign-out |

This is a design hypothesis, not permission to invent API behavior.

## Dependencies

Inject dependencies through an `AppEnvironment` or explicit initializers. Use protocols only where tests or multiple implementations need substitution.

Good boundaries:

- `APIClient`
- `TokenStore`
- `Clock`
- `UUIDGenerator` when deterministic identifiers matter

Avoid repository/use-case/interactor layers that merely rename one API call.

## Concurrency

- UI state mutations occur on `MainActor`.
- API operations are `async throws` and cancellation-aware.
- Keep a task handle when a screen owns cancellable work.
- Cancel obsolete search and load operations when query/identity changes.
- Use actors for mutable shared state that genuinely crosses tasks.
- Make boundary values `Sendable` where correct.
- Never mark a type `@unchecked Sendable` only to suppress a compiler warning.

## Caching and persistence

MVP defaults:

- JWT: Keychain.
- Preferences: `AppStorage`/`UserDefaults` only for non-sensitive preferences.
- API resources: in-memory feature/session cache unless a documented offline requirement exists.
- Images: rely on system URL loading/cache initially; add a package only after measured need.

Do not introduce SwiftData/Core Data as an API cache without an offline product contract, invalidation rules, and migration tests.

## Composition over framework building

Use direct, readable feature code. Extract a reusable component when at least two real screens share semantics, not merely similar pixels. Add a package only when Apple frameworks or a small local type cannot meet the requirement safely.
