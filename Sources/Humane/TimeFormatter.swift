import Foundation

/// Formats one time relative to another the way Finder-adjacent tools do.
public struct TimeFormatter {
    /// Below a minute, collapse to "less than a minute ago"/"in less than a minute". Matches ActionView's `include_seconds` default.
    public var includeSeconds: Bool

    /// Prefix "about"/"in about" on buckets of an hour or more, matching ActionView's `distance_of_time_in_words`.
    public var approximate: Bool

    public init(includeSeconds: Bool = false, approximate: Bool = false) {
        self.includeSeconds = includeSeconds
        self.approximate = approximate
    }

    public func string(for date: Date, relativeTo referenceDate: Date) -> String {
        let seconds = abs(referenceDate.timeIntervalSince(date))
        let future = date > referenceDate

        if !includeSeconds && seconds < 60 {
            return future ? "in less than a minute" : "less than a minute ago"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        var text = formatter.localizedString(for: date, relativeTo: referenceDate)

        // RelativeDateTimeFormatter calls an exact-zero delta "in 0 seconds"; this library treats zero as past-tense.
        if seconds == 0, text.hasPrefix("in ") {
            text = text.dropFirst(3) + " ago"
        }

        guard approximate, seconds >= 3600 else { return text }

        // English-only string surgery -- RelativeDateTimeFormatter has no "approximate" option to ask for directly.
        return text.hasPrefix("in ") ? "in about " + text.dropFirst(3) : "about " + text
    }
}
