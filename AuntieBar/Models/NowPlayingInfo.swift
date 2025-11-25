import Foundation

/// Represents currently playing track information for a BBC radio station
struct NowPlayingInfo: Equatable {
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
struct BBCNowPlayingResponse: Codable {
    let data: [BBCSegment]
}

struct BBCSegment: Codable {
    let segment_type: String
    let titles: BBCTitles?
    let images: BBCImages?

    enum CodingKeys: String, CodingKey {
        case segment_type
        case titles
        case images
    }
}

struct BBCImages: Codable {
    let standard: BBCImageRef?
}

struct BBCImageRef: Codable {
    let href: String
}

struct BBCTitles: Codable {
    let primary: String?
    let secondary: String?
}
