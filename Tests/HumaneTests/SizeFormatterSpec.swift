import Foundation
import Quick
import Nimble
@testable import Humane

final class SizeFormatterSpec: QuickSpec {
    override class func spec() {
        describe("SizeFormatter") {
            var formatter: SizeFormatter!
            beforeEach { formatter = SizeFormatter() }

            describe("#string(fromByteCount:)") {
                context("with 0 bytes") {
                    it("formats as 0 B") {
                        expect(formatter.string(fromByteCount: 0)).to(equal("0 B"))
                    }
                }

                context("with a small byte count") {
                    it("formats with no rounding") {
                        expect(formatter.string(fromByteCount: 7)).to(equal("7 B"))
                    }
                }

                context("with 999 bytes") {
                    it("stays in bytes, just under the 1 KB threshold") {
                        expect(formatter.string(fromByteCount: 999)).to(equal("999 B"))
                    }
                }

                context("with the shared 79992-byte fixture used by lambada/scandalous") {
                    it("formats as 80 KB") {
                        expect(formatter.string(fromByteCount: 79_992)).to(equal("80 KB"))
                    }
                }

                context("with a real file's byte count") {
                    it("matches Finder's reported size") {
                        expect(formatter.string(fromByteCount: 225_935)).to(equal("226 KB"))
                    }
                }

                context("with zouk's ByteCountFormatter(.file) fixture") {
                    it("matches its output") {
                        expect(formatter.string(fromByteCount: 500_000)).to(equal("500 KB"))
                    }
                }

                context("with a single-digit megabyte value") {
                    it("shows one decimal place") {
                        expect(formatter.string(fromByteCount: 1_500_000)).to(equal("1.5 MB"))
                    }
                }

                context("with a gigabyte-scale value") {
                    it("rounds to 2 significant digits") {
                        expect(formatter.string(fromByteCount: 5_240_000_000)).to(equal("5.2 GB"))
                    }
                }
            }
        }
    }
}
