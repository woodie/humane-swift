# humane-swift

[![Swift](https://img.shields.io/badge/swift-5.9%2B-F05138.svg)](Package.swift)
[![CI](https://github.com/woodie/humane-swift/actions/workflows/ci.yml/badge.svg)](https://github.com/woodie/humane-swift/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/woodie/humane-swift.svg)](https://github.com/woodie/humane-swift/releases/latest)
[![License](https://img.shields.io/github/license/woodie/humane-swift.svg)](LICENSE)

File sizes that read exactly the way macOS Finder shows them (`"4.1 MB"`,
`"226 KB"`), and relative dates in Rails ActionView's wording (`"about 3 hours
ago"`, `"in 3 minutes"`), for Swift apps.

```swift
import Humane

Humane.humanSize(225_935) // "226 KB"

let mtime = Date().addingTimeInterval(-180)
Humane.timeAgo(mtime) // "3 minutes ago" -- relative to the real clock

let now = Date()
Humane.distanceInTime(mtime, now) // "3 minutes ago" -- explicit relativeTo, for tests
```

## Install

Add as a Swift Package Manager dependency:

```swift
.package(url: "https://github.com/woodie/humane-swift.git", from: "0.9.4")
```

## File sizes

`Humane.humanSize` is a thin wrapper over Foundation's `ByteCountFormatter`
(file style), so it matches Finder by construction: no decimals for KB, one
for MB, two for GB and above, trailing zeros dropped, and rounding up into the
next unit when it reaches 1000.

```swift
Humane.humanSize(2_579)         // "3 KB"
Humane.humanSize(4_132_383)     // "4.1 MB"
Humane.humanSize(999_999)       // "1 MB"
Humane.humanSize(5_240_000_000) // "5.24 GB"
```

## `distanceInTime` and `timeAgo`

Two entry points, same naming split as ActionView's own
`distance_of_time_in_words`/`time_ago_in_words`:

- **`distanceInTime(at, relativeTo, ...)`** -- the explicit, fully-tested
  core. Takes both times, so it's what specs should call.
- **`timeAgo(at, ...)`** -- a one-argument convenience for the common
  "drop into a view" case. Supplies `Date()` as `relativeTo` internally;
  everything else is identical to `distanceInTime`.

The wording follows ActionView's `distance_of_time_in_words`, with one
difference: direction is picked for you. A past time reads `"3 minutes ago"`
and a future one `"in 3 minutes"`, where ActionView leaves that to the caller.

Both share the same options and recommended defaults, already matching
ActionView's own `distance_of_time_in_words` defaults -- pass none at all
and you get them for free:

```swift
Humane.distanceInTime(at, relativeTo) // approximate: true, includeSeconds: false
Humane.timeAgo(at)                    // same defaults, relativeTo is Date()
```

- **`approximate`** (default `true`): prefixes `"about"`/`"in about"` on the
  hour-scale buckets (1 hour, and 2..24 hours), matching ActionView's
  `distance_of_time_in_words` wording for those buckets exactly (down to its
  44:30/89:30 rounding cutoffs), through the "1 day" bucket.
- **`includeSeconds`** (default `false`): under 30 seconds, collapses to
  `"less than a minute ago"`/`"in less than a minute"` instead of an exact
  second count. Matches ActionView's `include_seconds` default.
- **`whenNil`** (default `""`): if `at` is `nil`, both functions return this
  string without formatting -- for a scan, download, or other record that
  doesn't have a timestamp yet.

```swift
Humane.distanceInTime(at, relativeTo, approximate: false) // "15 hours ago", not "about 15 hours ago"
Humane.timeAgo(nil, whenNil: "an unknown time") // "an unknown time"
```

## Scope

Finder's byte-count style, and a numeric (non-calendar-aware) relative time
style through the "1 day" bucket -- that's the whole surface area today.
Alternate size units/styles and a `.named` style (`"yesterday"`,
calendar-boundary-aware) aren't implemented -- contributions welcome.

## Development

```
swift build
swift test
```
