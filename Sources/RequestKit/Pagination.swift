import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Pagination links parsed from an RFC 5988 `Link` response header.
public struct PageInfo {
    public let next: URL?
    public let prev: URL?
    public let first: URL?
    public let last: URL?

    public var hasNextPage: Bool { next != nil }

    /// Parse a Link header value, e.g.:
    /// `<https://api.github.com/repos?page=2>; rel="next", <https://api.github.com/repos?page=5>; rel="last"`
    public init(linkHeader: String?) {
        guard let header = linkHeader else {
            next = nil; prev = nil; first = nil; last = nil
            return
        }
        var links: [String: URL] = [:]
        let entries = header.components(separatedBy: ", ")
        for entry in entries {
            let parts = entry.components(separatedBy: "; ")
            guard parts.count == 2 else { continue }
            let urlPart = parts[0].trimmingCharacters(in: .whitespaces)
            let relPart = parts[1].trimmingCharacters(in: .whitespaces)
            guard urlPart.hasPrefix("<"), urlPart.hasSuffix(">") else { continue }
            let urlString = String(urlPart.dropFirst().dropLast())
            guard let url = URL(string: urlString) else { continue }
            let relValue = relPart
                .replacingOccurrences(of: "rel=", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .trimmingCharacters(in: .whitespaces)
            links[relValue] = url
        }
        next = links["next"]
        prev = links["prev"]
        first = links["first"]
        last = links["last"]
    }
}

/// A decoded response along with its pagination metadata.
public struct PaginatedResponse<T> {
    public let values: T
    public let pageInfo: PageInfo
}
