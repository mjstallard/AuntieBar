import XCTest
@testable import AuntieBar

@MainActor
final class RadioViewModelTests: XCTestCase {
    var mockPlayer: MockRadioPlayer!
    var mockNowPlayingService: MockNowPlayingService!
    var viewModel: RadioViewModel!

    override func setUp() {
        super.setUp()
        // Clear any saved volume from previous tests
        UserDefaults.standard.removeObject(forKey: "savedVolume")
        mockPlayer = MockRadioPlayer()
        mockNowPlayingService = MockNowPlayingService()
        viewModel = RadioViewModel(player: mockPlayer, nowPlayingService: mockNowPlayingService)
    }

    override func tearDown() {
        mockPlayer = nil
        mockNowPlayingService = nil
        viewModel = nil
        // Clean up saved volume
        UserDefaults.standard.removeObject(forKey: "savedVolume")
        super.tearDown()
    }

    func testInitialState() {
        // Then
        XCTAssertEqual(viewModel.playbackState, .idle)
        XCTAssertNil(viewModel.currentStation)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertGreaterThan(viewModel.allStations.count, 0)
    }

    func testPlayStation() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_test"
        )

        // When
        viewModel.play(station: station)

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockPlayer.playCallCount, 1)
        XCTAssertEqual(mockPlayer.lastPlayedStation?.name, station.name)
        XCTAssertEqual(viewModel.currentStation?.name, station.name)
    }

    func testStopPlayback() {
        // When
        viewModel.stop()

        // Then
        XCTAssertEqual(mockPlayer.stopCallCount, 1)
        XCTAssertNil(viewModel.currentStation)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testTogglePlaybackStartsPlayback() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_test"
        )

        // When
        viewModel.togglePlayback(for: station)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockPlayer.playCallCount, 1)
    }

    func testTogglePlaybackStopsPlayback() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_test"
        )

        // Start playback
        viewModel.play(station: station)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When - toggle again to stop
        viewModel.togglePlayback(for: station)

        // Then
        XCTAssertEqual(mockPlayer.stopCallCount, 1)
    }

    func testIsCurrentlyPlaying() async {
        // Given
        let station1 = RadioStation(
            name: "Station 1",
            streamURL: URL(string: "http://example.com/stream1.m3u8")!,
            category: .national,
            serviceId: "bbc_test1"
        )
        let station2 = RadioStation(
            name: "Station 2",
            streamURL: URL(string: "http://example.com/stream2.m3u8")!,
            category: .national,
            serviceId: "bbc_test2"
        )

        // When
        viewModel.play(station: station1)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertTrue(viewModel.isCurrentlyPlaying(station1))
        XCTAssertFalse(viewModel.isCurrentlyPlaying(station2))
    }

    func testPlaybackError() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_test"
        )
        mockPlayer.shouldFailPlayback = true

        // When
        viewModel.play(station: station)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.currentStation)
    }

    func testStationsByCategory() {
        // When
        let categories = viewModel.stationsByCategory

        // Then
        XCTAssertTrue(categories.keys.contains(.national))
        XCTAssertTrue(categories.keys.contains(.regional))
        XCTAssertTrue(categories.keys.contains(.nations))
    }

    func testSortedCategories() {
        // When
        let sorted = viewModel.sortedCategories

        // Then
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0], .national)
    }

    // MARK: - Volume Persistence Tests

    func testDefaultVolumeWhenNoSavedValue() {
        // Given - setUp already cleared UserDefaults
        // When - viewModel was initialized in setUp

        // Then
        XCTAssertEqual(viewModel.volume, 0.5, accuracy: 0.01)
        XCTAssertEqual(mockPlayer.volume, 0.5, accuracy: 0.01)
    }

    func testVolumeChangesSavedToUserDefaults() {
        // Given
        let newVolume = 0.75

        // When
        viewModel.volume = newVolume

        // Then
        let savedVolume = UserDefaults.standard.double(forKey: "savedVolume")
        XCTAssertEqual(savedVolume, newVolume, accuracy: 0.01)
    }

    func testVolumeChangesUpdatePlayer() {
        // Given
        let newVolume = 0.25

        // When
        viewModel.volume = newVolume

        // Then
        XCTAssertEqual(mockPlayer.volume, newVolume, accuracy: 0.01)
    }

    func testVolumeLoadedFromUserDefaults() async {
        // Given
        let savedVolume = 0.8
        UserDefaults.standard.set(savedVolume, forKey: "savedVolume")

        // When - create new viewModel that should load the saved volume
        let newMockPlayer = MockRadioPlayer()
        let newViewModel = RadioViewModel(player: newMockPlayer)

        // Small delay to ensure initialization completes
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then
        XCTAssertEqual(newViewModel.volume, savedVolume, accuracy: 0.01)
        XCTAssertEqual(newMockPlayer.volume, savedVolume, accuracy: 0.01)
    }

    func testVolumePersistsAcrossMultipleChanges() {
        // Given
        let volumes: [Double] = [0.1, 0.3, 0.7, 0.9]

        // When
        for volume in volumes {
            viewModel.volume = volume

            // Then - verify it's saved immediately
            let savedVolume = UserDefaults.standard.double(forKey: "savedVolume")
            XCTAssertEqual(savedVolume, volume, accuracy: 0.01)
        }

        // Final verification
        XCTAssertEqual(viewModel.volume, volumes.last!, accuracy: 0.01)
    }

    // MARK: - Now Playing Tests

    func testInitialNowPlayingState() {
        // Then
        XCTAssertNil(viewModel.nowPlayingInfo)
    }

    func testPlayStationFetchesNowPlayingInfo() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_6music"
        )
        let expectedInfo = NowPlayingInfo(
            artist: "The Beatles",
            title: "Hey Jude",
            artworkURL: URL(string: "https://example.com/artwork.jpg"),
            artworkURLTemplate: nil
        )
        mockNowPlayingService.mockNowPlayingInfo = expectedInfo

        // When
        viewModel.play(station: station)
        try? await Task.sleep(nanoseconds: 300_000_000) // Wait for async operations

        // Then
        let fetchCount = mockNowPlayingService.fetchCallCount
        let lastServiceId = mockNowPlayingService.lastServiceIdFetched
        XCTAssertEqual(fetchCount, 1)
        XCTAssertEqual(lastServiceId, "bbc_6music")
        XCTAssertEqual(viewModel.nowPlayingInfo?.artist, "The Beatles")
        XCTAssertEqual(viewModel.nowPlayingInfo?.title, "Hey Jude")
    }

    func testStopClearsNowPlayingInfo() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_one"
        )
        let expectedInfo = NowPlayingInfo(
            artist: "Radiohead",
            title: "Creep",
            artworkURL: nil,
            artworkURLTemplate: nil
        )
        mockNowPlayingService.mockNowPlayingInfo = expectedInfo

        // Start playback
        viewModel.play(station: station)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Verify we have now playing info
        XCTAssertNotNil(viewModel.nowPlayingInfo)

        // When
        viewModel.stop()

        // Then
        XCTAssertNil(viewModel.nowPlayingInfo)
    }

    func testNowPlayingInfoUpdatesWithPolling() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_6music"
        )
        let initialInfo = NowPlayingInfo(
            artist: "The Beatles",
            title: "Hey Jude",
            artworkURL: nil,
            artworkURLTemplate: nil
        )
        mockNowPlayingService.mockNowPlayingInfo = initialInfo

        // When - start playback
        viewModel.play(station: station)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Verify initial fetch
        var fetchCount = mockNowPlayingService.fetchCallCount
        XCTAssertEqual(fetchCount, 1)
        XCTAssertEqual(viewModel.nowPlayingInfo?.artist, "The Beatles")

        // Update mock to return different info for polling
        let updatedInfo = NowPlayingInfo(
            artist: "Pink Floyd",
            title: "Comfortably Numb",
            artworkURL: nil,
            artworkURLTemplate: nil
        )
        mockNowPlayingService.mockNowPlayingInfo = updatedInfo

        // Wait for polling interval (slightly more than 30 seconds)
        try? await Task.sleep(nanoseconds: 31_000_000_000)

        // Then - should have polled again
        fetchCount = mockNowPlayingService.fetchCallCount
        XCTAssertGreaterThan(fetchCount, 1)
        XCTAssertEqual(viewModel.nowPlayingInfo?.artist, "Pink Floyd")
    }

    func testNowPlayingPollingStopsWhenStationStopped() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_two"
        )
        mockNowPlayingService.mockNowPlayingInfo = NowPlayingInfo(
            artist: "Test Artist",
            title: "Test Track",
            artworkURL: nil,
            artworkURLTemplate: nil
        )

        // Start playback
        viewModel.play(station: station)
        try? await Task.sleep(nanoseconds: 300_000_000)

        let initialFetchCount = mockNowPlayingService.fetchCallCount

        // When - stop playback
        viewModel.stop()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Wait to ensure polling would have occurred if it was still running
        try? await Task.sleep(nanoseconds: 31_000_000_000)

        // Then - no additional fetches should have occurred
        let finalFetchCount = mockNowPlayingService.fetchCallCount
        XCTAssertEqual(finalFetchCount, initialFetchCount)
    }

    func testNowPlayingHandlesNilResponse() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_four"
        )
        mockNowPlayingService.shouldReturnNil = true

        // When
        viewModel.play(station: station)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertNil(viewModel.nowPlayingInfo)
        let fetchCount = mockNowPlayingService.fetchCallCount
        XCTAssertEqual(fetchCount, 1) // Should still try to fetch
    }

    func testTogglePlaybackFetchesNowPlayingInfo() async {
        // Given
        let station = RadioStation(
            name: "Test Station",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_three"
        )
        let expectedInfo = NowPlayingInfo(
            artist: "Mozart",
            title: "Symphony No. 40",
            artworkURL: nil,
            artworkURLTemplate: nil
        )
        mockNowPlayingService.mockNowPlayingInfo = expectedInfo

        // When
        viewModel.togglePlayback(for: station)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        let fetchCount = mockNowPlayingService.fetchCallCount
        XCTAssertEqual(fetchCount, 1)
        XCTAssertEqual(viewModel.nowPlayingInfo?.artist, "Mozart")
    }

    func testSwitchingStationsFetchesNewNowPlayingInfo() async {
        // Given
        let station1 = RadioStation(
            name: "Station 1",
            streamURL: URL(string: "http://example.com/stream1.m3u8")!,
            category: .national,
            serviceId: "bbc_6music"
        )
        let station2 = RadioStation(
            name: "Station 2",
            streamURL: URL(string: "http://example.com/stream2.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_one"
        )

        let info1 = NowPlayingInfo(artist: "Artist 1", title: "Track 1", artworkURL: nil, artworkURLTemplate: nil)
        let info2 = NowPlayingInfo(artist: "Artist 2", title: "Track 2", artworkURL: nil, artworkURLTemplate: nil)

        // Play first station
        mockNowPlayingService.mockNowPlayingInfo = info1
        viewModel.play(station: station1)
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(viewModel.nowPlayingInfo?.artist, "Artist 1")

        // When - switch to second station
        mockNowPlayingService.mockNowPlayingInfo = info2
        viewModel.play(station: station2)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        let fetchCount = mockNowPlayingService.fetchCallCount
        let lastServiceId = mockNowPlayingService.lastServiceIdFetched
        XCTAssertEqual(fetchCount, 2) // Once for each station
        XCTAssertEqual(lastServiceId, "bbc_radio_one")
        XCTAssertEqual(viewModel.nowPlayingInfo?.artist, "Artist 2")
    }
}
