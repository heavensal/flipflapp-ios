# Mobile Domain Guide

This document translates the Rails MVP into iOS concepts. It does not replace the authoritative Rails domain document at `../../flipflapp-rails/docs/DOMAIN.md`.

## Shared vocabulary

Keep backend resource names in API and domain code:

`User`, `Event`, `EventTeam`, `EventParticipant`, `Friendship`, `Invitation`, and `Notification`.

Do not invent parallel API nouns such as `Match`, `Team`, `Player`, `Invitee`, or `Auth` when they obscure the server contract. UI copy may use natural French terms.

## User and session

- Every authenticated `User` is a player and may organize events.
- Email/password authentication uses a bearer JWT returned in the sign-in response `Authorization` header.
- The app stores only the session token in Keychain. Passwords are never persisted.
- A `401` ends the authenticated session unless the operation is sign-in itself.
- Public user profiles exclude email and role; current-user responses include them.

## Event visibility

The server determines which events are visible. A private event can be visible because the current user is:

- its author;
- an accepted friend of its author;
- already an `EventParticipant`; or
- invited.

The client must not infer access by filtering a broader dataset. Treat `404` as both missing and intentionally not viewable.

## Event ownership

- Any authenticated user can create an event.
- Only `event.user` can update or delete it.
- Use the `current_user.author` field from the event response to drive owner controls.
- Hiding a control is UX, not authorization.

## Teams and participation

Each event has exactly three immutable `EventTeam.slot` values:

| Slot | Counts toward capacity | Renameable |
|---|---:|---:|
| `team_one` | Yes | Yes, by an event participant |
| `team_two` | Yes | Yes, by an event participant |
| `bench` | No | No |

- `label` is display text; `slot` drives behavior.
- Joining creates an `EventParticipant`; selecting another team for an existing participation moves it.
- A countable team can be full while bench remains joinable.
- The app must present server validation failures instead of optimistically overriding capacity.
- Leaving deletes only the current user's participation.

## Invitations

- Any event participant may invite accepted friends who are neither participants nor already invited.
- Invitations have no accepted/declined state. They exist until the user joins or the event is deleted.
- The invite picker is derived from accepted friendships minus existing participants/invitations.
- The server validates eligibility; an empty eligible set is a recoverable `422`.

## Friendship lifecycle

| Current state | Actor | Allowed action | Result |
|---|---|---|---|
| none | either user | send | `pending` |
| `pending` | receiver | accept | `accepted` |
| `pending` | receiver | decline | `declined` |
| `pending` | sender | cancel | deleted |
| `accepted` | either user | unfriend | deleted |
| `declined` | receiver | remove | deleted |

- A declined request is visible only to its receiver.
- The sender sees it disappear but cannot send another request until the receiver removes it.
- Search excludes self and every user with any existing friendship state.
- Do not expose email as a friendship-search field.

## Notifications

- Inbox excludes `friendship_requested` notifications.
- The server returns at most 20 recent inbox items.
- Kinds are `updated`, `canceled`, `reminder`, `joined`, `left`, `invited`, and `friendship_requested`.
- Payload is extensible JSON. Unknown fields must not break decoding.
- Unknown future notification kinds should degrade to a safe generic presentation when the generated/API model permits it; never crash.
- Mark-read and deletion are server operations, not local-only flags.

## Money, dates, and location

- Use `Decimal` for event price and format it as currency only in the presentation layer.
- Treat API timestamps as absolute instants; format them using the user's locale and time zone.
- Event creation requires title, location, future start time, positive capacity, nonnegative whole-euro price, latitude, and longitude.
- Coordinates are transport/domain data, not localized strings.

## Client state principles

- Server state is authoritative after every mutation.
- Optimistic UI is allowed only when rollback is deterministic and accessibility feedback remains clear.
- Prefer replacing a mutated resource with the response body over duplicating mutation rules locally.
- Empty, missing, forbidden, validation, authentication, decoding, connectivity, timeout, and cancellation are distinct states.
