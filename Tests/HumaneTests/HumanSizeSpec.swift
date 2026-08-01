import Foundation
import Quick
import Nimble
@testable import Humane

final class HumanSizeSpec: QuickSpec {
    override class func spec() {
        describe("Humane.humanSize") {
            context("with 0 bytes") {
                it("formats as Zero KB") {
                    expect(Humane.humanSize(0)).to(equal("Zero KB"))
                }
            }

            context("with 1 byte") {
                it("spells out the singular unit") {
                    expect(Humane.humanSize(1)).to(equal("1 byte"))
                }
            }

            context("with a small byte count") {
                it("spells out bytes") {
                    expect(Humane.humanSize(7)).to(equal("7 bytes"))
                }
            }

            context("with 999 bytes") {
                it("stays in bytes") {
                    expect(Humane.humanSize(999)).to(equal("999 bytes"))
                }
            }

            context("with 79992 bytes") {
                it("formats as 80 KB") {
                    expect(Humane.humanSize(79_992)).to(equal("80 KB"))
                }
            }

            context("with a real file's byte count") {
                it("formats as 226 KB") {
                    expect(Humane.humanSize(225_935)).to(equal("226 KB"))
                }
            }

            context("with 500000 bytes") {
                it("formats as 500 KB") {
                    expect(Humane.humanSize(500_000)).to(equal("500 KB"))
                }
            }

            context("with a single-digit megabyte value") {
                it("shows one decimal place, trailing zero trimmed") {
                    expect(Humane.humanSize(1_500_000)).to(equal("1.5 MB"))
                }
            }

            context("with a gigabyte-scale value") {
                it("keeps 2 decimal places at 3 significant figures (not truncated to 1)") {
                    expect(Humane.humanSize(5_240_000_000)).to(equal("5.24 GB"))
                }
            }

            context("with a value that lands on an exact unit") {
                it("trims both trailing decimal digits") {
                    expect(Humane.humanSize(2_000_000)).to(equal("2 MB"))
                }
            }
        }
    }
}
