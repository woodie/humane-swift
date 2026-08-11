# Picking up humane-swift in a new Cowork session

Cross-project conventions (git locks, sandbox toolchain gaps, pushing, comments, code
style, test structure) are in `~/workspace/woodie/docs/COWORK.md`.

## What this is

The Swift sibling to `humane` (Go) and `humane-ruby`: same file-size/relative-date
formatting, matching macOS Finder's `ByteCountFormatter`/`RelativeDateTimeFormatter`
output plus an opt-in layer of ActionView-style vocabulary (`approximate`,
`includeSeconds`) on top. One `enum Humane` namespaces `humanSize`, `distanceInTime`,
and `timeAgo` (the last a one-argument convenience over `distanceInTime` supplying
`Date()`).

## Design decisions worth knowing

- **`humanSize` is a one-line `ByteCountFormatter` passthrough** -- no math to port,
  since Foundation is already the reference implementation the other two languages'
  hand-rolled rounding is built to match.
- **`distanceInTime`'s bucketing is hand-rolled, not `RelativeDateTimeFormatter`-
  derived.** `RelativeDateTimeFormatter`'s own rounding doesn't jump buckets early
  enough to match ActionView's `distance_of_time_in_words` table (44:30 for "about 1
  hour", 89:30 for "about 2 hours", etc.), so `Humane` computes `distanceInMinutes`
  directly and buckets by hand instead of string-surgering Foundation's output.
- **This package is the real-hardware reference for size-rounding**, not the other
  way around -- `humane`/`humane-ruby`'s own `humanSize`/`human_size` math was
  corrected to match findings from testing here (`"Zero KB"` for zero, spelled-out
  `"bytes"` below 1000, GB-scale values carrying 2 decimals). Any future rounding fix
  should start from a real `ByteCountFormatter` comparison here, then port to the
  other languages -- not the reverse.
- **CI-only Swift type-checker timeouts are a real, recurring risk** on dense Quick
  spec files (see `xctidy`'s own `docs/COWORK.md` for the same note) -- a local
  `swift test` pass does not guarantee CI's toolchain won't time out on the same
  code. `DistanceInTimeBoundarySpec.swift` is kept as its own file/`QuickSpec`
  subclass with precomputed integer literals for exactly this reason -- don't fold
  it back into a shared file without re-confirming CI stays green.
- **`whenNil` defaulting to `""` is the deliberate cross-language standard**, not
  a coincidence three of the four repos happened to share -- a cross-repo test
  comparison found `humane-ruby` alone defaulting `when_nil:` to `nil`, inherited
  from ActionView's own helper conventions rather than required by Ruby. Fixed
  there instead of changed here -- see `humane-ruby`'s own `docs/COWORK.md`
  ("Brought `when_nil` to parity").

## Testing

Quick/Nimble, `justBeforeEach` over inline setup (matches the rest of the family).
`TimeAgoSpec`/`DistanceInTimeSpec`/`DistanceInTimeBoundarySpec`/`HumanSizeSpec`.

## Sandbox limitation

No Swift toolchain here -- changes are written by inspection, verified via `swift
build`/`swift test`/`make check` on the user's own Mac. Real CI runs (not just a
local pass) are what caught the type-checker timeouts above -- treat a local-only
green run as provisional for large spec files.

## Current status

`v0.9.3`, adopted by `zouk`.

## Open items

**Verify `humanSize` rounding against real `ByteCountFormatter` output across a
wider range of magnitudes.** Only a handful of fixtures have been cross-checked on
real hardware so far; the 3-significant-figure rule in use reproduces all of them,
but is still an inference from a small set. `humane`/`humane-ruby`/`humane-kotlin`
all inherit whatever's confirmed here. Tracked in a GitHub issue on this repo (draft
handed off separately -- see chat).
