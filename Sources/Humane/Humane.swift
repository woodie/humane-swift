import Foundation

/// Human-readable file sizes and relative times, matching Finder/ActionView
/// wording. See docs/COMMENTS.md.
public enum Humane {
    /// Returns byteCount as a Finder-style human-readable string. A thin
    /// wrapper over `ByteCountFormatter` -- see docs/COMMENTS.md for why
    /// this package doesn't hand-roll the same math `humane`/`humane-ruby`
    /// do.
    ///
    ///     Humane.humanSize(225_935) // "226 KB"
    public static func humanSize(_ byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }

    /// Formats `at` relative to `relativeTo` the way ActionView's
    /// `distance_of_time_in_words` does for wording, but direction-aware like
    /// `RelativeDateTimeFormatter` -- "X ago"/"in X", chosen automatically
    /// rather than requiring the caller to know which applies ahead of time.
    /// This is the explicit, fully-tested core -- see `timeAgo` below for the
    /// one-argument convenience. See docs/COMMENTS.md.
    ///
    ///     Humane.distanceInTime(Date().addingTimeInterval(-180), Date()) // "3 minutes ago"
    public static func distanceInTime(
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

    /// Returns `at` relative to the current time -- a convenience for the
    /// common "drop into a view" case, modeled on ActionView's
    /// `time_ago_in_words` wrapping `distance_of_time_in_words` with
    /// `Time.now`. Use `distanceInTime` directly when the reference time
    /// needs to be explicit (tests, a fixed point other than now).
    ///
    ///     Humane.timeAgo(Date().addingTimeInterval(-180)) // "3 minutes ago"
    public static func timeAgo(
        _ at: Date?,
        approximate: Bool = true,
        includeSeconds: Bool = false,
        whenNil: String = ""
    ) -> String {
        distanceInTime(at, Date(), approximate: approximate, includeSeconds: includeSeconds, whenNil: whenNil)
    }

    private static func wrap(_ text: String, future: Bool) -> String {
        future ? "in " + text : text + " ago"
    }

    private static func pluralize(_ count: Int, _ unit: String) -> String {
        count == 1 ? "1 \(unit)" : "\(count) \(unit)s"
    }
}
