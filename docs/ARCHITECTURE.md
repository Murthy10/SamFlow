# Architecture

The goal of this document is to keep SamFlow small as it grows. It describes
where code goes, what it may depend on, and the invariants that must hold.

## Shape

Two targets, one dependency arrow:

```
┌──────────────────────────────────────────────────────┐
│  SamFlow  (executable)                               │
│  SwiftUI + AppKit. Renders phase, sends commands.    │
│                                                      │
│   MenuBar/        Focus/          History/           │
│   MenuBarLabel    GoalEntry       HistoryView        │
│   MenuBarContent  ActiveSession                      │
│                   Review                             │
│                                                      │
│   Support/  AppEnvironment · DesignTokens            │
└───────────────────────┬──────────────────────────────┘
                        │ depends on
                        ▼
┌──────────────────────────────────────────────────────┐
│  SamFlowKit  (library)                               │
│  Foundation only. No SwiftUI, no AppKit.             │
│                                                      │
│   Model/    FocusSession · SessionPhase · Formatting │
│   Session/  SessionController · Ticker               │
│   Store/    SessionStore · JSONFile · InMemory       │
└──────────────────────────────────────────────────────┘
```

**The dependency rule:** `SamFlowKit` never imports a UI framework, and never
learns about windows, menus, or notifications. It is buildable and testable with
no screen attached. If a change to `SamFlowKit` requires `import SwiftUI`, the
change is in the wrong target.

This is the whole architecture. Resist adding a third layer until there is a
second store, a second client, or a real networking concern — none of which v1
has.

## The state machine

`SessionPhase` is the spine of the app:

```
        start(goal:)
  idle ─────────────► running ──── clock hits 0 ───► review
   ▲                   │  ▲                            │
   │                   │  │ resume()                   │
   │            pause()│  │                            │
   │                   ▼  │                            │
   │                  paused                           │
   │                    │                              │
   └────────────────────┴──────────────────────────────┘
                 finish(outcome:)  → appends to store
```

Rules that must not break:

1. **Exactly one session exists at a time.** `start` from any phase but `idle`
   throws `sessionAlreadyRunning`.
2. **A session leaves the machine only through `finish`**, which is the only
   thing that writes to the store. There is no path from `review` to `idle` that
   skips recording an outcome.
3. **Every state the UI can show is a case of `SessionPhase`.** Views switch
   exhaustively over it and hold no session state of their own. If you find
   yourself adding `@State var isPaused` to a view, add a phase instead.
4. **`review` is a real phase, not a sheet.** Time-up is a state the app is in,
   so it survives the window being closed and reopened.

## How time works

Elapsed time is always `Date` arithmetic, never an accumulated counter:

```
focused(at: t)  = (t − startedAt) − pausedDuration − currentPauseSoFar
remaining(at: t) = max(0, plannedDuration − focused(at: t))
```

The `Ticker` exists only to tell the controller *when to recompute*. It is a
protocol with two implementations: `RunLoopTicker` (production, scheduled in
`.common` run loop mode so it keeps firing while the menu bar popover is being
tracked) and `ManualTicker` (tests, fired by hand).

Consequences worth keeping in mind:

- If the Mac sleeps for ten minutes mid-session, those ten minutes are gone from
  the clock when it wakes. That is intentional — wall-clock time passed.
- Dropped or delayed ticks cost display smoothness, never correctness.
- `remaining` is stored on the controller rather than computed on read, because
  `@Observable` can only notify SwiftUI about stored property changes.

## Data flow

One controller instance, created once in `SamFlowApp` via
`AppEnvironment.makeController()`, passed down to every view. Views read
`controller.phase` / `.remaining` / `.history` and call commands. There is no
other channel between surfaces — the menu bar and the focus window stay in sync
because they render the same object, not because they message each other.

Domain events travel back out through a single closure, `onTimeUp`, which
`AppEnvironment` sets. That is how the beep and window activation happen without
`SamFlowKit` knowing AppKit exists. Add further events the same way rather than
letting the domain reach for the platform.

## Startup parameters

`LaunchConfiguration.parse()` (`SamFlowKit/Session/LaunchConfiguration.swift`)
reads `--duration <minutes>` / `-d <minutes>` / `--duration=<minutes>` from
`CommandLine.arguments`, falling back to the `SAMFLOW_DURATION_MINUTES`
environment variable. `AppEnvironment.makeController()` is the only caller — it
resolves the value once, at launch, into `SessionController.defaultDuration`.

It is a pure function over `[String]` / `[String: String]`, not a `CommandLine`
call scattered into the app shell, so parsing is covered by the same fast
`SamFlowKit` test suite as everything else. A missing or invalid value is
ignored rather than rejected: a bad startup parameter must never stop the app
from launching. Follow this shape for the next startup parameter rather than
reaching for `ProcessInfo` directly from `AppEnvironment`.

The configured duration becomes `plannedDuration` on every `FocusSession`
started under it (via `SessionController.start`, which already threads a
duration override through), so it is persisted with the session and needs no
separate tracking in the store.

## Persistence

`SessionStore` is an append-only log: `load()` and `append(_:)`, nothing else.
`JSONFileSessionStore` writes the whole array to
`~/Library/Application Support/SamFlow/sessions.json` atomically on every append.

This is the right shape for hundreds of sessions a year and the wrong shape for
tens of thousands. The migration path, when it is needed, is a new `SessionStore`
implementation backed by SQLite or SwiftData — nothing above the protocol
changes. Do not pre-emptively adopt SwiftData for this; the file is inspectable,
diffable and trivially backed up, which is worth more right now.

Two failure decisions are already made: a store that cannot be created falls
back to `InMemorySessionStore` so a session can still run, and history that
cannot be read logs and yields an empty list. **A storage problem never blocks
starting a session.**

## Testing

`SamFlowKit` is tested with swift-testing (`swift test`). The controller takes
its clock and ticker as dependencies, so the suite drives the entire lifecycle —
countdown, pause accounting, time-up, persistence — in under a millisecond with
no real waiting.

Views are not unit-tested and should not be. Keeping views free of logic is what
makes that acceptable; the moment a view needs a test, the logic in it belongs in
`SamFlowKit`.

## Extension points

| Planned feature | Where it lands | What it must not do |
|---|---|---|
| Real notifications | `AppEnvironment.onTimeUp` | Add UserNotifications to `SamFlowKit` |
| Global hotkey | New file in `Support/`, calls `controller.start` | Bypass the state machine |
| Launch at login | `Support/`, `SMAppService` | Touch the domain at all |
| Stats over history | New type in `SamFlowKit/Model/`, pure function of `[FocusSession]` | Compute in a view |
| Per-session duration override | `SessionController.start(goal:duration:)` already exists; add UI for it | Add a picker to goal entry (product rule 3) |
| Distraction guard | Would need a new target; discuss before starting | — |

## Decisions on record

- **SPM + Makefile, no `.xcodeproj`.** Every project input stays plain text and
  diffable. Cost: the bundle is assembled by hand in the Makefile, and app icons
  and entitlements will need adding there when they arrive.
- **Ad-hoc code signing.** Fine for local development. Real notifications,
  sandboxing and distribution all need a Developer ID; that is a separate step.
- **`LSUIElement = true`.** No Dock icon or app switcher entry — the menu bar is
  the app. This is why `AppEnvironment.activate()` exists: an accessory app must
  explicitly pull itself forward when it opens a window.
- **Two windows, not one with navigation.** Focus and History are separate
  scenes so history can never appear during a running session.
