import XCTest
@testable import AuntieBar

@MainActor
final class RadioViewModelTests: XCTestCase {
    var mockPlayer: MockRadioPlayer!
    var viewModel: RadioViewModel!

    override func setUp() {
        super.setUp()
        mockPlayer = MockRadioPlayer()
        viewModel = RadioViewModel(player: mockPlayer)
    }

    override func tearDown() {
        mockPlayer = nil
        viewModel = nil
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
}
