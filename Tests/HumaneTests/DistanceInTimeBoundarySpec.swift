import Foundation
import Quick
import Nimble
@testable import Humane

// Kept in its own file/QuickSpec subclass rather than folded back into
// DistanceInTimeSpec.swift -- this exact content previously triggered a real CI
// type-checker timeout that took four rounds to isolate down to "needs its own
// compilation unit"; see docs/COMMENTS.md. Seconds stay precomputed integer
// literals (comment shows the derivation) rather than compound arithmetic
// (`44 * 60 + 29`), and each `it` keeps to one assertion, for the same reason.
//
// Boundary regression coverage for the ActionView distance_of_time_in_words bucket
// table this approximate-distance behavior ports, truncated at the "1 day" row
// since month/year buckets are out of scope. Each context below sits right on one
// cutoff second from that table to lock in exactly where the wording flips.
final class DistanceInTimeBoundarySpec: QuickSpec {
    override class func spec() {
        describe("Humane.distanceInTime at the approximate-distance bucket table boundaries, with approximate: false") {
            var base: Date!
            var at: Date!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }

            context("29 seconds ago") {
                beforeEach { at = base.addingTimeInterval(-29) }

                it("stays less than a minute") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("less than a minute ago"))
                }
            }

            context("30 seconds ago") {
                beforeEach { at = base.addingTimeInterval(-30) }

                it("rounds up to 1 minute") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("1 minute ago"))
                }
            }

            context("89 seconds ago") {
                beforeEach { at = base.addingTimeInterval(-89) }

                it("stays 1 minute") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("1 minute ago"))
                }
            }

            context("90 seconds ago") {
                beforeEach { at = base.addingTimeInterval(-90) }

                it("rounds up to 2 minutes") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("2 minutes ago"))
                }
            }

            context("44 minutes 29 seconds ago") {
                // 44 * 60 + 29
                beforeEach { at = base.addingTimeInterval(-2669) }

                it("stays 44 minutes") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("44 minutes ago"))
                }
            }

            context("44 minutes 30 seconds ago") {
                // 44 * 60 + 30
                beforeEach { at = base.addingTimeInterval(-2670) }

                it("rounds up to 1 hour") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("1 hour ago"))
                }
            }

            context("89 minutes 29 seconds ago") {
                // 89 * 60 + 29
                beforeEach { at = base.addingTimeInterval(-5369) }

                it("stays 1 hour") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("1 hour ago"))
                }
            }

            context("89 minutes 30 seconds ago") {
                // 89 * 60 + 30
                beforeEach { at = base.addingTimeInterval(-5370) }

                it("rounds up to 2 hours") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("2 hours ago"))
                }
            }

            context("23 hours 59 minutes 29 seconds ago") {
                // 23 * 3600 + 59 * 60 + 29
                beforeEach { at = base.addingTimeInterval(-86369) }

                it("stays 24 hours") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("24 hours ago"))
                }
            }

            context("23 hours 59 minutes 30 seconds ago") {
                // 23 * 3600 + 59 * 60 + 30
                beforeEach { at = base.addingTimeInterval(-86370) }

                it("rounds up to 1 day") {
                    let result = Humane.distanceInTime(at, base, approximate: false)
                    expect(result).to(equal("1 day ago"))
                }
            }
        }

        describe("Humane.distanceInTime at the approximate-distance bucket table boundaries, with no options (approximate true by default)") {
            var base: Date!
            var at: Date!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }

            context("44 minutes 29 seconds ago") {
                // 44 * 60 + 29
                beforeEach { at = base.addingTimeInterval(-2669) }

                it("has no about (still below the hour bucket)") {
                    let result = Humane.distanceInTime(at, base)
                    expect(result).to(equal("44 minutes ago"))
                }
            }

            context("44 minutes 30 seconds ago") {
                // 44 * 60 + 30
                beforeEach { at = base.addingTimeInterval(-2670) }

                it("gains about (entering the hour bucket)") {
                    let result = Humane.distanceInTime(at, base)
                    expect(result).to(equal("about 1 hour ago"))
                }
            }

            context("23 hours 59 minutes 29 seconds ago") {
                // 23 * 3600 + 59 * 60 + 29
                beforeEach { at = base.addingTimeInterval(-86369) }

                it("keeps about (still in the hour-scale buckets)") {
                    let result = Humane.distanceInTime(at, base)
                    expect(result).to(equal("about 24 hours ago"))
                }
            }

            context("23 hours 59 minutes 30 seconds ago") {
                // 23 * 3600 + 59 * 60 + 30
                beforeEach { at = base.addingTimeInterval(-86370) }

                it("drops about (entering the day bucket)") {
                    let result = Humane.distanceInTime(at, base)
                    expect(result).to(equal("1 day ago"))
                }
            }
        }
    }
}
