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
            context("just now") {
                it("displays less than a minute ago") {
                    expect(Humane.timeAgo(Date())).to(equal("less than a minute ago"))
                }
            }

            context("3 minutes ago") {
                it("forwards to distanceInTime with Date() as relativeTo") {
                    let when = Date().addingTimeInterval(-180)
                    expect(Humane.timeAgo(when)).to(equal("3 minutes ago"))
                }
            }

            context("when at is nil") {
                it("returns whenNil without formatting") {
                    expect(Humane.timeAgo(nil, whenNil: "an unknown time")).to(equal("an unknown time"))
                }
            }
        }
    }
}
