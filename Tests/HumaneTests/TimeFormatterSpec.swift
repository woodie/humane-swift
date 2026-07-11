import Foundation
import Quick
import Nimble
@testable import Humane

// Split into multiple top-level describes rather than one nested under a single
// "TimeFormatter" describe -- the combined expression was too large for the type
// checker (CI: "unable to type-check this expression in reasonable time"). Each
// describe below repeats its own `base`/`beforeEach` since Quick doesn't share
// state across sibling top-level describes. See docs/COMMENTS.md.
final class TimeFormatterSpec: QuickSpec {
    override class func spec() {
        describe("TimeFormatter#string(for:relativeTo:) with includeSeconds: false (the default)") {
            var base: Date!
            var formatter: TimeFormatter!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                formatter = TimeFormatter()
            }

            context("just now") {
                var when: Date!
                beforeEach { when = base }

                it("displays less than a minute ago") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("less than a minute ago"))
                }
            }

            context("45 seconds ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-45) }

                it("rounds up to 1 minute ago (past the 30-second cutoff)") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("1 minute ago"))
                }
            }

            context("1 minute ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-60) }

                it("displays 1 minute ago, singular") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("1 minute ago"))
                }
            }

            context("3 minutes ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-180) }

                it("displays 3 minutes ago") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("3 minutes ago"))
                }
            }

            context("1 hour ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-3600) }

                it("displays 1 hour ago, singular") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("1 hour ago"))
                }
            }

            context("15 hours ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-15 * 3600) }

                it("displays 15 hours ago") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("15 hours ago"))
                }
            }

            context("30 hours ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-30 * 3600) }

                it("rolls up to 1 day ago") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("1 day ago"))
                }
            }

            context("3 days ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-3 * 86_400) }

                it("displays 3 days ago") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("3 days ago"))
                }
            }

            context("45 seconds from now") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(45) }

                it("rounds up to in 1 minute (past the 30-second cutoff)") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("in 1 minute"))
                }
            }

            context("3 minutes from now") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(180) }

                it("displays in 3 minutes") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("in 3 minutes"))
                }
            }
        }

        describe("TimeFormatter#string(at:relativeTo:) and #string(_:_:)") {
            var base: Date!
            var formatter: TimeFormatter!
            var when: Date!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                formatter = TimeFormatter()
                when = base.addingTimeInterval(-180)
            }

            context("#string(at:relativeTo:)") {
                it("is an alias for string(for:relativeTo:), same output") {
                    expect(formatter.string(at: when, relativeTo: base))
                        .to(equal(formatter.string(for: when, relativeTo: base)))
                    expect(formatter.string(at: when, relativeTo: base)).to(equal("3 minutes ago"))
                }
            }

            context("#string(_:_:)") {
                it("is a positional alias for string(for:relativeTo:), same output") {
                    expect(formatter.string(when, base))
                        .to(equal(formatter.string(for: when, relativeTo: base)))
                    expect(formatter.string(when, base)).to(equal("3 minutes ago"))
                }
            }
        }

        describe("TimeFormatter#string(for:relativeTo:) with includeSeconds: true") {
            var base: Date!
            var formatter: TimeFormatter!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                formatter = TimeFormatter(includeSeconds: true)
            }

            context("just now") {
                var when: Date!
                beforeEach { when = base }

                it("displays 0 seconds ago") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("0 seconds ago"))
                }
            }

            context("1 second ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-1) }

                it("displays 1 second ago, singular") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("1 second ago"))
                }
            }

            context("45 seconds ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-45) }

                it("displays 45 seconds ago") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("45 seconds ago"))
                }
            }

            context("45 seconds from now") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(45) }

                it("displays in 45 seconds") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("in 45 seconds"))
                }
            }
        }

        describe("TimeFormatter#string(for:relativeTo:) with approximate: true") {
            var base: Date!
            var formatter: TimeFormatter!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                formatter = TimeFormatter(approximate: true)
            }

            context("59 minutes ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-59 * 60) }

                it("prefixes about (59 minutes falls in the 45..89-minute 'about 1 hour' bucket)") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("about 1 hour ago"))
                }
            }

            context("exactly 1 hour ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-3600) }

                it("prefixes about, the threshold is inclusive") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("about 1 hour ago"))
                }
            }

            context("15 hours ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-15 * 3600) }

                it("prefixes about") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("about 15 hours ago"))
                }
            }

            context("30 hours ago") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(-30 * 3600) }

                it("does not prefix about on the day bucket (ActionView's table has no 'about 1 day')") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("1 day ago"))
                }
            }

            context("3 minutes from now") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(180) }

                it("stays exact below the hour") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("in 3 minutes"))
                }
            }

            context("3 hours from now") {
                var when: Date!
                beforeEach { when = base.addingTimeInterval(3 * 3600) }

                it("prefixes in about") {
                    expect(formatter.string(for: when, relativeTo: base)).to(equal("in about 3 hours"))
                }
            }
        }

        // Boundary regression coverage for the ActionView distance_of_time_in_words bucket
        // table this approximate-distance behavior ports, truncated at the "1 day" row
        // since month/year buckets are out of scope. Each pair straddles a cutoff second
        // from that table to lock in exactly where the wording flips.
        describe("TimeFormatter#string at the approximate-distance bucket table boundaries, without approximate") {
            var base: Date!
            var formatter: TimeFormatter!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                formatter = TimeFormatter()
            }

            it("29s stays less than a minute, 30s rounds up to 1 minute") {
                let justBefore: Date = base.addingTimeInterval(-29)
                let atCutoff: Date = base.addingTimeInterval(-30)
                expect(formatter.string(for: justBefore, relativeTo: base)).to(equal("less than a minute ago"))
                expect(formatter.string(for: atCutoff, relativeTo: base)).to(equal("1 minute ago"))
            }

            it("89s stays 1 minute, 90s rounds up to 2 minutes") {
                let justBefore: Date = base.addingTimeInterval(-89)
                let atCutoff: Date = base.addingTimeInterval(-90)
                expect(formatter.string(for: justBefore, relativeTo: base)).to(equal("1 minute ago"))
                expect(formatter.string(for: atCutoff, relativeTo: base)).to(equal("2 minutes ago"))
            }

            it("44:29 stays 44 minutes, 44:30 rounds up to 1 hour") {
                let justBefore: Date = base.addingTimeInterval(-(44 * 60 + 29))
                let atCutoff: Date = base.addingTimeInterval(-(44 * 60 + 30))
                expect(formatter.string(for: justBefore, relativeTo: base)).to(equal("44 minutes ago"))
                expect(formatter.string(for: atCutoff, relativeTo: base)).to(equal("1 hour ago"))
            }

            it("89:29 stays 1 hour, 89:30 rounds up to 2 hours") {
                let justBefore: Date = base.addingTimeInterval(-(89 * 60 + 29))
                let atCutoff: Date = base.addingTimeInterval(-(89 * 60 + 30))
                expect(formatter.string(for: justBefore, relativeTo: base)).to(equal("1 hour ago"))
                expect(formatter.string(for: atCutoff, relativeTo: base)).to(equal("2 hours ago"))
            }

            it("23:59:29 stays 24 hours, 23:59:30 rounds up to 1 day") {
                let justBefore: Date = base.addingTimeInterval(-(23 * 3600 + 59 * 60 + 29))
                let atCutoff: Date = base.addingTimeInterval(-(23 * 3600 + 59 * 60 + 30))
                expect(formatter.string(for: justBefore, relativeTo: base)).to(equal("24 hours ago"))
                expect(formatter.string(for: atCutoff, relativeTo: base)).to(equal("1 day ago"))
            }
        }

        describe("TimeFormatter#string at the approximate-distance bucket table boundaries, with approximate: true") {
            var base: Date!
            var formatter: TimeFormatter!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                formatter = TimeFormatter(approximate: true)
            }

            it("44:29 has no about, 44:30 gains about (entering the hour bucket)") {
                let justBefore: Date = base.addingTimeInterval(-(44 * 60 + 29))
                let atCutoff: Date = base.addingTimeInterval(-(44 * 60 + 30))
                expect(formatter.string(for: justBefore, relativeTo: base)).to(equal("44 minutes ago"))
                expect(formatter.string(for: atCutoff, relativeTo: base)).to(equal("about 1 hour ago"))
            }

            it("23:59:29 keeps about, 23:59:30 drops about (entering the day bucket)") {
                let justBefore: Date = base.addingTimeInterval(-(23 * 3600 + 59 * 60 + 29))
                let atCutoff: Date = base.addingTimeInterval(-(23 * 3600 + 59 * 60 + 30))
                expect(formatter.string(for: justBefore, relativeTo: base)).to(equal("about 24 hours ago"))
                expect(formatter.string(for: atCutoff, relativeTo: base)).to(equal("1 day ago"))
            }
        }
    }
}
