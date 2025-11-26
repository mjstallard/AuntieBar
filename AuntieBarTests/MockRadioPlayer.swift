import Foundation
import Combine
@testable import AuntieBar

/// Mock radio player for testing
final class MockRadioPlayer: RadioPlayerProtocol {
    private(set) var playbackState: PlaybackState = .idle {
        didSet {
            stateSubject.send(playbackState)
        }
    }
    private(set) var currentStation: RadioStation?
    var volume: Double = 0.5

    var shouldFailPlayback = false
    var playCallCount = 0
    var stopCallCount = 0
    var lastPlayedStation: RadioStation?

    private let stateSubject = PassthroughSubject<PlaybackState, Never>()
    private let metricsSubject = PassthroughSubject<AudioQualityMetrics?, Never>()

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var metricsPublisher: AnyPublisher<AudioQualityMetrics?, Never> {
        metricsSubject.eraseToAnyPublisher()
    }

    func play(station: RadioStation) async throws {
        playCallCount += 1
        lastPlayedStation = station

        if shouldFailPlayback {
            playbackState = .failed(.playbackFailed("Mock error"))
            throw RadioPlayerError.playbackFailed("Mock error")
        }

        playbackState = .loading
        currentStation = station
        playbackState = .playing(station)
    }

    func stop() {
        stopCallCount += 1
        playbackState = .idle
        currentStation = nil
    }

    // Test helpers
    func reset() {
        playCallCount = 0
        stopCallCount = 0
        lastPlayedStation = nil
        shouldFailPlayback = false
        playbackState = .idle
        currentStation = nil
    }
}
