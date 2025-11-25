import Foundation
import Observation
import Combine

/// ViewModel managing radio station selection and playback state
@Observable
final class RadioViewModel {
    // MARK: - Published Properties
    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentStation: RadioStation?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    var volume: Double = 0.5 {
        didSet {
            player.volume = volume
            UserDefaults.standard.set(volume, forKey: "savedVolume")
        }
    }

    // MARK: - Data
    let allStations: [RadioStation]
    let stationsByCategory: [RadioStationCategory: [RadioStation]]
    let sortedCategories: [RadioStationCategory]

    // MARK: - Dependencies
    private let player: RadioPlayerProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(player: RadioPlayerProtocol = RadioPlayer.shared) {
        self.player = player
        self.allStations = RadioStationsData.allStations
        self.stationsByCategory = RadioStationsData.stationsByCategory
        self.sortedCategories = RadioStationsData.sortedCategories

        // Load saved volume or default to 0.5
        let savedVolume = UserDefaults.standard.object(forKey: "savedVolume") as? Double ?? 0.5
        self.volume = savedVolume
        player.volume = savedVolume

        setupBindings()
    }

    // MARK: - Public Methods

    func play(station: RadioStation) {
        Task { @MainActor in
            errorMessage = nil
            isLoading = true

            do {
                try await player.play(station: station)
                currentStation = station
            } catch {
                errorMessage = error.localizedDescription
                currentStation = nil
            }

            isLoading = false
        }
    }

    func stop() {
        player.stop()
        currentStation = nil
        errorMessage = nil
    }

    func togglePlayback(for station: RadioStation) {
        if currentStation?.id == station.id && playbackState.isPlaying {
            stop()
        } else {
            play(station: station)
        }
    }

    func isCurrentlyPlaying(_ station: RadioStation) -> Bool {
        currentStation?.id == station.id && playbackState.isPlaying
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Observe player state changes
        player.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.playbackState = state
            }
            .store(in: &cancellables)
    }
}
