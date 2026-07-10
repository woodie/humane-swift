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

## Sandbox limitation

No Swift toolchain in the Cowork sandbox (confirmed: no `swift` binary) -- same
situation as `humane`'s missing Go toolchain. Code here was written by inspection;
still needs `swift build`/`swift test` run for real on a Mac before it's trusted,
including the `Quick`/`Nimble` specs (mirroring `zouk`'s own test setup and the
describe/context/it structure documented in the cross-project conventions doc).

## Current state

`Package.swift` (macOS 13+, matching `zouk`'s own platform target), `Sources/Humane/`
(`SizeFormatter`, `TimeFormatter`), `Tests/HumaneTests/` (Quick/Nimble specs -- the
`SizeFormatter` fixtures are the same byte counts already validated against real
`ByteCountFormatter` output in `humane-ruby`'s spec suite; the `TimeFormatter` fixtures
share the same base timestamp and deltas as `humane-ruby`'s spec for cross-language
parity), README, and a GitHub Actions `ci.yml`. Not yet built, tested, tagged, or
published.

`zouk`'s `ScanEntry.timeAgo` already has its own hand-rolled version of both
`includeSeconds`-equivalent and `approximate`-equivalent behavior (with the 30-second
threshold noted above under "Why this exists") -- it hasn't been switched over to
depend on this package yet.

## Next up

1. Confirm on real hardware (`swift build`, `swift test`), tag and push `v0.1.0`.
2. Point `zouk`'s `Package.swift` at this repo (a branch/local `path:` dependency
   first, then a version pin once tagged -- the same bridge `humane-ruby` used into
   `scandalous`) and replace `ScanEntry`'s hand-rolled `humanSize`/`timeAgo` with calls
   into `Humane.SizeFormatter`/`Humane.TimeFormatter(approximate: true)`, fixing the
   30-vs-60-second drift in the process.
3. Circle back to `humane` and `humane-ruby`: rename `CollapseMinute`/
   `collapse_minute` to `IncludeSeconds`/`include_seconds` (breaking -- polarity
   inverts, needs a version bump and an upgrade note the way the `v0.2.0` wording
   change got one in both `docs/COWORK.md`), and decide whether `approximate` gets
   backported to those two as well.
4. Once (3) lands, `humane-ruby#1` ("Provide ActionView compatibility mode") can be
   closed with a pointer to `approximate` as the actual answer to what it was asking
   for.
