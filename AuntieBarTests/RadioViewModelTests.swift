import XCTest
@testable import AuntieBar

@MainActor
final class RadioViewModelTests: XCTestCase {
    var mockPlayer: MockRadioPlayer!
    var viewModel: RadioViewModel!

    override func setUp() {
        super.setUp()
        // Clear any saved volume from previous tests
        UserDefaults.standard.removeObject(forKey: "savedVolume")
        mockPlayer = MockRadioPlayer()
        viewModel = RadioViewModel(player: mockPlayer)
    }

    override func tearDown() {
        mockPlayer = nil
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
            category: .national
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
            category: .national
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
            category: .national
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
            category: .national
        )
        let station2 = RadioStation(
            name: "Station 2",
            streamURL: URL(string: "http://example.com/stream2.m3u8")!,
            category: .national
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
            category: .national
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
}
