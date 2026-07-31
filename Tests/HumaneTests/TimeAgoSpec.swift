import Foundation
import Quick
import Nimble
@testable import Humane

// Humane.timeAgo is a thin one-argument convenience over distanceInTime,
// supplying Date() as relativeTo -- see DistanceInTimeSpec.swift for the
// exhaustive wording/bucket coverage this doesn't need to repeat.
final class TimeAgoSpec: QuickSpec {
    override class func spec() {
        describe("Humane.timeAgo") {
            var at: Date!
            var whenNil: String!
            var result: String!
            beforeEach { whenNil = "" }
            justBeforeEach { result = Humane.timeAgo(at, whenNil: whenNil) }

            context("just now") {
                beforeEach { at = Date() }

                it("displays less than a minute ago") {
                    expect(result).to(equal("less than a minute ago"))
                }
            }

            context("3 minutes ago") {
                beforeEach { at = Date().addingTimeInterval(-180) }

                it("forwards to distanceInTime with Date() as relativeTo") {
                    expect(result).to(equal("3 minutes ago"))
                }
            }

            context("when at is nil") {
                beforeEach {
                    at = nil
                    whenNil = "an unknown time"
                }

                it("returns whenNil without formatting") {
                    expect(result).to(equal("an unknown time"))
                }
            }
        }
    }
}
