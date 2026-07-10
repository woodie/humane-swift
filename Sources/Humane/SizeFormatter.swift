import Foundation

/// Formats byte counts the way Finder does.
public struct SizeFormatter {
    public init() {}

    public func string(fromByteCount byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }
}
