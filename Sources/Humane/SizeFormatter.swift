import Foundation

/// Formats byte counts the way Finder does.
public struct SizeFormatter {
    public init() {}

    public func string(fromByteCount byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }

    /// Positional alias for `string(fromByteCount:)`, matching `humane` (Go)'s label-free calling convention. See docs/COMMENTS.md.
    public func string(_ byteCount: Int) -> String {
        string(fromByteCount: byteCount)
    }
}
