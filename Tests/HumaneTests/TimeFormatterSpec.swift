import Foundation
import Quick
import Nimble
@testable import Humane

final class TimeFormatterSpec: QuickSpec {
    override class func spec() {
        describe("TimeFormatter") {
            var base: Date!
            beforeEach { base = ISO8601DateFormatter().date(from: "2026-07-08T12:00:00Z") }

            describe("#string(for:relativeTo:) with includeSeconds: false (the default)") {
                var formatter: TimeFormatter!
                beforeEach { formatter = TimeFormatter() }

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

                    it("displays less than a minute ago") {
                        expect(formatter.string(for: when, relativeTo: base)).to(equal("less than a minute ago"))
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

                    it("displays in less than a minute") {
                        expect(formatter.string(for: when, relativeTo: base)).to(equal("in less than a minute"))
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

            describe("#string(for:relativeTo:) with includeSeconds: true") {
                var formatter: TimeFormatter!
                beforeEach { formatter = TimeFormatter(includeSeconds: true) }

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

            describe("#string(for:relativeTo:) with approximate: true") {
                var formatter: TimeFormatter!
                beforeEach { formatter = TimeFormatter(approximate: true) }

                context("59 minutes ago") {
                    var when: Date!
                    beforeEach { when = base.addingTimeInterval(-59 * 60) }

                    it("stays exact below the hour") {
                        expect(formatter.string(for: when, relativeTo: base)).to(equal("59 minutes ago"))
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

                    it("prefixes about on the rolled-up day bucket") {
                        expect(formatter.string(for: when, relativeTo: base)).to(equal("about 1 day ago"))
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
        }
    }
}
