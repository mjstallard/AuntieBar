import Foundation

/// Represents currently playing track information for a BBC radio station
struct NowPlayingInfo: Equatable, Sendable {
    let artist: String?
    let title: String?
    let artworkURL: URL?

    /// Returns true if there's any metadata available
    var hasMetadata: Bool {
        artist != nil || title != nil
    }

    /// Returns formatted track info as "Artist – Track"
    var formattedTrackInfo: String? {
        guard let artist = artist, let title = title else {
            return nil
        }
        return "\(artist) – \(title)"
    }
}

/// API response structures for BBC Now Playing API
/// Note: Swift 6 migration - @unchecked Sendable used for immutable value types
/// Warning about MainActor isolation will be resolved in full Swift 6 migration
struct BBCNowPlayingResponse: Codable, @unchecked Sendable {
    let data: [BBCSegment]
}

struct BBCSegment: Codable, @unchecked Sendable {
    let segment_type: String
    let titles: BBCTitles?
    let image_url: String?

    enum CodingKeys: String, CodingKey {
        case segment_type
        case titles
        case image_url
    }
}

struct BBCTitles: Codable, @unchecked Sendable {
    let primary: String?
    let secondary: String?
}
