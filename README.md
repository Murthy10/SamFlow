# SamFlow

**One goal. 25 minutes. Zero drift.**

SamFlow is a native macOS menu bar app for people who open a to-do list and
end up doing everything except the one thing on it. Click the icon, type the
one goal you're committing to, and a ring starts closing around it — visible
in the menu bar, traced in a shimmering border around every screen you touch,
impossible to quietly forget about. When the clock hits zero, SamFlow asks the
only question that matters: **did you reach it?** Your answer is the log.

No task lists. No projects. No streak-shaming. No account, no sync, no
telemetry — just you, one sentence of intent, and a countdown that means it.

```
[icon click] → "What is the one goal?" → 25:00 and closing → "Did you reach it?"
```

## Why SamFlow

Most focus timers time *work*. SamFlow times a **decision** — the one you
made when you typed the goal — and won't let the session end without
resolving it. That single constraint is the whole product:

- **One goal, always on screen.** No lists, no tags, no subtasks. If it
  needs a second concurrent goal, it doesn't belong here.
- **Starting costs one decision.** Type the goal, hit Start. No duration
  picker, no category, no estimate to fuss over — the popover opens right
  under the click, no separate window in the way.
- **The border doesn't let you forget.** A shimmering outline traces every
  screen while a session runs, filling in as time passes and pulling faster
  once you're under a minute — ambient enough to ignore, present enough to
  never truly lose track.
- **It always asks.** Time runs out or you bail early — either way, SamFlow
  makes you say `achieved` or `abandoned` before the session is allowed to
  close. That answer is the only data point that matters.
- **Never nags, never blocks.** No lockouts, no interruptions mid-session.
  It asks once, when time is actually up, and gets out of your way otherwise.
- **Local-only, forever.** Every session lands in one plain JSON file on
  your disk, grouped by day in a history window. No server has ever seen it.

## Quick start

```sh
make run                    # build the .app bundle and launch it
make run DURATION=45        # same, with a 45-minute session instead of 25
make test                   # run the SamFlowKit domain test suite
make help                   # every target
```

Requires **macOS 15+** and **Xcode 16** (Swift 6, strict concurrency
throughout). There's no `.xcodeproj` — the whole project is Swift Package
Manager plus a Makefile that assembles the app bundle, so every input stays
plain text. Open `Package.swift` directly in Xcode for previews and the
debugger.

## Under the hood

SamFlow is two targets and one dependency arrow: `SamFlowKit`, a pure
Foundation domain library with no SwiftUI or AppKit import, holding the
session state machine, time math, and the JSON store — and `SamFlow`, the
thin AppKit/SwiftUI shell that renders it. Elapsed time is always `Date`
arithmetic against `startedAt`, never a tick count, so a session survives the
Mac going to sleep mid-run.

- [`CLAUDE.md`](CLAUDE.md) — the product rules and how to work on the code.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — layers, the session state
  machine, and the invariants that keep it honest.
