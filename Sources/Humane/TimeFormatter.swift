import Foundation

/// Formats one time relative to another the way Finder-adjacent tools do.
public struct TimeFormatter {
    /// Under 30 seconds, collapse to "less than a minute ago"/"in less than a minute". Matches ActionView's `include_seconds` default.
    public var includeSeconds: Bool

    /// Prefix "about"/"in about" on the hour-scale buckets, matching ActionView's `distance_of_time_in_words`. See docs/COMMENTS.md.
    public var approximate: Bool

    public init(includeSeconds: Bool = false, approximate: Bool = false) {
        self.includeSeconds = includeSeconds
        self.approximate = approximate
    }

    public func string(for date: Date, relativeTo referenceDate: Date) -> String {
        let seconds = abs(referenceDate.timeIntervalSince(date))
        let future = date > referenceDate

        if !includeSeconds && seconds < 30 {
            return future ? "in less than a minute" : "less than a minute ago"
        }

        if includeSeconds && seconds < 60 {
            return wrap(pluralize(Int(seconds), "second"), future: future)
        }

        // Buckets come from distanceInMinutes, not RelativeDateTimeFormatter's own rounding -- see docs/COMMENTS.md.
        let distanceInMinutes = Int((seconds / 60.0).rounded())

        var text: String
        var approximable = false
        switch distanceInMinutes {
        case 1:
            text = "1 minute"
        case 2...44:
            text = pluralize(distanceInMinutes, "minute")
        case 45...89:
            text = "1 hour"
            approximable = true
        case 90...1439:
            text = pluralize(Int((Double(distanceInMinutes) / 60.0).rounded()), "hour")
            approximable = true
        case 1440...2519:
            text = "1 day"
        default:
            text = pluralize(Int((Double(distanceInMinutes) / 1440.0).rounded()), "day")
        }

        if approximate && approximable {
            text = "about " + text
        }

        return wrap(text, future: future)
    }

    private func wrap(_ text: String, future: Bool) -> String {
        future ? "in " + text : text + " ago"
    }

    private func pluralize(_ count: Int, _ unit: String) -> String {
        count == 1 ? "1 \(unit)" : "\(count) \(unit)s"
    }
}
