# Testing Strategy

Use a test pyramid: many fast unit tests, fewer API/integration tests, and a small set of critical UI journeys.

Apple recommends Swift Testing for new unit tests and XCTest/XCUIAutomation for UI and performance testing.

## Workflow

1. Describe observable behavior and edge cases.
2. Add the smallest failing test at the lowest useful layer.
3. Implement the behavior.
4. Refactor only with tests green.
5. Build and run targeted tests on a deterministic destination when approved.

## Unit tests: Swift Testing

Prioritize:

- successful and failing decoding fixtures;
- `Decimal` and date handling;
- HTTP status/error mapping;
- auth state restoration and invalidation;
- feature loading/empty/content/failure transitions;
- cancellation and stale-response suppression;
- friendship state actions;
- team slot/countable presentation;
- localization-independent formatting inputs;
- unknown notification payload behavior.

Use dependency injection and deterministic clocks/data. Avoid sleeps and live network calls.

## API integration tests

Test the client boundary with an injected transport or `URLProtocol` stub:

- method, path, headers, query, and body;
- bearer header injection/redaction;
- `200`/`201` decoding and `204` handling;
- Devise and application error envelopes;
- malformed JSON and unexpected content types;
- cancellation and timeout mapping.

Fixtures are synthetic and named by operation/status. Keep them aligned with OpenAPI examples or Rails request contracts.

## UI tests: XCTest

Cover only high-value journeys:

1. restore/sign in and reach authenticated root;
2. list and open an event;
3. join/switch/leave participation;
4. create an event and see it returned;
5. accept/decline a friendship request;
6. read notifications and sign out.

Launch with deterministic stub data/configuration. UI tests must not depend on production or shared mutable accounts.

## Accessibility verification

- Add accessibility identifiers only where UI tests need stable selection; identifiers are not user labels.
- Manually verify VoiceOver, large Dynamic Type, contrast, Reduce Motion, and keyboard behavior for material UI work.
- Use Xcode Accessibility Inspector where available.

## What not to test

- SwiftUI implementation details or private methods.
- Pixel snapshots as the only evidence of usability.
- Apple's framework behavior.
- The same domain invariant already enforced by Rails as independent client truth.
- Live production endpoints in the standard test suite.

## Completion evidence

Report the exact command, scheme, destination, and result. If tests or builds were not run, state that explicitly.

References:

- [Testing in Xcode](https://developer.apple.com/documentation/xcode/testing)
- [XCTest](https://developer.apple.com/documentation/xctest)
