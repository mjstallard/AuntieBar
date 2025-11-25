import XCTest
@testable import AuntieBar

final class PlaybackStateTests: XCTestCase {

    func testIdleIsNotPlaying() {
        // Given
        let state = PlaybackState.idle

        // Then
        XCTAssertFalse(state.isPlaying)
    }

    func testLoadingIsNotPlaying() {
        // Given
        let state = PlaybackState.loading

        // Then
        XCTAssertFalse(state.isPlaying)
    }

    func testPlayingIsPlaying() {
        // Given
        let station = RadioStation(
            name: "Test",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_test"
        )
        let state = PlaybackState.playing(station)

        // Then
        XCTAssertTrue(state.isPlaying)
    }

    func testFailedIsNotPlaying() {
        // Given
        let state = PlaybackState.failed(.networkError)

        // Then
        XCTAssertFalse(state.isPlaying)
    }

    func testPlaybackStateEquality() {
        // Given
        let station = RadioStation(
            name: "Test",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_test"
        )

        // Then
        XCTAssertEqual(PlaybackState.idle, PlaybackState.idle)
        XCTAssertEqual(PlaybackState.loading, PlaybackState.loading)
        XCTAssertEqual(PlaybackState.playing(station), PlaybackState.playing(station))
        XCTAssertEqual(
            PlaybackState.failed(.networkError),
            PlaybackState.failed(.networkError)
        )
    }
}

final class RadioPlayerErrorTests: XCTestCase {

    func testErrorDescriptions() {
        // Then
        XCTAssertEqual(
            RadioPlayerError.invalidURL.errorDescription,
            "Invalid streaming URL"
        )
        XCTAssertEqual(
            RadioPlayerError.networkError.errorDescription,
            "Network connection error"
        )
        XCTAssertEqual(
            RadioPlayerError.playbackFailed("test").errorDescription,
            "Playback failed: test"
        )
    }

    func testErrorEquality() {
        // Then
        XCTAssertEqual(RadioPlayerError.invalidURL, RadioPlayerError.invalidURL)
        XCTAssertEqual(RadioPlayerError.networkError, RadioPlayerError.networkError)
        XCTAssertEqual(
            RadioPlayerError.playbackFailed("test"),
            RadioPlayerError.playbackFailed("test")
        )
    }
}
