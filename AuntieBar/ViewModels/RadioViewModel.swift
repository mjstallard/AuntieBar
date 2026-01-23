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
    private(set) var nowPlayingInfo: NowPlayingInfo?
    private(set) var nowNextInfo: NowNextInfo?
    private(set) var audioQualityMetrics: AudioQualityMetrics?
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
    private let nowPlayingService: any NowPlayingServiceProtocol
    private let pollingInterval: TimeInterval
    private let remoteCommandService: RemoteCommandService
    private var cancellables = Set<AnyCancellable>()
    private var pollingTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        player: RadioPlayerProtocol = RadioPlayer.shared,
        nowPlayingService: any NowPlayingServiceProtocol = NowPlayingService(),
        pollingInterval: TimeInterval = 30.0,
        remoteCommandService: RemoteCommandService = .shared
    ) {
        self.player = player
        self.nowPlayingService = nowPlayingService
        self.pollingInterval = pollingInterval
        self.remoteCommandService = remoteCommandService
        self.allStations = RadioStationsData.allStations
        self.stationsByCategory = RadioStationsData.stationsByCategory
        self.sortedCategories = RadioStationsData.sortedCategories

        // Load saved volume or default to 0.5
        let savedVolume = UserDefaults.standard.object(forKey: "savedVolume") as? Double ?? 0.5
        self.volume = savedVolume
        player.volume = savedVolume

        setupBindings()
        remoteCommandService.bind(to: self)
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Public Methods

    func play(station: RadioStation) {
        Task { @MainActor in
            errorMessage = nil
            isLoading = true

            do {
                try await player.play(station: station)
                currentStation = station

                // Fetch initial now-playing info and start polling
                await fetchNowPlayingInfo(for: station)
                startPolling(for: station)
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
        stopPolling()
        nowPlayingInfo = nil
        nowNextInfo = nil
    }

    func pause() {
        Task { @MainActor in
            player.pause()
            stopPolling()
        }
    }

    func resume() {
        Task { @MainActor in
            guard let station = currentStation else { return }
            player.resume()
            await fetchNowPlayingInfo(for: station)
            startPolling(for: station)
        }
    }

    func togglePlayback(for station: RadioStation) {
        if currentStation?.id == station.id {
            if playbackState.isPlaying {
                stop()
            } else if playbackState.isPaused {
                resume()
            } else {
                play(station: station)
            }
        } else {
            play(station: station)
        }
    }

    func isCurrentlyPlaying(_ station: RadioStation) -> Bool {
        currentStation?.id == station.id && playbackState.isPlaying
    }

    func stations(for category: RadioStationCategory, hideUKOnly: Bool) -> [RadioStation] {
        let stations = stationsByCategory[category] ?? []
        guard hideUKOnly else { return stations }
        return stations.filter { !$0.isUKOnly }
    }

    func categories(hideUKOnly: Bool) -> [RadioStationCategory] {
        sortedCategories.filter { !stations(for: $0, hideUKOnly: hideUKOnly).isEmpty }
    }

    var ukOnlyStationCount: Int {
        allStations.filter { $0.isUKOnly }.count
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Observe player state changes
        player.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.playbackState = state
                self.remoteCommandService.updateCommandAvailability(for: state)
                self.remoteCommandService.updateNowPlayingInfo(
                    station: self.currentStation,
                    nowPlayingInfo: self.nowPlayingInfo,
                    playbackState: state
                )
            }
            .store(in: &cancellables)

        // Observe audio quality metrics changes
        player.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.audioQualityMetrics = metrics
            }
            .store(in: &cancellables)
    }

    // MARK: - Now Playing

    private func fetchNowPlayingInfo(for station: RadioStation) async {
        async let info = nowPlayingService.fetchNowPlaying(for: station.serviceId)
        async let nowNext = nowPlayingService.fetchNowNext(for: station.serviceId)

        let (nowPlaying, schedule) = await (info, nowNext)
        await MainActor.run {
            nowPlayingInfo = nowPlaying
            nowNextInfo = schedule
            remoteCommandService.updateNowPlayingInfo(
                station: currentStation,
                nowPlayingInfo: nowPlayingInfo,
                playbackState: playbackState
            )
        }
    }

    private func startPolling(for station: RadioStation) {
        // Cancel any existing polling task
        pollingTask?.cancel()

        pollingTask = Task {
            while !Task.isCancelled {
                // Wait for polling interval
                try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))

                guard !Task.isCancelled else { break }

                // Fetch updated now-playing info
                await fetchNowPlayingInfo(for: station)
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Remote Commands

    func handleRemotePlayPause() -> Bool {
        if playbackState.isPlaying {
            pause()
            return true
        }

        if playbackState.isPaused {
            resume()
            return true
        }

        return false
    }

    func handleRemotePlay() -> Bool {
        if playbackState.isPaused {
            resume()
            return true
        }

        return false
    }

    func handleRemotePause() -> Bool {
        if playbackState.isPlaying {
            pause()
            return true
        }

        return false
    }
}
