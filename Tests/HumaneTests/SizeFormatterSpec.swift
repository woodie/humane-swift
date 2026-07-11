import Foundation
import Quick
import Nimble
@testable import Humane

final class SizeFormatterSpec: QuickSpec {
    override class func spec() {
        describe("SizeFormatter.humanSize") {
            context("with 0 bytes") {
                it("formats as Zero KB, ByteCountFormatter's own zero phrasing") {
                    expect(SizeFormatter.humanSize(0)).to(equal("Zero KB"))
                }
            }

            context("with 1 byte") {
                it("spells out the singular unit") {
                    expect(SizeFormatter.humanSize(1)).to(equal("1 byte"))
                }
            }

            context("with a small byte count") {
                it("spells out bytes, no rounding") {
                    expect(SizeFormatter.humanSize(7)).to(equal("7 bytes"))
                }
            }

            context("with 999 bytes") {
                it("stays in bytes, just under the 1 KB threshold") {
                    expect(SizeFormatter.humanSize(999)).to(equal("999 bytes"))
                }
            }

            context("with the shared 79992-byte fixture used by lambada/scandalous") {
                it("formats as 80 KB") {
                    expect(SizeFormatter.humanSize(79_992)).to(equal("80 KB"))
                }
            }

            context("with a real file's byte count") {
                it("matches Finder's reported size") {
                    expect(SizeFormatter.humanSize(225_935)).to(equal("226 KB"))
                }
            }

            context("with zouk's ByteCountFormatter(.file) fixture") {
                it("matches its output") {
                    expect(SizeFormatter.humanSize(500_000)).to(equal("500 KB"))
                }
            }

            context("with a single-digit megabyte value") {
                it("shows one decimal place") {
                    expect(SizeFormatter.humanSize(1_500_000)).to(equal("1.5 MB"))
                }
            }

            context("with a gigabyte-scale value") {
                it("keeps 2 decimal places at GB scale, unlike the old 1-decimal rule") {
                    expect(SizeFormatter.humanSize(5_240_000_000)).to(equal("5.24 GB"))
                }
            }
        }
    }
}
