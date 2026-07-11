# Picking up humane-swift in a new Cowork session

Context for whoever opens this repo cold, with none of the prior conversation history.
Cross-project conventions (git locks, sandbox toolchain gaps, pushing, comments, code
style, test structure) are in `~/workspace/woodie/docs/COWORK.md`.

## What this is

The Swift sibling to `humane` (Go) and `humane-ruby`: `Humane.SizeFormatter` and
`Humane.TimeFormatter`, matching their API shape (a configurable formatter type with a
`string`-flavored method, not a bare helper function). `SizeFormatter` has no math to
port -- `ByteCountFormatter` is already exactly right, since it's the reference
implementation `humane`/`humane-ruby` were built to match in the first place, and stays
a thin wrapper. `TimeFormatter` no longer is: once `approximate` needed to match
ActionView's exact bucket table (44:30/89:30/etc. cutoffs, see `humane-ruby` issue #1),
`RelativeDateTimeFormatter`'s own rounding stopped being close enough to build on top of
-- it doesn't jump buckets that early. `TimeFormatter` now computes `distanceInMinutes`
and buckets by hand, the same way `humane`/`humane-ruby` do, rather than delegating to
Foundation and string-surgering the result.

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

- **`string(at:relativeTo:)`**: additive alias for `string(for:relativeTo:)`, added once
  `humane`/`humane-ruby` picked up ActionView's `Approximate`/`approximate` and it became
  clear this family is no longer a pure Swift port -- it's its own thing with Foundation
  as the baseline, which made the one real naming mismatch between the three languages
  worth closing. `at` is canonical because it's the only name Ruby can actually use
  (`for` is a reserved word there); Swift keeps `for:` as its primary spelling since it
  matches `RelativeDateTimeFormatter` and this package's whole point is feeling native to
  Foundation. Go has no argument labels at all, so its side of this is just a parameter
  rename in the signature (`at`, cosmetic-only) -- see `humane`'s own `docs/COWORK.md`.

## Design decisions

- **`SizeFormatter`**: a one-line passthrough to
  `ByteCountFormatter.string(fromByteCount:countStyle:.file)`. No `allowedUnits`/
  alternate `countStyle`s, matching the same "one style, the one anything here needs"
  scoping `humane`/`humane-ruby` already settled on.
- **`TimeFormatter`**: defaults (`includeSeconds: false, approximate: false`) match
  `RelativeDateTimeFormatter`'s raw output exactly -- per "By default, humane matches
  the Swift implementation," this type should require zero configuration to behave
  identically to calling Foundation directly.
- **`approximate`'s buckets, revised**: originally "about" kicked in on any bucket of an
  hour or more (day-and-larger buckets inherited it for free once the delta crossed the
  hour mark). Revised to match ActionView's `distance_of_time_in_words` table exactly
  instead: "about" only decorates the 1-hour and 2..24-hour buckets, not the day bucket
  -- ActionView's own table has no "about 1 day". See `humane-ruby` issue #1 and
  `TimeFormatter.swift`'s doc comment for the full table (truncated at "1 day";
  week/month/year buckets are out of scope).
- **Bucketing is hand-rolled, not `RelativeDateTimeFormatter`-derived**: originally
  `approximate` did string surgery -- prepending "about "/"in about " onto whatever
  `RelativeDateTimeFormatter` returned, rather than recomputing the bucket text.
  That stopped working once `approximate` needed ActionView's specific early cutoffs
  (44:30 for "about 1 hour", 89:30 for "about 2 hours") -- Foundation's own rounding
  doesn't jump buckets that early, so there was no "about"-eligible bucket text to
  surgery onto in the first place. `TimeFormatter` now computes `distanceInMinutes`
  and switches on it directly, the same shape `humane`/`humane-ruby` use, dropping the
  `RelativeDateTimeFormatter` dependency for time formatting entirely.
- **Zero-delta, no longer a Foundation workaround**: `RelativeDateTimeFormatter` used to
  call an exact-zero delta `"in 0 seconds"` (future-tense) rather than `"0 seconds
  ago"` -- discovered via a real `swift test` failure, not by inspection, and corrected
  with an inline patch. Now that bucketing is hand-rolled and `future` is computed
  directly (`date > referenceDate`, false when equal), zero is past-tense by
  construction, matching `humane`/`humane-ruby`'s own approach
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
`zouk`'s `Package.swift` is pinned to it (`from: "0.1.0"`, no more local `path:`),
confirmed via a real `make build`/`make test` resolving the published package from
GitHub -- 46/46 pass, same as the `path:` version. This library's adoption story is
complete: scaffolded, tested, adopted by `zouk`, tagged, released, and re-confirmed
against the real published artifact.

`TimeFormatter` reworked to match ActionView's `distance_of_time_in_words` bucket table
exactly (see `humane-ruby` issue #1), through the "1 day" row -- `include_seconds`'s
collapse cutoff moved from 60s to 30s, and `approximate` narrowed from "any bucket >= 1
hour" to exactly the hour-scale buckets (1 hour, 2..24 hours), since ActionView's table
has no "about" on the day bucket. This required dropping `RelativeDateTimeFormatter` as
the bucketing source (see "Design decisions" above) -- `TimeFormatter` now computes
`distanceInMinutes` by hand, the same shape `humane`/`humane-ruby` use, both of which
picked up the identical table change in the same session. Confirmed for real via
`swift test` on woodie's Mac -- 35/35 passing, alongside `humane-ruby`'s (35/35) and
`humane`'s (36/36) identical changes in the same session.

`v0.3.0`: `TimeFormatter` gained `string(at:relativeTo:)` (additive alias for
`string(for:relativeTo:)` -- see "Naming" above) and `string(_:_:)` (fully
positional, no argument labels, matching `humane` (Go)'s label-free calling
convention). `SizeFormatter` gained the equivalent `string(_:)` positional
alias once a mocked-up three-language comparison surfaced it as the one
method still keyword-only after `TimeFormatter` got its aliases. Every
addition is a one-line forward to the existing implementation, not a
separate one. `humane-ruby`'s `#string` on both formatters picked up
equivalent positional-or-keyword support in the same session -- see
`docs/releases/v0.3.0.md`.

README also gained the `approximate: true` example (`"about 15 hours ago"`)
that `humane`'s and `humane-ruby`'s READMEs already had -- this README's
"Beyond Foundation's defaults" section listed the option but never showed it
actually triggering "about". 15 hours matches the other two languages'
existing example distance (already covered by real specs here); the
top-of-README 3-minute example is untouched -- it's correct as-is, since
ActionView's own table has no "about" below the hour bucket. The README also
now states explicitly the principle that's been guiding all of the above:
Foundation is the baseline every default matches exactly in all three
languages; ActionView's vocabulary is a layer on top of that baseline,
opt-in, never a replacement for it.

Written by inspection in the sandbox, then confirmed for real via `swift
test` on woodie's Mac -- 38/38 passing, including every alias/positional
case added this session. Tagged, pushed, and **released**:
[github.com/woodie/humane-swift/releases/tag/v0.3.0](https://github.com/woodie/humane-swift/releases/tag/v0.3.0)
(via `gh release create v0.3.0 --title "v0.3.0" --notes-file
docs/releases/v0.3.0.md`).

**CI found broken separately from the local `swift test` pass above**:
`ci.yml` (`swift build`/`swift test` on `macos-14`) has been red since the
`v0.2.0` commit -- confirmed via the actual GitHub Actions log woodie
pasted in, `error: the compiler is unable to type-check this expression in
reasonable time`, pointed at `TimeFormatterSpec.swift`'s single outer
`describe("TimeFormatter") { ... }` wrapping everything. Not a real test
failure and not something introduced this session (`v0.2.0`'s own CI run
is red too) -- a local `swift test` on a fast Mac can still pass while the
CI runner's type checker times out on the same giant nested-closure
expression. Fixed by splitting `TimeFormatterSpec` into multiple sibling
top-level `describe`s -- see `docs/COMMENTS.md`. Confirmed via a real
`swift test` on woodie's Mac -- 38/38 passing, same count and behavior as
before the split.

`ci.yml` briefly also gained `-Xswiftc -solver-expression-time-limit=600`
as a margin of safety, added and reverted in the same session: it's a
frontend-only flag, and passing it bare through `-Xswiftc` (instead of
threaded as `-Xswiftc -Xfrontend -Xswiftc -solver-expression-time-limit=600`)
produced `error: unknown argument: '-solver-expression-time-limit=600'` on
CI's real Xcode 15.4/Swift 5.10 toolchain -- a genuine CI break introduced
by this session's own fix attempt, caught via the real CI log, not the
original type-checker problem. Removed rather than fixed, since the
describe split is the real fix and doesn't need a compiler-flag hedge that
can't be verified in this sandbox. `ci.yml` is back to plain `swift build
-v`/`swift test -v`.

Pushing the flag revert got a second real CI log: the file-level split fixed
every block except the boundary-table one, which timed out on its own,
pointed at `describe("...bucket table boundaries")` specifically -- real
progress (one block, not the whole file), and confirmation that this is
genuinely a per-expression density problem, not something that clears up on
its own from regrouping alone. That block's `it`s each packed a `Date`
computation and two `expect(...).to(equal(...))` calls into one line.
Fixed by doing what the compiler's own error suggests -- pulling each
`Date` computation into a type-annotated `let` before the `expect` calls --
and splitting its two `context`s into their own top-level `describe`s, same
as the rest of the file. Same 7 `it` cases, same assertions.

**Still unconfirmed on the actual CI runner** -- this second-round fix has
only been reasoned through by inspection so far (no Swift toolchain in this
sandbox); needs a real `swift test` and a green Actions run before it's
trusted, same bar as everything else here. Two real CI logs in a row have
each caught something a local pass alone wouldn't have.

## Next up

1. Confirm the second-round `TimeFormatterSpec` fix (extracted `let`s +
   the boundary-table block split in two) actually turns CI green -- a
   third real CI log, this time hopefully clean. `swift test` passing
   locally doesn't by itself prove this, per the exact local-vs-CI
   divergence that caused the original problem.
2. `CollapseMinute`/`collapse_minute` -> `IncludeSeconds`/`include_seconds` in
   `humane`/`humane-ruby` (this repo's own `v0.1.0` motivation for the
   rename) is done -- both shipped it in their own `v0.3.0`s. `approximate`
   backported to both as well, in their `v0.4.0`s. Nothing left open here.
3. Decide whether `humane`/`humane-ruby`'s `SizeFormatter` math is worth correcting
   toward exact `ByteCountFormatter` parity for the zero/byte-scale/GB-scale cases
   found above, or whether "2 significant digits, close enough" is an accepted,
   documented limitation -- currently neither repo's docs mention the gap.
4. Once (2) lands, `humane-ruby#1` ("Provide ActionView compatibility mode") can be
   closed with a pointer to `approximate` as the actual answer to what it was asking
   for.
