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

## UI reactivity

The app follows a **stale-while-revalidate** pattern so lists and forms stay usable while data refreshes in the background.

### Rules

1. **Full-screen spinner only on first load** — use `LoadState.loading` when `state` is `.idle` and there is no cached value. Never replace visible content with a spinner on refresh, search, or retry.
2. **Keep content during refresh** — when `LoadState` already has `.loaded(value)`, keep showing `value` and set `isRefreshing` (or domain-specific flags like `isSearching`) instead of switching back to `.loading`.
3. **Per-row / per-button mutations** — track `sendingUserID`, `mutatingFriendshipID`, or `workingTeamID` per item. Do not disable an entire list while one row is submitting.
4. **Optimistic UI with rollback** — apply local state changes immediately for read/delete/accept/decline/send; revert on `422`/`403` and surface an inline error.
5. **Inline errors** — show `InlineErrorView` or field messages below the affected UI. Do not replace a loaded list with `ContentUnavailableView` on a failed refresh.
6. **Ignore stale responses** — increment a generation counter or compare the current query/identity before applying async results (see `FriendsSearchModel.searchGeneration`).
7. **No auto-retry on writes** — failed POST/PATCH/DELETE stay failed until the user retries.

### Building blocks

- [`LoadState`](flipflapp-ios/Core/DesignSystem/LoadState.swift) — `hasContent`, `loadedValue` for stale-while-revalidate checks.
- [`LoadStateView`](flipflapp-ios/Core/DesignSystem/LoadStateView.swift) — renders cached content with an optional top `ProgressView` when `isRefreshing`.
- [`DebouncedTask`](flipflapp-ios/Core/Concurrency/DebouncedTask.swift) — reusable debounce for search fields (300 ms default).

### Examples

| Screen | Pattern |
|--------|---------|
| Events / Friends / Notifications | `load()` sets `.loading` only from `.idle`; `retry()` uses `isRefreshing` when content exists |
| Friend search | Separate `results` + `isSearching`; debounced query; per-row send button |
| Event details | Per-team join/leave locks; optimistic join with rollback |
| Invitation picker | `fetch()` keeps friend list visible; toolbar shows selection count while submitting |

## Composition over framework building

Use direct, readable feature code. Extract a reusable component when at least two real screens share semantics, not merely similar pixels. Add a package only when Apple frameworks or a small local type cannot meet the requirement safely.
