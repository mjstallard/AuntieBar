import AVFoundation
import Combine

/// Concrete implementation of RadioPlayerProtocol using AVPlayer
final class RadioPlayer: RadioPlayerProtocol {
    static let shared = RadioPlayer()

    private(set) var playbackState: PlaybackState = .idle {
        didSet {
            stateSubject.send(playbackState)
        }
    }

    private(set) var currentStation: RadioStation?

    var volume: Double {
        get { Double(player?.volume ?? 0.5) }
        set { player?.volume = Float(newValue) }
    }

    private var player: AVPlayer?
    private var playerObserver: NSKeyValueObservation?
    private let stateSubject = PassthroughSubject<PlaybackState, Never>()

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private init() {}

    deinit {
        playerObserver?.invalidate()
    }

    func play(station: RadioStation) async throws {
        playbackState = .loading
        currentStation = station

        // Clean up existing player
        player?.pause()
        playerObserver?.invalidate()

        let playerItem = AVPlayerItem(url: station.streamURL)
        let newPlayer = AVPlayer(playerItem: playerItem)

        // Preserve volume from previous player
        let currentVolume = player?.volume ?? 0.5
        newPlayer.volume = currentVolume

        player = newPlayer

        // Observe player status for error handling
        observePlayerStatus(for: playerItem, station: station)

        player?.play()
        playbackState = .playing(station)
    }

    func stop() {
        player?.pause()
        playerObserver?.invalidate()
        currentStation = nil
        playbackState = .idle
    }

    // MARK: - Private Methods

    private func observePlayerStatus(for item: AVPlayerItem, station: RadioStation) {
        playerObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }

            switch item.status {
            case .failed:
                let errorMessage = item.error?.localizedDescription ?? "Unknown error"
                self.playbackState = .failed(.playbackFailed(errorMessage))
                self.currentStation = nil

            case .readyToPlay:
                if case .loading = self.playbackState {
                    self.playbackState = .playing(station)
                }

            case .unknown:
                break

            @unknown default:
                break
            }
        }
    }
}
