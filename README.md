# humane-swift

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

## Install

Add as a Swift Package Manager dependency:

```swift
.package(url: "https://github.com/woodie/humane-swift.git", from: "0.1.0")
```

## Beyond Foundation's defaults

Two options on `TimeFormatter`, both off by default so it matches
`RelativeDateTimeFormatter` exactly out of the box:

- `includeSeconds` (default `false`): below a minute, collapses to "less
  than a minute ago"/"in less than a minute" instead of an exact second
  count -- a static render is stale the instant it's produced, so
  second-level precision there is misleading. Named after ActionView's
  `include_seconds`, which defaults the same way.
- `approximate` (default `false`): prefixes "about"/"in about" on buckets of
  an hour or larger, the way ActionView's `distance_of_time_in_words` does
  past that same boundary -- a signal that the bucket itself is a rounded
  value.

## Scope

Finder's `.file` byte-count style, and a numeric (non-calendar-aware)
relative time style -- that's the whole surface area today. `allowedUnits`/
alternate `countStyle`s and a `.named` style (`"yesterday"`,
calendar-boundary-aware) aren't implemented -- contributions welcome.
