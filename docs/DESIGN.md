# Apple-Native Product Design

FlipFlapp should feel designed for iPhone, not like the Rails site translated pixel-for-pixel.

## Design principles

- **Hierarchy:** make the event, its time, location, availability, and primary action immediately clear.
- **Consistency:** use system navigation, controls, symbols, typography, materials, and feedback.
- **Focus:** each screen has one obvious primary purpose.
- **Context:** preserve scroll/navigation state and avoid disorienting full-screen replacements.
- **Accessibility:** build for diverse vision, mobility, cognition, and input needs from the first implementation.

Apple references:

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)

## Information architecture

Use a stable tab bar for top-level destinations, not actions. Keep tabs visible while navigating within a section and preserve each section's navigation state. Use a toolbar button or prominent content action for event creation.

Suggested tabs: Events, Friends, Notifications, Profile. Use short localized labels and familiar SF Symbols. Apply an unread badge only when it communicates meaningful new information.

## Screen patterns

### Events list

- Navigation title and native pull-to-refresh.
- Event rows prioritize title, localized date/time, location, availability, and privacy.
- A row navigates to details; creation is a separate toolbar/content action.
- Empty state explains why and offers event creation or refresh as appropriate.

### Event details

- Clear title, organizer, time, location, price, privacy, and capacity.
- Teams are grouped by immutable slot but display their current labels.
- Primary participation action reflects server state: join, switch, bench, or leave.
- Owner edit/delete controls are separated from participant actions.
- Destructive deletion uses a confirmation dialog with a specific consequence.

### Forms

- Use `Form`, sections, native pickers, toggles, date pickers, keyboard content types, and inline validation.
- Preserve entered values after recoverable server failures.
- Disable duplicate submission while submitting, but keep cancellation/navigation behavior intentional.
- Place field errors close to fields and provide a concise summary when multiple errors exist.

### Friends

- Preserve the four server buckets: accepted, sent, received, declined.
- Received requests expose accept and decline with unambiguous labels.
- Search communicates that email is not searchable.
- Declined state respects the receiver-only domain rule.

### Notifications

- Use readable semantic rows, not color alone, to distinguish unread state.
- Mark-as-read feedback is immediate but reconciled with server failure.
- Unknown payloads degrade gracefully.

## Visual system

- Use semantic colors (`primary`, `secondary`, `tint`, system backgrounds).
- Use Dynamic Type text styles instead of fixed font sizes.
- Use SF Symbols before custom icons.
- Use system spacing and container behavior; avoid hardcoded screen-width layouts.
- Support light/dark modes and increased contrast.
- Let current system materials and navigation appearance adapt; avoid recreating system chrome.
- Brand color may be the app tint, but never the only carrier of meaning.

## Accessibility acceptance criteria

- Default interactive targets are at least 44×44 pt; never below Apple's platform minimum.
- VoiceOver labels communicate purpose, value, and state without duplicating visible prose.
- Reading/focus order matches visual and task order.
- Dynamic Type works through accessibility sizes without clipping critical content.
- Color contrast remains sufficient and status is not encoded by color alone.
- Reduce Motion removes nonessential movement; Reduce Transparency remains legible.
- Gestures have visible control alternatives.
- Progress and important state changes are announced when needed, without noisy repeated announcements.
- French localization expansion does not truncate controls or rely on English word length.

## Feedback

- Use inline progress for scoped actions and content-preserving refresh.
- Use alerts for decisions or blocking failures, not routine success.
- Use haptics sparingly for meaningful completion or warning after the state actually changes.
- Errors explain what happened and the next available action: retry, edit, sign in, or dismiss.

## Design review

Review representative screens in:

- compact and regular width where supported;
- portrait and landscape when applicable;
- light/dark and increased contrast;
- default and largest accessibility text sizes;
- VoiceOver;
- loading, empty, populated, long-content, offline, `401`, `403`, `404`, and `422` states.
