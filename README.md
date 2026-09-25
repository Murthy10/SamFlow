# SamFlow

One goal. 25 minutes. A native macOS menu bar app.

```sh
make run     # build and launch
make test    # run the domain test suite
make help    # all targets
```

Requires macOS 15+ and Xcode 16. There is no `.xcodeproj` — open `Package.swift`
in Xcode if you want the IDE.

- `CLAUDE.md` — what the app is, the product rules, how to work on it.
- `docs/ARCHITECTURE.md` — layers, state machine, invariants, extension points.
