import Foundation
import Quick
import Nimble
@testable import Humane

// Split into its own file/QuickSpec subclass, not just its own describe within
// TimeFormatterSpec.swift -- three rounds of within-file restructuring (splitting
// describes, extracting Date/String lets, one assertion per it) each failed on CI
// at this exact content, even as local swift test passed every time. Moving it to
// a separate compilation unit is the stronger form of isolation. Seconds are
// precomputed integer literals (comment shows the derivation) rather than compound
// arithmetic (`44 * 60 + 29`) computed inline, removing another layer of expression
// complexity. See docs/COMMENTS.md.
//
// Boundary regression coverage for the ActionView distance_of_time_in_words bucket
// table this approximate-distance behavior ports, truncated at the "1 day" row
// since month/year buckets are out of scope. Each pair straddles a cutoff second
// from that table to lock in exactly where the wording flips.
final class TimeFormatterBoundarySpec: QuickSpec {
    override class func spec() {
        describe("TimeFormatter#string at the approximate-distance bucket table boundaries, without approximate") {
            var base: Date!
            var formatter: TimeFormatter!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                formatter = TimeFormatter()
            }

            it("29s stays less than a minute") {
                let result: String = formatter.string(for: base.addingTimeInterval(-29), relativeTo: base)
                expect(result).to(equal("less than a minute ago"))
            }

            it("30s rounds up to 1 minute") {
                let result: String = formatter.string(for: base.addingTimeInterval(-30), relativeTo: base)
                expect(result).to(equal("1 minute ago"))
            }

            it("89s stays 1 minute") {
                let result: String = formatter.string(for: base.addingTimeInterval(-89), relativeTo: base)
                expect(result).to(equal("1 minute ago"))
            }

            it("90s rounds up to 2 minutes") {
                let result: String = formatter.string(for: base.addingTimeInterval(-90), relativeTo: base)
                expect(result).to(equal("2 minutes ago"))
            }

            it("44:29 stays 44 minutes") {
                // 44 * 60 + 29
                let result: String = formatter.string(for: base.addingTimeInterval(-2669), relativeTo: base)
                expect(result).to(equal("44 minutes ago"))
            }

            it("44:30 rounds up to 1 hour") {
                // 44 * 60 + 30
                let result: String = formatter.string(for: base.addingTimeInterval(-2670), relativeTo: base)
                expect(result).to(equal("1 hour ago"))
            }

            it("89:29 stays 1 hour") {
                // 89 * 60 + 29
                let result: String = formatter.string(for: base.addingTimeInterval(-5369), relativeTo: base)
                expect(result).to(equal("1 hour ago"))
            }

            it("89:30 rounds up to 2 hours") {
                // 89 * 60 + 30
                let result: String = formatter.string(for: base.addingTimeInterval(-5370), relativeTo: base)
                expect(result).to(equal("2 hours ago"))
            }

            it("23:59:29 stays 24 hours") {
                // 23 * 3600 + 59 * 60 + 29
                let result: String = formatter.string(for: base.addingTimeInterval(-86369), relativeTo: base)
                expect(result).to(equal("24 hours ago"))
            }

            it("23:59:30 rounds up to 1 day") {
                // 23 * 3600 + 59 * 60 + 30
                let result: String = formatter.string(for: base.addingTimeInterval(-86370), relativeTo: base)
                expect(result).to(equal("1 day ago"))
            }
        }

        describe("TimeFormatter#string at the approximate-distance bucket table boundaries, with approximate: true") {
            var base: Date!
            var formatter: TimeFormatter!
            beforeEach {
                base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z")
                formatter = TimeFormatter(approximate: true)
            }

            it("44:29 has no about (still below the hour bucket)") {
                // 44 * 60 + 29
                let result: String = formatter.string(for: base.addingTimeInterval(-2669), relativeTo: base)
                expect(result).to(equal("44 minutes ago"))
            }

            it("44:30 gains about (entering the hour bucket)") {
                // 44 * 60 + 30
                let result: String = formatter.string(for: base.addingTimeInterval(-2670), relativeTo: base)
                expect(result).to(equal("about 1 hour ago"))
            }

            it("23:59:29 keeps about (still in the hour-scale buckets)") {
                // 23 * 3600 + 59 * 60 + 29
                let result: String = formatter.string(for: base.addingTimeInterval(-86369), relativeTo: base)
                expect(result).to(equal("about 24 hours ago"))
            }

            it("23:59:30 drops about (entering the day bucket)") {
                // 23 * 3600 + 59 * 60 + 30
                let result: String = formatter.string(for: base.addingTimeInterval(-86370), relativeTo: base)
                expect(result).to(equal("1 day ago"))
            }
        }
    }
}
