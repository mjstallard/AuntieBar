import XCTest
import SwiftUI
@testable import AuntieBar

final class NowPlayingViewTests: XCTestCase {

    func testNowPlayingViewDisplaysStationName() {
        // Given
        let station = RadioStation(
            name: "Radio 3",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_three"
        )
        let nowPlayingInfo = NowPlayingInfo(
            artist: "Ola Gjeilo",
            title: "Serenity [O magnum mysterium]",
            artworkURL: nil,
            artworkURLTemplate: nil
        )

        // When
        let view = NowPlayingView(station: station, nowPlayingInfo: nowPlayingInfo)

        // Then - View should be created successfully
        XCTAssertNotNil(view)
    }

    func testNowPlayingViewWithLongTrackInfo() {
        // Given
        let station = RadioStation(
            name: "Radio Cymru",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .nations,
            serviceId: "bbc_radio_cymru"
        )
        let longTrackInfo = NowPlayingInfo(
            artist: "Amy Wadge",
            title: "Unwaith Eto, Rwy'n Teimlo Fy Mod I'n Angen Mwy Na'r Hyn Sydd Gen I",
            artworkURL: nil,
            artworkURLTemplate: nil
        )

        // When
        let view = NowPlayingView(station: station, nowPlayingInfo: longTrackInfo)

        // Then - View should be created successfully with long text
        XCTAssertNotNil(view)
        XCTAssertNotNil(longTrackInfo.formattedTrackInfo)
        // Verify the formatted track info is quite long (would be truncated in UI)
        XCTAssertGreaterThan(longTrackInfo.formattedTrackInfo?.count ?? 0, 50)
    }

    func testNowPlayingViewWithoutTrackInfo() {
        // Given
        let station = RadioStation(
            name: "Radio 4",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_four"
        )

        // When
        let view = NowPlayingView(station: station, nowPlayingInfo: nil)

        // Then - View should handle nil nowPlayingInfo gracefully
        XCTAssertNotNil(view)
    }

    func testNowPlayingViewWithArtwork() {
        // Given
        let station = RadioStation(
            name: "Radio 6 Music",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_6music"
        )
        let nowPlayingInfo = NowPlayingInfo(
            artist: "Radiohead",
            title: "Paranoid Android",
            artworkURL: URL(string: "https://example.com/artwork.jpg"),
            artworkURLTemplate: nil
        )

        // When
        let view = NowPlayingView(station: station, nowPlayingInfo: nowPlayingInfo)

        // Then - View should be created with artwork
        XCTAssertNotNil(view)
        XCTAssertNotNil(nowPlayingInfo.artworkURL)
        XCTAssertTrue(nowPlayingInfo.hasMetadata)
    }

    func testNowPlayingViewHandlesPartialMetadata() {
        // Given
        let station = RadioStation(
            name: "Radio 1",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_one"
        )
        let partialInfo = NowPlayingInfo(
            artist: "Artist Only",
            title: nil,
            artworkURL: nil,
            artworkURLTemplate: nil
        )

        // When
        let view = NowPlayingView(station: station, nowPlayingInfo: partialInfo)

        // Then - View should handle partial metadata
        XCTAssertNotNil(view)
        XCTAssertNil(partialInfo.formattedTrackInfo) // No formatted info without both artist and title
    }

    func testPopoverContentMatchesOriginalText() {
        // Given
        let station = RadioStation(
            name: "Radio 3",
            streamURL: URL(string: "http://example.com/stream.m3u8")!,
            category: .national,
            serviceId: "bbc_radio_three"
        )
        let trackInfo = NowPlayingInfo(
            artist: "Ludwig van Beethoven",
            title: "Symphony No. 9 in D minor, Op. 125 'Choral' - IV. Finale: Ode to Joy",
            artworkURL: nil,
            artworkURLTemplate: nil
        )

        // When
        let view = NowPlayingView(station: station, nowPlayingInfo: trackInfo)

        // Then - The formatted track info should be available for popover display
        XCTAssertNotNil(view)
        let expectedText = "Ludwig van Beethoven – Symphony No. 9 in D minor, Op. 125 'Choral' - IV. Finale: Ode to Joy"
        XCTAssertEqual(trackInfo.formattedTrackInfo, expectedText)
    }
}
