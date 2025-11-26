import Foundation

/// Represents currently playing track information for a BBC radio station
struct NowPlayingInfo: Equatable, Sendable {
    let artist: String?
    let title: String?
    let artworkURL: URL?
    let artworkURLTemplate: String?  // Original template URL with {recipe} placeholder
    let programmeTitle: String?  // The show/programme name (e.g., "Chris Hawkins")
    let programmeSynopsis: String?  // Short description of the show

    /// All possible artwork URLs (primary first, then fallbacks) with duplicates removed
    var artworkCandidates: [URL] {
        var candidates: [URL] = []

        if let artworkURL {
            candidates.append(artworkURL)
        }

        candidates.append(contentsOf: fallbackArtworkURLs)

        var seen = Set<URL>()
        return candidates.filter { seen.insert($0).inserted }
    }

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

    /// Generate fallback artwork URLs with different recipes
    var fallbackArtworkURLs: [URL] {
        guard let template = artworkURLTemplate else { return [] }
        let recipes = ["256x256", "192x192", "128x128", "64x64"]
        return recipes.compactMap { recipe in
            URL(string: template.replacingOccurrences(of: "{recipe}", with: recipe))
        }
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

// MARK: - Broadcast API Response

struct BBCBroadcastResponse: Codable, @unchecked Sendable {
    let data: [BBCBroadcast]
}

struct BBCBroadcast: Codable, @unchecked Sendable {
    let titles: BBCBroadcastTitles?
    let synopses: BBCBroadcastSynopses?

    enum CodingKeys: String, CodingKey {
        case titles
        case synopses
    }
}

struct BBCBroadcastTitles: Codable, @unchecked Sendable {
    let primary: String?
}

struct BBCBroadcastSynopses: Codable, @unchecked Sendable {
    let short: String?
}
