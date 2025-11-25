import Foundation

/// Service for fetching now-playing information from BBC Radio API
actor NowPlayingService: NowPlayingServiceProtocol {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Fetches now-playing metadata for a given BBC service
    /// - Parameter serviceId: The BBC service ID (e.g., "bbc_6music", "bbc_radio_two")
    /// - Returns: NowPlayingInfo if available, nil on error or if no music is playing
    func fetchNowPlaying(for serviceId: String) async -> NowPlayingInfo? {
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
            if let imageHref = musicSegment.images?.standard?.href {
                // Replace {recipe} with 128x128
                let processedURL = imageHref.replacingOccurrences(of: "{recipe}", with: "128x128")
                artworkURL = URL(string: processedURL)
            }

            return NowPlayingInfo(
                artist: artist,
                title: title,
                artworkURL: artworkURL
            )
        } catch {
            // Fail quietly as per requirements
            return nil
        }
    }
}
