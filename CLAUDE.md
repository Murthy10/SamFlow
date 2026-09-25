# SamFlow

A native macOS app for achieving **one** goal in **25 minutes**.

## The product in one paragraph

You name a single goal, you get 25 minutes, and at the end you say whether you
reached it. That is the whole app. It lives in the menu bar so starting a session
costs one click, and it keeps the goal visible while the clock runs, because the
point is not to time work — it is to stop you drifting away from the one thing
you said you would do. Every finished session is written to a local log with its
outcome, so the app can eventually tell you something true about how you work.

## Product rules

These are decisions, not preferences. Changing one is a product change, not a
refactor — say so explicitly if you are about to.

1. **One goal.** There is no list, no subtasks, no tags, no projects. If a
   feature needs a second concurrent goal, it does not belong in SamFlow.
2. **The goal stays on screen.** During a running session the goal text is
   always visible in the focus window and in the menu bar popover.
3. **Starting is one decision.** Goal entry asks for the goal and nothing else.
   No duration picker, no category, no estimate on the entry screen.
4. **The session always ends with an answer.** When the clock runs out the app
   asks "did you reach it?" and does not record the session until answered.
   Sessions the user ends early still get an outcome (`achieved` / `abandoned`).
5. **Never nag, never block.** The app does not lock you out of anything, and it
   does not interrupt except once, when time is up.
6. **Local only.** No account, no sync, no network. The log is a JSON file the
   user owns.

## State of the build

Working today (v1 scope):

- Menu bar item showing a live countdown, with a popover for pause/resume/done.
- Focus window covering the three steps: goal entry → running session → review.
- Session log persisted to `~/Library/Application Support/SamFlow/sessions.json`,
  shown newest-first in a History window, each row showing its configured
  duration alongside the goal.
- Session length configurable at launch (`--duration <minutes>` or
  `SAMFLOW_DURATION_MINUTES`), defaulting to 25. See `make run DURATION=45`
  below. The chosen duration is recorded on every session it produces.

Deliberately **not** built yet, in rough priority order:

- Time-up notification via `UserNotifications` (currently just `NSSound.beep()`
  plus activating the app — real notifications need a signed bundle).
- Global hotkey to start a session from any app; launch at login.
- Anything derived from history (streaks, achieved rate, time-of-day patterns).
- Distraction guard. Explicitly deferred: it needs Accessibility permissions and
  would change the app from "keeps you pointed at the goal" to "polices you".

## Working on this codebase

```sh
make run                    # build the .app bundle and run it with logs in the terminal
make run DURATION=45        # same, with a 45-minute default instead of 25
make launch                 # same as run, but detached via LaunchServices
make test                   # swift test — the SamFlowKit suite
make app                    # assemble .build/SamFlow.app without launching
make clean
```

The app **must** run from the assembled `.app` bundle, not the bare executable —
`MenuBarExtra`, `LSUIElement` and the bundle identifier all depend on it. `make
run` handles that; it kills any running instance first.

There is no `.xcodeproj`. The project is Swift Package Manager plus a Makefile
that assembles the bundle, so every input is plain text. To use Xcode, open
`Package.swift` directly — previews and the debugger work from there.

### Conventions

- **Swift 6 language mode, strict concurrency.** The whole app is `@MainActor`
  except the store, which is `Sendable`. Do not silence a concurrency error with
  `@unchecked Sendable` outside test doubles.
- **Put logic in `SamFlowKit`, not in views.** If a rule can be stated without
  mentioning a button, it belongs in the domain target, where it can be tested.
  A view that computes anything about time or outcomes is a smell.
- **Never derive elapsed time by counting ticks.** Time comes from `Date`
  arithmetic against `startedAt`; the ticker only says when to look. This is what
  makes a session survive the machine sleeping.
- **No hardcoded spacing or fonts in views.** Use `Token` in `DesignTokens.swift`.
- **Tests use `ManualTicker` and an injected clock.** No test may wait on real
  time. If you need a new kind of time behavior, extend the fake, do not sleep.
- Targets: macOS 15. The installed SDK is 15.5, so macOS 26-only APIs will not
  compile even though the machine runs macOS 26.

### Where things live

| You want to change... | Go to |
|---|---|
| What a session *is*, or how time is computed | `Sources/SamFlowKit/Model/` |
| What the app can do and when | `Sources/SamFlowKit/Session/SessionController.swift` |
| How sessions are stored | `Sources/SamFlowKit/Store/` |
| The menu bar item and its popover | `Sources/SamFlow/MenuBar/` |
| The three focus-window steps | `Sources/SamFlow/Focus/` |
| Platform glue (notifications, activation, wiring) | `Sources/SamFlow/Support/AppEnvironment.swift` |

Read `docs/ARCHITECTURE.md` before adding a feature — it states the dependency
rule and the invariants that keep the state machine honest.
