import Foundation

/// Formats byte counts the way Finder does.
public enum SizeFormatter {
    /// Returns byteCount as a Finder-style human-readable string. A thin
    /// wrapper over `ByteCountFormatter` -- see docs/COMMENTS.md for why
    /// this package doesn't hand-roll the same math `humane`/`humane-ruby`
    /// do.
    ///
    ///     SizeFormatter.humanSize(225_935) // "226 KB"
    public static func humanSize(_ byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }
}
