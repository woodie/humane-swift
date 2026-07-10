# Picking up humane-swift in a new Cowork session

Context for whoever opens this repo cold, with none of the prior conversation history.
Cross-project conventions (git locks, sandbox toolchain gaps, pushing, comments, code
style, test structure) are in `~/workspace/woodie/docs/COWORK.md`.

## What this is

The Swift sibling to `humane` (Go) and `humane-ruby`: `Humane.SizeFormatter` and
`Humane.TimeFormatter`, matching their API shape (a configurable formatter type with a
`string`-flavored method, not a bare helper function). Unlike the other two, there's no
math to port -- `ByteCountFormatter`/`RelativeDateTimeFormatter` are already exactly
right, since they're the reference implementation `humane`/`humane-ruby` were built to
match in the first place. This library is a thin wrapper, plus two small additive
options Foundation doesn't provide on its own.

## Why this exists

`zouk`'s `ScanEntry.timeAgo` had been hand-rolling a manual clamp on top of
`RelativeDateTimeFormatter` ("Emulate github.com/woodie/humane NewTimeFormatter
CollapseMinute") since before this repo existed -- and it had drifted: the comment said
it was emulating `humane`'s `CollapseMinute`, but used a 30-second threshold where
`humane`'s actual default is 60. Exactly the kind of independent-hand-rolled-fix drift
that `humane`/`humane-ruby` were created to eliminate for Go and Ruby, recurring a third
time in Swift, in miniature.

Separately, a real screenshot of `scandalous-web`'s scan listing (in the
["Humane, or how I learned to stop worrying and love Foundation"](https://johnwoodell.medium.com/humane-or-how-i-learned-to-stop-worrying-and-love-foundation-25024c3cb4d2)
writeup) showed ActionView's `"about 2 hours ago"` wording -- and for that
static, server-rendered listing, the "about" qualifier is genuinely better than exact
phrasing, precisely because the page can't refresh itself. That's the origin of
`humane-ruby#1` ("Provide ActionView compatibility mode"), which asked for
`distance_of_time_in_words`' full bucket table. The real need behind that issue isn't
ActionView-wording compatibility (which would reintroduce the "developer manually
prepends ago/in" burden `humane` was built to remove) -- it's that a consumer's ability
to live-refresh, not its platform or language, determines how much rounding its
display of relative time should tolerate. `zouk` itself can refresh live and doesn't
need it; `scandalous-web` can't and does.

Both of the above -- the drifted clamp and the "about" need -- got prototyped directly
in `zouk`'s `ScanEntry.timeAgo` first (see its own git history), then extracted here
once proven, the same sequence `humane`/`humane-ruby` went through relative to
`lambada`/`scandalous`.

## Naming

`includeSeconds` and `approximate` are meant to read as a "marriage" of Foundation and
ActionView vocabulary rather than new, invented concepts:

- **`includeSeconds`** replaces what would otherwise be called `collapseMinute` (the
  name used in `humane`/`humane-ruby` today). Reusing ActionView's own
  `include_seconds` name isn't just borrowing a word -- the polarities actually line
  up: `collapse_minute: true` (Ruby's default) suppresses seconds, identical in effect
  to `include_seconds: false` (Rails' default). They're exact inverses of the same
  concept, and the defaults invert to match, so `includeSeconds: false` here produces
  byte-identical behavior to `CollapseMinute`/`collapse_minute`'s existing default --
  this is a rename plus a default-value flip, not a new feature.
- **`approximate`** doesn't have as clean a precedent -- ActionView has no toggle for
  this at all (`distance_of_time_in_words` applies "about" unconditionally past its
  hour-ish boundary), and no Foundation vocabulary was found for it either. It's the
  one genuinely new term in this library rather than a borrowed one.

`humane`/`humane-ruby` still use `CollapseMinute`/`collapse_minute` as of this writing.
Renaming those to `IncludeSeconds`/`include_seconds` (with the accompanying default
flip) is deliberately deferred until after this package ships -- see "Next up".

## Design decisions

- **`SizeFormatter`**: a one-line passthrough to
  `ByteCountFormatter.string(fromByteCount:countStyle:.file)`. No `allowedUnits`/
  alternate `countStyle`s, matching the same "one style, the one anything here needs"
  scoping `humane`/`humane-ruby` already settled on.
- **`TimeFormatter`**: defaults (`includeSeconds: false, approximate: false`) match
  `RelativeDateTimeFormatter`'s raw output exactly -- per "By default, humane matches
  the Swift implementation," this type should require zero configuration to behave
  identically to calling Foundation directly.
- **`approximate`'s hour threshold**: "about" only kicks in once the bucket itself is
  coarse enough that the rounding it's hiding stops being visible -- nobody reads "3
  hours ago" as more precise than it is, but "47 minutes ago" reads as exact. An hour
  is where that stops holding. Day-and-larger buckets inherit "about" for free once
  their underlying delta crosses the hour mark; there's no separate day-level
  threshold.
- **Prefix insertion is string surgery, not reimplemented bucketing**: `approximate`
  prepends "about "/"in about " onto whatever `RelativeDateTimeFormatter` already
  returned, rather than recomputing the bucket text. English-only, and relies on
  Foundation's known `"in X"` prefix shape for future-dated output -- noted inline at
  the one spot it matters.
- **Zero-delta is forced past-tense**: `RelativeDateTimeFormatter` itself calls an
  exact-zero delta `"in 0 seconds"` (future-tense) rather than `"0 seconds ago"` --
  discovered via a real `swift test` failure, not by inspection. `humane`/`humane-ruby`
  both treat zero as non-future by construction (`seconds.negative?` is false at zero),
  so this type corrects Foundation's own zero-delta phrasing to match that convention
  rather than exposing the inconsistency.

## Sandbox limitation

No Swift toolchain in the Cowork sandbox (confirmed: no `swift` binary) -- same
situation as `humane`'s missing Go toolchain. Code here was written by inspection,
then confirmed for real via `swift test` on woodie's Mac -- that run caught the
zero-delta bug above and several wrong `SizeFormatter` fixture assumptions (see
"Current state"), exactly the category of mistake this workflow exists to catch.

## Current state

`Package.swift` (macOS 13+, matching `zouk`'s own platform target), `Sources/Humane/`
(`SizeFormatter`, `TimeFormatter`), `Tests/HumaneTests/` (Quick/Nimble specs), README,
and a GitHub Actions `ci.yml`. Confirmed via `swift test` on real hardware -- 28/28
passing (first run surfaced 5 failures, fixed in a follow-up commit; second run clean).
Tagged `v0.1.0` locally; not yet pushed.

That real run surfaced a genuine finding: `ByteCountFormatter`'s actual output diverges
from `humane`/`humane-ruby`'s hand-rolled 2-significant-digit algorithm in cases beyond
the two fixtures (`225_935`, `500_000`) their `docs/COWORK.md` explicitly says were
cross-checked against real hardware. Specifically: `0` bytes formats as `"Zero KB"`,
not `"0 B"`; byte-scale values spell out `"bytes"`, not `"B"` (`"7 bytes"`, not `"7
B"`); and GB-scale values can carry 2 decimal places, not 1 (`"5.24 GB"`, not `"5.2
GB"`, for `5_240_000_000`). `SizeFormatter` here is a direct passthrough to
`ByteCountFormatter`, so it's authoritative on these; `humane`/`humane-ruby`'s own
math isn't exhaustively Foundation-accurate outside their originally-checked range,
which undercuts their README's "corresponding functions in Swift will have consistent
output" claim for these specific shapes of input.

`zouk` has switched over: `Package.swift` depends on this repo via a local
`.package(path: "../humane-swift")` (deliberately not a version pin yet, since
`v0.1.0` isn't pushed), and `ScanEntry.humanSize`/`timeAgo(relativeTo:)` now call
`Humane.SizeFormatter`/`Humane.TimeFormatter(approximate: true)` instead of their old
hand-rolled versions -- see `zouk/docs/COWORK.md`, "adopted humane-swift" for that
side. Confirmed via a real `make test` on woodie's Mac -- 46/46 `zouk` specs passing,
including the 30-vs-60-second drift fix (no spec needed changing; nothing in the
existing fixtures landed in that gap). Not exercised against a live `lambada`
server -- woodie deliberately scoped this round to the automated suite, matching how
`zouk`'s own `docs/COWORK.md` already treats a green `make test` as sufficient for
most changes, reserving a live `make run` pass for cases that specifically call for
it.

`v0.1.0` is tagged, pushed, and released:
[github.com/woodie/humane-swift/releases/tag/v0.1.0](https://github.com/woodie/humane-swift/releases/tag/v0.1.0)
(via `gh release create v0.1.0 --title "v0.1.0" --notes-file docs/releases/v0.1.0.md`).
`zouk`'s `Package.swift` is pinned to it (`from: "0.1.0"`, no more local `path:`) --
not yet confirmed via `make test` against the real published package rather than the
local checkout that was actually tested.

## Next up

1. Confirm `zouk` still passes `make build`/`make test` now that it resolves
   `humane-swift` from GitHub instead of `path:`.
2. Circle back to `humane` and `humane-ruby`: rename `CollapseMinute`/
   `collapse_minute` to `IncludeSeconds`/`include_seconds` (breaking -- polarity
   inverts, needs a version bump and an upgrade note the way the `v0.2.0` wording
   change got one in both `docs/COWORK.md`), and decide whether `approximate` gets
   backported to those two as well.
4. Decide whether `humane`/`humane-ruby`'s `SizeFormatter` math is worth correcting
   toward exact `ByteCountFormatter` parity for the zero/byte-scale/GB-scale cases
   found above, or whether "2 significant digits, close enough" is an accepted,
   documented limitation -- currently neither repo's docs mention the gap.
5. Once (3) lands, `humane-ruby#1` ("Provide ActionView compatibility mode") can be
   closed with a pointer to `approximate` as the actual answer to what it was asking
   for.
