import Foundation

/// Protocol for fetching now-playing information
protocol NowPlayingServiceProtocol: Actor {
    func fetchNowPlaying(for serviceId: String) async -> NowPlayingInfo?
}
