# humane-swift

[![Swift](https://img.shields.io/badge/swift-5.9%2B-F05138.svg)](Package.swift)
[![CI](https://github.com/woodie/humane-swift/actions/workflows/ci.yml/badge.svg)](https://github.com/woodie/humane-swift/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/woodie/humane-swift.svg)](https://github.com/woodie/humane-swift/releases/latest)
[![License](https://img.shields.io/github/license/woodie/humane-swift.svg)](LICENSE)

`humane` (Go) and `humane-ruby` exist so those languages can match what
Foundation's `ByteCountFormatter` and `RelativeDateTimeFormatter` already get
right for free on every Mac. `humane-swift` is the Swift sibling: thin
wrappers over those two formatters, with the same API shape as the Go and
Ruby libraries, plus a couple of additive, opt-in options for contexts that
can't live-refresh a rendered time (a web response, a cached page).

```swift
import Humane

Humane.SizeFormatter().string(fromByteCount: 225_935) // "226 KB"

let timeFormatter = Humane.TimeFormatter()
timeFormatter.string(for: Date().addingTimeInterval(-180), relativeTo: Date()) // "3 minutes ago"
```

Matches `ByteCountFormatter`/`RelativeDateTimeFormatter` output exactly by
default -- the wrapping exists so a Go or Ruby application shares identical
output with a Swift one, not because Foundation needs correcting.

`TimeFormatter` also accepts `string(at:relativeTo:)` as an alias for
`string(for:relativeTo:)` -- `at` is the parameter name shared with `humane`
(Go) and `humane-ruby`, where `for` isn't available as a keyword argument.
Use whichever reads more naturally; `for:` is the primary spelling here.
Both `SizeFormatter` and `TimeFormatter` also accept fully positional calls
(`string(_:)` / `string(_:_:)`) for callers who'd rather skip argument
labels entirely, matching `humane` (Go)'s label-free calling convention:

```swift
Humane.SizeFormatter().string(225_935) // "226 KB"
timeFormatter.string(Date().addingTimeInterval(-180), Date()) // "3 minutes ago"
```

## Install

Add as a Swift Package Manager dependency:

```swift
.package(url: "https://github.com/woodie/humane-swift.git", from: "0.3.0")
```

## Beyond Foundation's defaults

Foundation is the baseline every default matches exactly, in all three
languages -- these two options on `TimeFormatter` are how you layer
ActionView's wording on top of it, not a replacement for it. Both off by
default, so `TimeFormatter()` and calling `RelativeDateTimeFormatter`
directly always agree:

- `includeSeconds` (default `false`): under 30 seconds, collapses to "less
  than a minute ago"/"in less than a minute" instead of an exact second
  count -- a static render is stale the instant it's produced, so
  second-level precision there is misleading. Named after ActionView's
  `include_seconds`, which defaults the same way.
- `approximate` (default `false`): prefixes "about"/"in about" on the
  hour-scale buckets (1 hour, and 2..24 hours), the way ActionView's
  `distance_of_time_in_words` does for those same buckets -- a signal that
  the bucket itself is a rounded value. Matches ActionView's own table
  exactly (down to its 44:30/89:30 rounding cutoffs), through the "1 day"
  bucket; week/month/year buckets are out of scope. See
  [humane-ruby issue #1](https://github.com/woodie/humane-ruby/issues/1).

```swift
Humane.TimeFormatter(approximate: true)
    .string(for: Date().addingTimeInterval(-15 * 3600), relativeTo: Date())
// "about 15 hours ago"
```

## Scope

Finder's `.file` byte-count style, and a numeric (non-calendar-aware)
relative time style -- that's the whole surface area today. `allowedUnits`/
alternate `countStyle`s and a `.named` style (`"yesterday"`,
calendar-boundary-aware) aren't implemented -- contributions welcome.
