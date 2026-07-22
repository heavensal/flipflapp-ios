# Swift Style Guide

Default to the current Swift API Design Guidelines and nearby repository patterns, with the rules below as project-specific constraints.

## Language and naming

- Code and technical documentation are English.
- Types and protocols use `UpperCamelCase`; members use `lowerCamelCase`.
- Name operations for intent: `loadEvents()`, `join(event:teamID:)`, `markAllNotificationsRead()`.
- Avoid generic project nouns such as `Manager`, `Helper`, `Utils`, `Handler`, or `Service` unless the type's role is genuinely that broad and precise.
- Protocols describe capability (`TokenStoring`) only when that reads naturally; concrete boundary names such as `APIClient` are acceptable.

## Types

- Prefer `struct` and `enum`; use classes for identity/observation/shared mutable state.
- Prefer `let`; narrow mutation scope.
- Use exhaustive enums for finite UI state.
- Use `Decimal` for money, `Date` for instants, and `URL` for URLs.
- Prefer typed identifiers at feature boundaries when mixing IDs would be dangerous.
- Avoid `[String: Any]` except at unavoidable platform boundaries; notification payloads need a documented representation.

## Safety

- No force unwrap, `try!`, production `fatalError`, or empty catch blocks.
- Convert programmer assumptions into initializers or validated types.
- Preserve underlying errors for diagnostics while mapping them to stable app errors.
- Never use errors as normal view-state flags without retaining recovery context.

## SwiftUI

- Keep `body` declarative and free of side effects.
- Extract meaningful subviews, not every stack.
- Use semantic system styles and environment values.
- Avoid `AnyView` unless type erasure is required at a real boundary.
- Do not initialize long-lived observable objects repeatedly from `body`.
- Use `.task(id:)` when work follows view identity and should cancel automatically.
- Buttons represent actions; `NavigationLink` represents navigation.
- Prefer `ContentUnavailableView`, `LabeledContent`, `Form`, `List`, `Section`, `ToolbarItem`, and other semantic components when they fit.

## Concurrency

- Prefer structured concurrency.
- Mark UI feature models `@MainActor` rather than wrapping every assignment in `MainActor.run`.
- Do not detach tasks unless actor inheritance is specifically undesirable and the lifetime is independently owned.
- Check cancellation before publishing stale results.
- Avoid callbacks and Combine for APIs that have a clear `async` equivalent.

## API code

- One shared response-validation/error-mapping path.
- No request construction in views.
- No endpoint strings outside the API layer or generated client.
- Use injected `URLSession`/transport for testability.
- Redact headers and bodies in diagnostics.
- Keep generated OpenAPI code separate and never hand-edit it.

## Formatting and files

- Use Xcode/Swift standard formatting; adopt `swift-format` only after explicit tooling approval.
- One primary type per file when it improves discoverability; small private support types may stay nearby.
- Use extensions to group protocol conformances or focused behavior.
- Keep public/internal surface minimal; default to `private` for implementation details.
- Imports are minimal and sorted by formatter behavior.

## Documentation

- Public or non-obvious APIs document invariants, ownership, actor isolation, and failure behavior.
- Do not narrate obvious code.
- `TODO` includes a reason or tracked decision; never leave speculative architecture markers.

## Review checklist

- Domain terms match Rails/OpenAPI.
- UI state is explicit and race-free.
- Cancellation and repeated user actions are safe.
- Errors are mapped once and recovery is visible.
- Sensitive values cannot reach logs or preferences.
- Dynamic Type, VoiceOver, contrast, motion, dark mode, and localization were considered.
- Tests exercise behavior rather than private implementation details.
