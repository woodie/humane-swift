import Foundation
import Quick
import Nimble
@testable import Humane

// Split into multiple sibling top-level describes rather than one nested under a
// single "Humane" describe -- an earlier version of this file hit a real CI
// type-checker timeout at that shape; see docs/COMMENTS.md. Each describe below
// repeats its own `base` since Quick doesn't share state across sibling top-level
// describes.
final class DistanceInTimeSpec: QuickSpec {
    override class func spec() {
        describe("Humane.distanceInTime with no options") {
            var base: Date!
            var at: Date!
            var result: String!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }
            justBeforeEach { result = Humane.distanceInTime(at, base) }

            context("just now") {
                beforeEach { at = base }

                it("displays less than a minute ago") {
                    expect(result).to(equal("less than a minute ago"))
                }
            }

            context("45 seconds ago") {
                beforeEach { at = base.addingTimeInterval(-45) }

                it("rounds up to 1 minute ago (past the 30-second cutoff)") {
                    expect(result).to(equal("1 minute ago"))
                }
            }

            context("1 minute ago") {
                beforeEach { at = base.addingTimeInterval(-60) }

                it("displays 1 minute ago, singular") {
                    expect(result).to(equal("1 minute ago"))
                }
            }

            context("3 minutes ago") {
                beforeEach { at = base.addingTimeInterval(-180) }

                it("displays 3 minutes ago") {
                    expect(result).to(equal("3 minutes ago"))
                }
            }

            context("1 hour ago") {
                beforeEach { at = base.addingTimeInterval(-3600) }

                it("displays about 1 hour ago") {
                    expect(result).to(equal("about 1 hour ago"))
                }
            }

            context("15 hours ago") {
                beforeEach { at = base.addingTimeInterval(-15 * 3600) }

                it("displays about 15 hours ago") {
                    expect(result).to(equal("about 15 hours ago"))
                }
            }

            context("30 hours ago") {
                beforeEach { at = base.addingTimeInterval(-30 * 3600) }

                it("rolls up to 1 day ago, with no about") {
                    expect(result).to(equal("1 day ago"))
                }
            }

            context("3 days ago") {
                beforeEach { at = base.addingTimeInterval(-3 * 86_400) }

                it("displays 3 days ago") {
                    expect(result).to(equal("3 days ago"))
                }
            }

            context("45 seconds from now") {
                beforeEach { at = base.addingTimeInterval(45) }

                it("rounds up to in 1 minute (past the 30-second cutoff)") {
                    expect(result).to(equal("in 1 minute"))
                }
            }

            context("3 minutes from now") {
                beforeEach { at = base.addingTimeInterval(180) }

                it("displays in 3 minutes") {
                    expect(result).to(equal("in 3 minutes"))
                }
            }

            context("3 hours from now") {
                beforeEach { at = base.addingTimeInterval(3 * 3600) }

                it("displays in about 3 hours") {
                    expect(result).to(equal("in about 3 hours"))
                }
            }
        }

        describe("Humane.distanceInTime with includeSeconds: true") {
            var base: Date!
            var at: Date!
            var result: String!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }
            justBeforeEach { result = Humane.distanceInTime(at, base, includeSeconds: true) }

            context("just now") {
                beforeEach { at = base }

                it("displays 0 seconds ago") {
                    expect(result).to(equal("0 seconds ago"))
                }
            }

            context("1 second ago") {
                beforeEach { at = base.addingTimeInterval(-1) }

                it("displays 1 second ago, singular") {
                    expect(result).to(equal("1 second ago"))
                }
            }

            context("45 seconds ago") {
                beforeEach { at = base.addingTimeInterval(-45) }

                it("displays 45 seconds ago") {
                    expect(result).to(equal("45 seconds ago"))
                }
            }

            context("45 seconds from now") {
                beforeEach { at = base.addingTimeInterval(45) }

                it("displays in 45 seconds") {
                    expect(result).to(equal("in 45 seconds"))
                }
            }
        }

        describe("Humane.distanceInTime with approximate: false") {
            var base: Date!
            var at: Date!
            var result: String!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
            }
            justBeforeEach { result = Humane.distanceInTime(at, base, approximate: false) }

            context("1 hour ago") {
                beforeEach { at = base.addingTimeInterval(-3600) }

                it("displays the exact count, no about prefix") {
                    expect(result).to(equal("1 hour ago"))
                }
            }

            context("15 hours ago") {
                beforeEach { at = base.addingTimeInterval(-15 * 3600) }

                it("displays 15 hours ago") {
                    expect(result).to(equal("15 hours ago"))
                }
            }
        }

        describe("Humane.distanceInTime nil handling") {
            var base: Date!
            var whenNil: String!
            var result: String!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                whenNil = ""
            }
            justBeforeEach { result = Humane.distanceInTime(nil, base, whenNil: whenNil) }

            context("when at is nil and whenNil is set") {
                beforeEach { whenNil = "an unknown time" }

                it("returns whenNil without formatting") {
                    expect(result).to(equal("an unknown time"))
                }
            }

            context("when at is nil and whenNil is left unset") {
                it("returns an empty string") {
                    expect(result).to(equal(""))
                }
            }
        }

        // Boundary-cutoff regression coverage moved to its own file/QuickSpec
        // subclass: DistanceInTimeBoundarySpec.swift. See docs/COMMENTS.md.
    }
}
