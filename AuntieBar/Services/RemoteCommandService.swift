import MediaPlayer

final class RemoteCommandService {
    static let shared = RemoteCommandService()

    private let commandCenter = MPRemoteCommandCenter.shared()
    private var isConfigured = false
    private weak var viewModel: RadioViewModel?

    func bind(to viewModel: RadioViewModel) {
        self.viewModel = viewModel
        configureIfNeeded()
        updateCommandAvailability(for: viewModel.playbackState)
        updateNowPlayingInfo(
            station: viewModel.currentStation,
            nowPlayingInfo: viewModel.nowPlayingInfo,
            playbackState: viewModel.playbackState
        )
    }

    func updateCommandAvailability(for state: PlaybackState) {
        commandCenter.togglePlayPauseCommand.isEnabled = state.isPlaying || state.isPaused
        commandCenter.playCommand.isEnabled = state.isPaused
        commandCenter.pauseCommand.isEnabled = state.isPlaying
    }

    func updateNowPlayingInfo(
        station: RadioStation?,
        nowPlayingInfo: NowPlayingInfo?,
        playbackState: PlaybackState
    ) {
        guard let station else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            MPNowPlayingInfoCenter.default().playbackState = .stopped
            return
        }

        var info: [String: Any] = [:]
        let title = nowPlayingInfo?.title ?? station.name
        let artist = nowPlayingInfo?.artist ?? station.name
        let programme = nowPlayingInfo?.programmeTitle ?? station.name

        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = artist
        info[MPMediaItemPropertyAlbumTitle] = programme
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = playbackState.isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = playbackState.isPlaying ? .playing : .paused
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] (_: MPRemoteCommandEvent) in
            guard let self else { return MPRemoteCommandHandlerStatus.commandFailed }
            return self.handlePlayPause()
        }

        commandCenter.playCommand.addTarget { [weak self] (_: MPRemoteCommandEvent) in
            guard let self else { return MPRemoteCommandHandlerStatus.commandFailed }
            return self.handlePlay()
        }

        commandCenter.pauseCommand.addTarget { [weak self] (_: MPRemoteCommandEvent) in
            guard let self else { return MPRemoteCommandHandlerStatus.commandFailed }
            return self.handlePause()
        }
    }

    private func handlePlayPause() -> MPRemoteCommandHandlerStatus {
        guard let viewModel else { return .commandFailed }
        return viewModel.handleRemotePlayPause() ? .success : .commandFailed
    }

    private func handlePlay() -> MPRemoteCommandHandlerStatus {
        guard let viewModel else { return .commandFailed }
        return viewModel.handleRemotePlay() ? .success : .commandFailed
    }

    private func handlePause() -> MPRemoteCommandHandlerStatus {
        guard let viewModel else { return .commandFailed }
        return viewModel.handleRemotePause() ? .success : .commandFailed
    }
}
