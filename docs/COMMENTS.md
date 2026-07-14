# Comments

Rationale, history, and design notes that used to live as multi-line
comments in the source. Organized by file, then by the type, property, or
function each note is attached to. The source itself now carries at most
one short line at any given spot -- anything longer that would previously
have been a doc comment lives here instead. See `humane`/`humane-ruby`'s
own `docs/COMMENTS.md` for the pattern this follows.

## Tests/HumaneTests/DistanceInTimeSpec.swift (formerly TimeFormatterSpec.swift, renamed in v0.9.3)

### Top-level structure
Split into multiple sibling top-level `describe` calls instead of one
`describe("TimeFormatter") { ... }` wrapping everything, after CI started
failing with `error: the compiler is unable to type-check this expression
in reasonable time; try breaking up the expression into distinct
sub-expressions` pointed at the outer describe's opening line. Confirmed via
the real GitHub Actions log (`swift build -v`/`swift test -v` on
`macos-14`) -- CI had been red since the `v0.2.0` commit (the one that added
the boundary-table `describe`), not something introduced by this session's
additions, though the two new alias describes likely pushed it further
over. Each top-level `describe` now repeats its own `base`/`beforeEach`
since Quick doesn't share state across sibling top-level describes -- a
small amount of duplication traded for the compiler actually being able to
type-check each block independently.

`ci.yml` briefly gained `-Xswiftc -solver-expression-time-limit=600` on
`swift build`/`swift test` as a hedge, then had it reverted in the same
session: `-solver-expression-time-limit` is a frontend-only flag, so passing
it bare through `-Xswiftc` (rather than threaded as `-Xswiftc -Xfrontend
-Xswiftc -solver-expression-time-limit=600`) produces `error: unknown
argument`, which broke the build *before* it ever reached the test file --
confirmed via a real CI log. Removed rather than re-attempted, since it
couldn't be verified in this sandbox (no Swift toolchain) and the describe
split above is the real fix on its own merits.

The first round of splitting fixed every block except the boundary-table
one -- confirmed via a second real CI log, same error, now pointing at
`describe("...bucket table boundaries")` specifically (down from the whole
file). That block's `it`s each packed a `Date` computation and two
`expect(...).to(equal(...))` calls using it into one line
(`expect(formatter.string(for: base.addingTimeInterval(-(44 * 60 + 29)),
relativeTo: base)).to(equal("44 minutes ago"))`) -- dense even after the
file-level split. Fixed by doing what the compiler's own error message
says: pulling each `Date` computation out into a type-annotated `let`
before the `expect` calls, plus splitting the block's two contexts
("without approximate" / "with approximate: true") into their own
top-level describes rather than nested `context`s under a shared one.
Same 7 `it` cases (5 + 2), same assertions, same behavior.

That round-2 fix still failed on CI, on the exact same two describes --
confirmed via a third real CI log. The remaining common factor: this was
the only block in the file where a single `it` made *two*
`expect(formatter.string(...)).to(equal(...))` calls back to back; every
other block already had one assertion per `it`. `TimeFormatter.string` also
gained two new overloads this session (`at:relativeTo:`, `_:_:`), so
`formatter.string(for:relativeTo:)` now has three candidates to resolve
inside Nimble's generic `equal` machinery -- plausibly expensive enough,
twice per closure, to be the actual trigger, even though the file otherwise
type-checks fine with those same three overloads in play everywhere else
(where each `it` only calls `.string` once). Fixed by resolving each
`.string(...)` call to a concrete, type-annotated `let result: String`
*before* handing it to `expect`, and splitting every two-assertion `it`
into two one-assertion `it`s, matching the rest of the file. 14 `it` cases
now (was 7) -- more granular, same coverage, same cutoffs asserted.

Round 3 *also* failed on CI, on the exact same two describes, at the exact
same line numbers -- a fourth real CI log. The tell: within-file
restructuring (regrouping describes, extracting lets, reducing assertions
per `it`) wasn't going to fix this no matter how it was sliced, since every
variant tried still put all of this content inside the same `describe`
closure in the same file. Moved to its own file/QuickSpec subclass entirely
-- see `DistanceInTimeBoundarySpec.swift` (formerly `TimeFormatterBoundarySpec.swift`,
renamed in v0.9.3) -- a stronger form of isolation
than another describe split. Also replaced the compound arithmetic
(`44 * 60 + 29`) with precomputed integer literals (`-2669`, comment shows
the derivation), removing another layer of inline expression complexity on
top of the file split, since three prior guesses about which specific
factor mattered had each turned out wrong on the real CI runner.

## Sources/Humane/Humane.swift (formerly SizeFormatter.swift + TimeFormatter.swift, merged in v0.9.3)

### `Humane.humanSize` (formerly `SizeFormatter.humanSize`)
`v0.9.0` drops the instantiated-formatter shape (`SizeFormatter().string(
fromByteCount:)`) for a static function on a case-less enum used purely as
a namespace -- see `docs/COWORK.md`'s `v0.9.0` entry for the full
cross-repo rationale. `v0.9.3` collapses that enum (and `TimeFormatter`,
below) into one `Humane` enum -- see `docs/COWORK.md`'s `v0.9.3` entry. The
implementation itself is unchanged throughout: still a one-line passthrough
to `ByteCountFormatter`, still the authoritative reference
`humane`/`humane-ruby`'s hand-rolled math is checked against, since
Foundation already gets this right for free and there's no reason to
duplicate it here the way those two languages have to.

### `Humane.distanceInTime` (formerly `TimeFormatter.timeAgo`, renamed in v0.9.3)
`v0.9.0` drops the instantiated-formatter shape (`TimeFormatter(approximate:
true).string(for:relativeTo:)`) for a static function on a case-less enum,
matching the `SizeFormatter` change above and `humane`/`humane-ruby`'s
equivalent moves in the same session -- each language keeps its own
idiomatic casing for the shared concept (`timeAgo` here, `TimeAgo` in Go,
`time_ago` in Ruby) rather than one literal spelling. Configuration moves
from initializer parameters to call-site parameters; Swift's native
default parameter values make this a plain signature change; no `TimeOptions`
struct is needed the way Go's zero-value semantics required (see `humane`'s
own `docs/COMMENTS.md`). `v0.9.3` renames this function `distanceInTime` and
adds a separate one-argument `Humane.timeAgo` convenience wrapping it with
`Date()` -- see that entry below and `docs/COWORK.md`'s `v0.9.3` entry for
why (the ActionView `distance_of_time_in_words`/`time_ago_in_words` naming
pair). Everything in this entry and the ones below it describes behavior
that now lives under `distanceInTime`, not `timeAgo`.

### `approximate` default flips `false` -> `true`
Matches ActionView's own `distance_of_time_in_words` (which has no toggle
for this at all -- always on past the hour boundary), and, checked against
real code, matches what `zouk`'s `ScanEntry.swift` already passed
explicitly (`Humane.TimeFormatter(approximate: true)`). Zero behavior
change for the one real Swift consumer; removes required boilerplate at
the call site instead. `includeSeconds` stays `false` by default,
unchanged.

### `whenNil`
Added in `v0.9.0` alongside `timeAgo` accepting `Date?` instead of `Date`.
Motivated directly by `zouk`'s own `ScanEntry.timeAgo(relativeTo:)`, which
used to guard a possibly-unparsable `downloadedAt` itself
(`guard let downloadedAt else { return nil }`) and hand the caller a
`String?` that still needed its own `?? "an unknown time"` fallback one
layer up in `ScanGridView` -- two guard points for one final string.
`timeAgo` now takes the optional directly and a caller-supplied fallback
string, collapsing both guard points into one call -- once `zouk` adopts
this, `ScanEntry.timeAgo`'s wrapper can likely be removed entirely in
favor of calling `Humane.timeAgo` straight from the view (`v0.9.3` renamed
the qualifying type from `TimeFormatter` to `Humane` -- see above).
The fallback text stays app-specific (an empty default, not a hardcoded
string baked into this package), matching how `approximate`/
`includeSeconds` are already opt-in rather than assumed.

### `distanceInTime`'s `includeSeconds` (formerly `TimeFormatter.includeSeconds`)
Under 30 seconds (not 60), collapses to "less than a minute ago"/"in less
than a minute" instead of counting seconds -- matching the first row of
ActionView's `distance_of_time_in_words` bucket table (see `string`
below), not an arbitrary round number.

### `distanceInTime`'s `approximate` (formerly `TimeFormatter.approximate`)
Prefixes "about"/"in about" onto exactly the hour-scale buckets (1 hour,
and 2..24 hours) -- matching ActionView's `distance_of_time_in_words`
wording for those buckets, and no others. An earlier version prefixed
"about" onto any bucket of an hour or larger, which also caught whole-day
deltas; ActionView's own table has no "about 1 day" (or week/month/year
buckets, out of scope here), so this was narrowed to match. See
[humane-ruby issue #1](https://github.com/woodie/humane-ruby/issues/1)
for the source table.

Used to be string surgery on top of whatever `RelativeDateTimeFormatter`
returned. That stopped working once `approximate` needed ActionView's
specific early cutoffs (44:30 for "about 1 hour", 89:30 for "about 2
hours") -- Foundation's own rounding doesn't jump buckets that early, so
there was no "about"-eligible bucket text to surgery onto. See `string`
below for what replaced it.

### `distanceInTime`'s bucketing (formerly `TimeFormatter.timeAgo`)
Buckets are chosen from `distanceInMinutes` (seconds/60, rounded once via
`Double.rounded()`), not by re-dividing raw seconds independently per
unit, and not by delegating to `RelativeDateTimeFormatter`'s own rounding
-- neither hits the specific cutoffs ActionView's table requires. Dividing
raw seconds per unit independently also let rounding carry across a
bucket boundary on its own (`59:59:59`, under an hour, used to round to
"60 minutes ago" instead of "1 hour ago" under the old per-unit approach).
Computing `distanceInMinutes` once and switching on *that* is exactly how
ActionView's own `distance_of_time_in_words` works, and is what produces
its non-obvious cutoffs: the "about 1 hour" bucket starts at 44 minutes
30 seconds (not 60:00), and "about 2 hours" starts at 89:30, not 90:00.
This is the same algorithm `humane`/`humane-ruby` use; the table is
truncated at the "1 day" row across all three (week/month/year buckets
are out of scope -- see "Scope" in README.md).

`RelativeDateTimeFormatter` is no longer used here at all -- it once
supplied the base phrase (with `approximate` string-surgeried on top) and
needed an inline correction for its own exact-zero-delta quirk (calling
it `"in 0 seconds"`, future-tense, rather than `"0 seconds ago"`). Now
that `future` is computed directly (`at > relativeTo`, false when equal)
and bucketing is hand-rolled, zero is past-tense by construction and that
correction no longer applies.

`v0.9.0` dropped the `for:relativeTo:` / `at:relativeTo:` / `string(_:_:)`
trio of labeled and positional overloads down to one static function with
two positional parameters and three defaulted keyword options
(`approximate:`, `includeSeconds:`, `whenNil:`) -- see the top-level
`Humane.distanceInTime` entry above. `for`/`at` existed specifically to
bridge Swift's `RelativeDateTimeFormatter`-style label and the `at` every
other language in the family was forced into (Ruby's `for` is a reserved
word); once this package stopped mirroring `RelativeDateTimeFormatter`'s
API shape at all, maintaining both spellings stopped earning its keep.

    distanceInTime(t, t)                               == "less than a minute ago"
    distanceInTime(t.addingTimeInterval(-45), t)        == "1 minute ago"
    distanceInTime(t.addingTimeInterval(-15 * 3600), t) == "about 15 hours ago"
    distanceInTime(t.addingTimeInterval(-30 * 3600), t) == "1 day ago"  // no "about" -- ActionView's table has none on the day bucket
    distanceInTime(nil, t, whenNil: "an unknown time")  == "an unknown time"

### `Humane.timeAgo` (new in v0.9.3)
A one-argument convenience over `distanceInTime`, supplying `Date()` as
`relativeTo` -- see `docs/COWORK.md`'s `v0.9.3` entry for why (the
ActionView `distance_of_time_in_words`/`time_ago_in_words` naming pair this
mirrors). Thin passthrough, no bucketing logic of its own; `TimeAgoSpec.swift`
covers it with three cases rather than re-testing everything above.
