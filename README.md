# humane-swift

[![Swift](https://img.shields.io/badge/swift-5.9%2B-F05138.svg)](Package.swift)
[![CI](https://github.com/woodie/humane-swift/actions/workflows/ci.yml/badge.svg)](https://github.com/woodie/humane-swift/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/woodie/humane-swift.svg)](https://github.com/woodie/humane-swift/releases/latest)
[![License](https://img.shields.io/github/license/woodie/humane-swift.svg)](LICENSE)

Human-readable file sizes and relative times for a live, refreshable Swift
app -- consistent output with [`humane`](https://github.com/woodie/humane)
(Go) and [`humane-ruby`](https://github.com/woodie/humane-ruby), which serve
Ruby and Go HTML templates that render once and can't refresh themselves.

```swift
import Humane

SizeFormatter.humanSize(225_935) // "226 KB"

let now = Date(); let mtime = now.addingTimeInterval(-180)
TimeFormatter.timeAgo(now, now) // "less than a minute ago"
TimeFormatter.timeAgo(mtime, now) // "3 minutes ago"
```

`SizeFormatter.humanSize` is a thin wrapper over `ByteCountFormatter` --
Foundation already gets this right for free, so there's no reason to
duplicate its math the way `humane`/`humane-ruby` have to.

## Install

Add as a Swift Package Manager dependency:

```swift
.package(url: "https://github.com/woodie/humane-swift.git", from: "0.9.0")
```

## `timeAgo` options

`timeAgo`'s recommended defaults already match ActionView's own
`distance_of_time_in_words` defaults -- pass no options at all and you get
them for free:

```swift
TimeFormatter.timeAgo(at, relativeTo) // approximate: true, includeSeconds: false
```

- **`approximate`** (default `true`): prefixes `"about"`/`"in about"` on the
  hour-scale buckets (1 hour, and 2..24 hours), matching ActionView's
  `distance_of_time_in_words` wording for those buckets exactly (down to its
  44:30/89:30 rounding cutoffs), through the "1 day" bucket.
- **`includeSeconds`** (default `false`): under 30 seconds, collapses to
  `"less than a minute ago"`/`"in less than a minute"` instead of an exact
  second count. Matches ActionView's `include_seconds` default.
- **`whenNil`** (default `""`): if `at` is `nil`, `timeAgo` returns this
  string without formatting -- for a scan, download, or other record that
  doesn't have a timestamp yet.

```swift
TimeFormatter.timeAgo(at, relativeTo, approximate: false) // "15 hours ago", not "about 15 hours ago"
TimeFormatter.timeAgo(nil, relativeTo, whenNil: "an unknown time") // "an unknown time"
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
