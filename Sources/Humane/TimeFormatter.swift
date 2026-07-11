import Foundation

/// Formats one time relative to another the way ActionView's
/// `distance_of_time_in_words` does for wording, but direction-aware like
/// `RelativeDateTimeFormatter` -- see docs/COMMENTS.md.
public enum TimeFormatter {
    /// Returns `at` relative to `relativeTo` as a human-readable string. If
    /// `at` is `nil`, returns `whenNil` without formatting -- see
    /// docs/COMMENTS.md.
    ///
    ///     TimeFormatter.timeAgo(Date().addingTimeInterval(-180), Date()) // "3 minutes ago"
    public static func timeAgo(
        _ at: Date?,
        _ relativeTo: Date,
        approximate: Bool = true,
        includeSeconds: Bool = false,
        whenNil: String = ""
    ) -> String {
        guard let at else { return whenNil }

        let seconds = abs(relativeTo.timeIntervalSince(at))
        let future = at > relativeTo

        if !includeSeconds && seconds < 30 {
            return future ? "in less than a minute" : "less than a minute ago"
        }

        if includeSeconds && seconds < 60 {
            return wrap(pluralize(Int(seconds), "second"), future: future)
        }

        // Buckets come from distanceInMinutes, not raw seconds re-divided per unit -- see docs/COMMENTS.md.
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

    private static func wrap(_ text: String, future: Bool) -> String {
        future ? "in " + text : text + " ago"
    }

    private static func pluralize(_ count: Int, _ unit: String) -> String {
        count == 1 ? "1 \(unit)" : "\(count) \(unit)s"
    }
}
