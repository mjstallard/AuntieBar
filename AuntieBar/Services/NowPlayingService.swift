import Foundation

/// Service for fetching now-playing information from BBC Radio API
actor NowPlayingService: NowPlayingServiceProtocol {
    private let urlSession: URLSession
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Fetches now-playing metadata for a given BBC service
    /// - Parameter serviceId: The BBC service ID (e.g., "bbc_6music", "bbc_radio_two")
    /// - Returns: NowPlayingInfo if available, nil on error or if no music is playing
    func fetchNowPlaying(for serviceId: String) async -> NowPlayingInfo? {
        // Fetch both track info (segments) and programme info (broadcasts) in parallel
        async let trackInfo = fetchTrackInfo(for: serviceId)
        async let programmeInfo = fetchProgrammeInfo(for: serviceId)

        let (track, programme) = await (trackInfo, programmeInfo)

        // Return nil if no track is playing
        guard let track = track else {
            return nil
        }

        // Combine track and programme info
        return NowPlayingInfo(
            artist: track.artist,
            title: track.title,
            artworkURL: track.artworkURL,
            artworkURLTemplate: track.artworkURLTemplate,
            programmeTitle: programme?.programmeTitle,
            programmeSynopsis: programme?.programmeSynopsis
        )
    }

    func fetchNowNext(for serviceId: String) async -> NowNextInfo? {
        do {
            let broadcasts = try await fetchBroadcasts(for: serviceId, limit: 2)

            guard
                let current = broadcasts.first,
                let currentTitle = current.titles?.primary,
                let currentStart = current.start,
                let currentEnd = current.end
            else {
                return nil
            }

            let currentSlot = ProgrammeSlot(title: currentTitle, startTime: currentStart, endTime: currentEnd)

            var nextSlot: ProgrammeSlot?
            if broadcasts.count > 1,
               let nextTitle = broadcasts[1].titles?.primary,
               let nextStart = broadcasts[1].start,
               let nextEnd = broadcasts[1].end {
                nextSlot = ProgrammeSlot(title: nextTitle, startTime: nextStart, endTime: nextEnd)
            }

            return NowNextInfo(current: currentSlot, next: nextSlot)
        } catch {
            return nil
        }
    }

    /// Fetches track information from the segments API
    private func fetchTrackInfo(for serviceId: String) async -> (artist: String?, title: String?, artworkURL: URL?, artworkURLTemplate: String?)? {
        let urlString = "https://rms.api.bbc.co.uk/v2/services/\(serviceId)/segments/latest?experience=domestic&offset=0&limit=1"

        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await urlSession.data(from: url)
            let response = try JSONDecoder().decode(BBCNowPlayingResponse.self, from: data)

            // Find the first music segment
            guard let musicSegment = response.data.first(where: { $0.segment_type == "music" }) else {
                return nil
            }

            let artist = musicSegment.titles?.primary
            let title = musicSegment.titles?.secondary

            // Process artwork URL if available
            var artworkURL: URL? = nil
            var artworkTemplate: String? = nil
            if let imageURL = musicSegment.image_url {
                artworkTemplate = imageURL
                // Try different image sizes - BBC image service supports various recipes
                // Use 256x256 for better quality on retina displays
                let processedURL = imageURL.replacingOccurrences(of: "{recipe}", with: "256x256")
                artworkURL = URL(string: processedURL)
            }

            return (artist, title, artworkURL, artworkTemplate)
        } catch {
            // Fail quietly as per requirements
            return nil
        }
    }

    /// Fetches programme (show) information from the broadcasts API
    private func fetchProgrammeInfo(for serviceId: String) async -> (programmeTitle: String?, programmeSynopsis: String?)? {
        do {
            let broadcasts = try await fetchBroadcasts(for: serviceId, limit: 1)

            guard let broadcast = broadcasts.first else { return nil }
            return (broadcast.titles?.primary, broadcast.synopses?.short)
        } catch {
            // Fail quietly - programme info is optional
            return nil
        }
    }

    private func fetchBroadcasts(for serviceId: String, limit: Int) async throws -> [BBCBroadcast] {
        let urlString = "https://rms.api.bbc.co.uk/v2/broadcasts/poll/\(serviceId)?experience=domestic&offset=0&limit=\(limit)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await urlSession.data(from: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = NowPlayingService.iso8601Formatter.date(from: dateString) {
                return date
            }

            if let fallbackDate = ISO8601DateFormatter().date(from: dateString) {
                return fallbackDate
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(dateString)")
        }

        let response = try decoder.decode(BBCBroadcastResponse.self, from: data)
        return response.data
    }
}
