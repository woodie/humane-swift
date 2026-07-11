import Foundation
import Quick
import Nimble
@testable import Humane

// Split into multiple sibling top-level describes rather than one nested under a
// single "TimeFormatter" describe -- an earlier version of this file hit a real CI
// type-checker timeout at that shape; see docs/COMMENTS.md. Each describe below
// repeats its own `base` since Quick doesn't share state across sibling top-level
// describes.
final class TimeFormatterSpec: QuickSpec {
    override class func spec() {
        describe("TimeFormatter.timeAgo with no options (the recommended defaults: approximate true, includeSeconds false)") {
            var base: Date!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }

            context("just now") {
                it("displays less than a minute ago") {
                    expect(TimeFormatter.timeAgo(base, base)).to(equal("less than a minute ago"))
                }
            }

            context("45 seconds ago") {
                it("rounds up to 1 minute ago (past the 30-second cutoff)") {
                    let when = base.addingTimeInterval(-45)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("1 minute ago"))
                }
            }

            context("1 minute ago") {
                it("displays 1 minute ago, singular") {
                    let when = base.addingTimeInterval(-60)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("1 minute ago"))
                }
            }

            context("3 minutes ago") {
                it("displays 3 minutes ago") {
                    let when = base.addingTimeInterval(-180)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("3 minutes ago"))
                }
            }

            context("1 hour ago") {
                it("displays about 1 hour ago") {
                    let when = base.addingTimeInterval(-3600)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("about 1 hour ago"))
                }
            }

            context("15 hours ago") {
                it("displays about 15 hours ago") {
                    let when = base.addingTimeInterval(-15 * 3600)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("about 15 hours ago"))
                }
            }

            context("30 hours ago") {
                it("rolls up to 1 day ago, with no about (ActionView's table has none on the day bucket)") {
                    let when = base.addingTimeInterval(-30 * 3600)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("1 day ago"))
                }
            }

            context("3 days ago") {
                it("displays 3 days ago") {
                    let when = base.addingTimeInterval(-3 * 86_400)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("3 days ago"))
                }
            }

            context("45 seconds from now") {
                it("rounds up to in 1 minute (past the 30-second cutoff)") {
                    let when = base.addingTimeInterval(45)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("in 1 minute"))
                }
            }

            context("3 minutes from now") {
                it("displays in 3 minutes") {
                    let when = base.addingTimeInterval(180)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("in 3 minutes"))
                }
            }

            context("3 hours from now") {
                it("displays in about 3 hours") {
                    let when = base.addingTimeInterval(3 * 3600)
                    expect(TimeFormatter.timeAgo(when, base)).to(equal("in about 3 hours"))
                }
            }
        }

        describe("TimeFormatter.timeAgo with includeSeconds: true") {
            var base: Date!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }

            context("just now") {
                it("displays 0 seconds ago") {
                    expect(TimeFormatter.timeAgo(base, base, includeSeconds: true)).to(equal("0 seconds ago"))
                }
            }

            context("1 second ago") {
                it("displays 1 second ago, singular") {
                    let when = base.addingTimeInterval(-1)
                    expect(TimeFormatter.timeAgo(when, base, includeSeconds: true)).to(equal("1 second ago"))
                }
            }

            context("45 seconds ago") {
                it("displays 45 seconds ago") {
                    let when = base.addingTimeInterval(-45)
                    expect(TimeFormatter.timeAgo(when, base, includeSeconds: true)).to(equal("45 seconds ago"))
                }
            }

            context("45 seconds from now") {
                it("displays in 45 seconds") {
                    let when = base.addingTimeInterval(45)
                    expect(TimeFormatter.timeAgo(when, base, includeSeconds: true)).to(equal("in 45 seconds"))
                }
            }
        }

        describe("TimeFormatter.timeAgo with approximate: false") {
            var base: Date!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }

            context("1 hour ago") {
                it("displays the exact count, no about prefix") {
                    let when = base.addingTimeInterval(-3600)
                    expect(TimeFormatter.timeAgo(when, base, approximate: false)).to(equal("1 hour ago"))
                }
            }

            context("15 hours ago") {
                it("displays 15 hours ago") {
                    let when = base.addingTimeInterval(-15 * 3600)
                    expect(TimeFormatter.timeAgo(when, base, approximate: false)).to(equal("15 hours ago"))
                }
            }
        }

        describe("TimeFormatter.timeAgo nil handling") {
            var base: Date!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }

            context("when at is nil and whenNil is set") {
                it("returns whenNil without formatting") {
                    let result = TimeFormatter.timeAgo(nil, base, whenNil: "an unknown time")
                    expect(result).to(equal("an unknown time"))
                }
            }

            context("when at is nil and whenNil is left unset") {
                it("returns an empty string") {
                    expect(TimeFormatter.timeAgo(nil, base)).to(equal(""))
                }
            }
        }

        // Boundary-cutoff regression coverage moved to its own file/QuickSpec
        // subclass: TimeFormatterBoundarySpec.swift. See docs/COMMENTS.md.
    }
}
