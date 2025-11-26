import Foundation

/// Protocol for fetching now-playing information
protocol NowPlayingServiceProtocol: Actor {
    func fetchNowPlaying(for serviceId: String) async -> NowPlayingInfo?
    func fetchNowNext(for serviceId: String) async -> NowNextInfo?
}
