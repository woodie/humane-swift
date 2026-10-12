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
                it("shows two decimal places") {
                    expect(Humane.humanSize(5_240_000_000)).to(equal("5.24 GB"))
                }
            }

            context("with a value that lands on an exact unit") {
                it("trims both trailing decimal digits") {
                    expect(Humane.humanSize(2_000_000)).to(equal("2 MB"))
                }
            }

            context("with a kilobyte value under 10") {
                it("rounds to whole kilobytes") {
                    expect(Humane.humanSize(1_234)).to(equal("1 KB"))
                }
            }

            context("with a kilobyte value that has a fraction") {
                it("rounds to the nearest kilobyte") {
                    expect(Humane.humanSize(2_579)).to(equal("3 KB"))
                }
            }

            context("with a megabyte value under 10") {
                it("shows one decimal place, not two") {
                    expect(Humane.humanSize(4_132_383)).to(equal("4.1 MB"))
                }
            }

            context("with a megabyte value whose second decimal would round") {
                it("drops the second decimal place") {
                    expect(Humane.humanSize(5_243_887)).to(equal("5.2 MB"))
                }
            }

            context("with a megabyte value at 100 or more") {
                it("still shows one decimal place") {
                    expect(Humane.humanSize(123_456_789)).to(equal("123.5 MB"))
                }
            }

            context("with a gigabyte value at 10 or more") {
                it("still shows two decimal places") {
                    expect(Humane.humanSize(12_345_678_901)).to(equal("12.35 GB"))
                }
            }

            context("with a terabyte value") {
                it("shows two decimal places") {
                    expect(Humane.humanSize(1_234_567_890_123)).to(equal("1.23 TB"))
                }
            }

            context("when rounding reaches 1000 of a unit") {
                context("just below the kilobyte limit") {
                    it("stays in KB") {
                        expect(Humane.humanSize(999_499)).to(equal("999 KB"))
                    }
                }

                context("with 999999 bytes") {
                    it("moves up to MB") {
                        expect(Humane.humanSize(999_999)).to(equal("1 MB"))
                    }
                }

                context("just below the megabyte limit") {
                    it("stays in MB") {
                        expect(Humane.humanSize(999_949_999)).to(equal("999.9 MB"))
                    }
                }

                context("with 999960000 bytes") {
                    it("moves up to GB") {
                        expect(Humane.humanSize(999_960_000)).to(equal("1 GB"))
                    }
                }

                context("with 999995000000 bytes") {
                    it("moves up to TB") {
                        expect(Humane.humanSize(999_995_000_000)).to(equal("1 TB"))
                    }
                }
            }
        }
    }
}
