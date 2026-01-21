import Foundation
import AVFoundation
import Combine

/// Protocol defining radio player capabilities for testability
protocol RadioPlayerProtocol: AnyObject {
    var playbackState: PlaybackState { get }
    var currentStation: RadioStation? { get }
    var volume: Double { get set }
    var statePublisher: AnyPublisher<PlaybackState, Never> { get }
    var metricsPublisher: AnyPublisher<AudioQualityMetrics?, Never> { get }

    func play(station: RadioStation) async throws
    func pause()
    func resume()
    func stop()
}

/// Represents the current playback state
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing(RadioStation)
    case paused(RadioStation)
    case failed(RadioPlayerError)

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }
}

/// Errors that can occur during radio playback
enum RadioPlayerError: LocalizedError, Equatable {
    case invalidURL
    case playbackFailed(String)
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid streaming URL"
        case .playbackFailed(let message):
            return "Playback failed: \(message)"
        case .networkError:
            return "Network connection error"
        }
    }
}
