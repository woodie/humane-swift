# Comments

Rationale, history, and design notes that used to live as multi-line
comments in the source. Organized by file, then by the type, property, or
function each note is attached to. The source itself now carries at most
one short line at any given spot -- anything longer that would previously
have been a doc comment lives here instead. See `humane`/`humane-ruby`'s
own `docs/COMMENTS.md` for the pattern this follows.

## Sources/Humane/SizeFormatter.swift

### `SizeFormatter.string(_:)`
Positional alias for `string(fromByteCount:)`, matching `humane` (Go)'s
label-free calling convention -- same reasoning and same session as
`TimeFormatter.string(_:_:)` below. One-line forward, no separate
implementation. `humane-ruby`'s `SizeFormatter#string` picked up the
equivalent positional-or-keyword support in the same pass.

## Sources/Humane/TimeFormatter.swift

### `TimeFormatter.includeSeconds`
Under 30 seconds (not 60), collapses to "less than a minute ago"/"in less
than a minute" instead of counting seconds -- matching the first row of
ActionView's `distance_of_time_in_words` bucket table (see `string`
below), not an arbitrary round number.

### `TimeFormatter.approximate`
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

### `TimeFormatter.string`
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
that `future` is computed directly (`date > referenceDate`, false when
equal) and bucketing is hand-rolled, zero is past-tense by construction
and that correction no longer applies.

    string(for: t, relativeTo: t)                              == "less than a minute ago"
    string(for: t.addingTimeInterval(-45), relativeTo: t)       == "1 minute ago"
    string(for: t.addingTimeInterval(-15 * 3600), relativeTo: t) == "15 hours ago"
    string(for: t.addingTimeInterval(-30 * 3600), relativeTo: t) == "1 day ago"

    let approx = TimeFormatter(approximate: true)
    approx.string(for: t.addingTimeInterval(-15 * 3600), relativeTo: t) == "about 15 hours ago"
    approx.string(for: t.addingTimeInterval(-30 * 3600), relativeTo: t) == "1 day ago"  // no "about" -- ActionView's table has none on the day bucket

### `TimeFormatter.string(at:relativeTo:)`
Additive alias for `string(for:relativeTo:)`. `at` is the parameter name
`humane` (Go) and `humane-ruby` actually share -- Ruby can't call it `for`
at all (`for` is a reserved word there, so `def string(for:, ...)` is a
syntax error), so `at` is the only name available in every language, not
a stylistic pick. `for:` remains this package's primary spelling since it
matches `RelativeDateTimeFormatter`'s own argument label and this
package's whole premise is feeling native to Foundation; `at:` exists
purely so the three languages can be compared/grepped side by side
without the one genuine naming mismatch between them (see `humane`'s and
`humane-ruby`'s own `docs/COWORK.md` "Naming" sections for the full
rationale). Implemented as a one-line forward to `string(for:relativeTo:)`,
not a separate implementation.

### `TimeFormatter.string(_:_:)`
Positional alias, no argument labels at all -- for callers who'd rather skip
labels entirely, matching `humane` (Go), which has no argument labels to
begin with (Go's calling convention is positional-only, full stop). Also a
one-line forward to `string(for:relativeTo:)`. Added alongside `at:relativeTo:`
in the same cross-language naming pass; `humane-ruby`'s `#string` picked up
the equivalent positional-or-keyword support -- see its own `docs/COMMENTS.md`.
