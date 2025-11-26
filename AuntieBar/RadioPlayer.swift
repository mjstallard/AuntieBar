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

    private(set) var audioQualityMetrics: AudioQualityMetrics? {
        didSet {
            metricsSubject.send(audioQualityMetrics)
        }
    }

    var volume: Double {
        get { Double(player?.volume ?? 0.5) }
        set { player?.volume = Float(newValue) }
    }

    private var player: AVPlayer?
    private var playerObserver: NSKeyValueObservation?
    private var metricsTimer: Timer?
    private let stateSubject = PassthroughSubject<PlaybackState, Never>()
    private let metricsSubject = PassthroughSubject<AudioQualityMetrics?, Never>()
    private var nominalBitrate: Double?
    private var nominalBitrateCache: [URL: Double] = [:]

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var metricsPublisher: AnyPublisher<AudioQualityMetrics?, Never> {
        metricsSubject.eraseToAnyPublisher()
    }

    private init() {}

    deinit {
        playerObserver?.invalidate()
        metricsTimer?.invalidate()
    }

    func play(station: RadioStation) async throws {
        playbackState = .loading
        currentStation = station

        // Clean up existing player
        player?.pause()
        playerObserver?.invalidate()
        metricsTimer?.invalidate()
        audioQualityMetrics = nil
        nominalBitrate = nil

        let playerItem = AVPlayerItem(url: station.streamURL)
        let newPlayer = AVPlayer(playerItem: playerItem)

        // Preserve volume from previous player
        let currentVolume = player?.volume ?? 0.5
        newPlayer.volume = currentVolume

        player = newPlayer

        Task { await self.populateNominalBitrate(for: station.streamURL) }

        // Observe player status for error handling
        observePlayerStatus(for: playerItem, station: station)

        // Start metrics monitoring
        startMetricsMonitoring()

        player?.play()
        playbackState = .playing(station)
    }

    func stop() {
        player?.pause()
        playerObserver?.invalidate()
        metricsTimer?.invalidate()
        currentStation = nil
        audioQualityMetrics = nil
        nominalBitrate = nil
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
                // Extract initial format information when ready
                self.updateAudioQualityMetrics()

            case .unknown:
                break

            @unknown default:
                break
            }
        }
    }

    // MARK: - Audio Quality Metrics

    private func startMetricsMonitoring() {
        // Update metrics immediately
        updateAudioQualityMetrics()

        // Then update every 5 seconds
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateAudioQualityMetrics()
        }
    }

    private func updateAudioQualityMetrics() {
        guard let playerItem = player?.currentItem else {
            audioQualityMetrics = nil
            return
        }

        // Extract metrics from access log
        var indicatedBitrate: Double?
        var observedBitrate: Double?
        var stallCount: Int?
        var bytesTransferred: Int64?

        if let accessLog = playerItem.accessLog(),
           let lastEvent = accessLog.events.last {
            // Prefer manifest-indicated bitrate; fall back to access log if missing
            indicatedBitrate = nominalBitrate ?? (lastEvent.indicatedBitrate > 0 ? lastEvent.indicatedBitrate : nil)
            observedBitrate = lastEvent.observedBitrate > 0 ? lastEvent.observedBitrate : nil
            stallCount = lastEvent.numberOfStalls
            bytesTransferred = lastEvent.numberOfBytesTransferred
        }

        // Extract format information from asset tracks asynchronously
        let asset = playerItem.asset
        Task {
            let (sampleRate, channelCount, codec) = await extractAudioFormat(from: asset)

            // Update metrics on main thread
            await MainActor.run {
                self.audioQualityMetrics = AudioQualityMetrics(
                    indicatedBitrate: indicatedBitrate,
                    observedBitrate: observedBitrate,
                    sampleRate: sampleRate,
                    channelCount: channelCount,
                    codec: codec,
                    stallCount: stallCount,
                    bytesTransferred: bytesTransferred
                )
            }
        }
    }

    private func populateNominalBitrate(for url: URL) async {
        if let cached = nominalBitrateCache[url] {
            await MainActor.run { self.nominalBitrate = cached }
            return
        }

        let manifestBitrate = await HLSManifestParser.fetchNominalBitrate(from: url)
        let fallbackBitrate = HLSManifestParser.parseBitrateFromURL(url)

        let resolvedBitrate = manifestBitrate ?? fallbackBitrate

        if let resolvedBitrate {
            nominalBitrateCache[url] = resolvedBitrate
            await MainActor.run {
                self.nominalBitrate = resolvedBitrate
                self.updateAudioQualityMetrics()
            }
        }
    }

    private func extractAudioFormat(from asset: AVAsset) async -> (sampleRate: Double?, channelCount: Int?, codec: String?) {
        // Keep this light: we only expose codec/channels; sample rate is omitted to avoid misleading values.
        guard let urlAsset = asset as? AVURLAsset else {
            return (nil, nil, nil)
        }

        let urlString = urlAsset.url.absoluteString

        // BBC fallback: AAC stereo; leave sample rate unknown (nil)
        if urlString.contains("bbc_radio") || urlString.contains("bbc.co.uk") {
            return (nil, 2, "AAC")
        }

        return (nil, nil, nil)
    }
}
