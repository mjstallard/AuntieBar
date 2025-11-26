import XCTest
@testable import AuntieBar

final class NowPlayingInfoTests: XCTestCase {

    func testNowPlayingInfoWithAllFields() {
        // Given
        let artworkURL = URL(string: "https://example.com/artwork.jpg")!

        // When
        let info = NowPlayingInfo(
            artist: "The Beatles",
            title: "Hey Jude",
            artworkURL: artworkURL,
            artworkURLTemplate: nil,
            programmeTitle: nil,
            programmeSynopsis: nil
        )

        // Then
        XCTAssertEqual(info.artist, "The Beatles")
        XCTAssertEqual(info.title, "Hey Jude")
        XCTAssertEqual(info.artworkURL, artworkURL)
        XCTAssertTrue(info.hasMetadata)
        XCTAssertEqual(info.formattedTrackInfo, "The Beatles – Hey Jude")
    }

    func testNowPlayingInfoWithNoMetadata() {
        // When
        let info = NowPlayingInfo(
            artist: nil,
            title: nil,
            artworkURL: nil,
            artworkURLTemplate: nil,
            programmeTitle: nil,
            programmeSynopsis: nil
        )

        // Then
        XCTAssertNil(info.artist)
        XCTAssertNil(info.title)
        XCTAssertNil(info.artworkURL)
        XCTAssertFalse(info.hasMetadata)
        XCTAssertNil(info.formattedTrackInfo)
    }

    func testNowPlayingInfoWithOnlyArtist() {
        // When
        let info = NowPlayingInfo(
            artist: "Radiohead",
            title: nil,
            artworkURL: nil,
            artworkURLTemplate: nil,
            programmeTitle: nil,
            programmeSynopsis: nil
        )

        // Then
        XCTAssertEqual(info.artist, "Radiohead")
        XCTAssertNil(info.title)
        XCTAssertTrue(info.hasMetadata)
        XCTAssertNil(info.formattedTrackInfo) // Needs both artist and title
    }

    func testNowPlayingInfoWithOnlyTitle() {
        // When
        let info = NowPlayingInfo(
            artist: nil,
            title: "Creep",
            artworkURL: nil,
            artworkURLTemplate: nil,
            programmeTitle: nil,
            programmeSynopsis: nil
        )

        // Then
        XCTAssertNil(info.artist)
        XCTAssertEqual(info.title, "Creep")
        XCTAssertTrue(info.hasMetadata)
        XCTAssertNil(info.formattedTrackInfo) // Needs both artist and title
    }

    func testNowPlayingInfoEquality() {
        // Given
        let artworkURL = URL(string: "https://example.com/artwork.jpg")!
        let info1 = NowPlayingInfo(
            artist: "The Beatles",
            title: "Hey Jude",
            artworkURL: artworkURL,
            artworkURLTemplate: nil,
            programmeTitle: nil,
            programmeSynopsis: nil
        )
        let info2 = NowPlayingInfo(
            artist: "The Beatles",
            title: "Hey Jude",
            artworkURL: artworkURL,
            artworkURLTemplate: nil,
            programmeTitle: nil,
            programmeSynopsis: nil
        )
        let info3 = NowPlayingInfo(
            artist: "Radiohead",
            title: "Creep",
            artworkURL: artworkURL,
            artworkURLTemplate: nil,
            programmeTitle: nil,
            programmeSynopsis: nil
        )

        // Then
        XCTAssertEqual(info1, info2)
        XCTAssertNotEqual(info1, info3)
    }

    func testFormattedTrackInfoUsesEnDash() {
        // Given
        let info = NowPlayingInfo(
            artist: "Pink Floyd",
            title: "Comfortably Numb",
            artworkURL: nil,
            artworkURLTemplate: nil,
            programmeTitle: nil,
            programmeSynopsis: nil
        )

        // Then
        XCTAssertTrue(info.formattedTrackInfo?.contains("–") ?? false)
        XCTAssertFalse(info.formattedTrackInfo?.contains("-") ?? true)
    }

    func testFallbackArtworkURLsGenerateExpectedRecipes() {
        // Given
        let template = "https://ichef.bbci.co.uk/images/ic/{recipe}/p0123456.jpg"
        let info = NowPlayingInfo(
            artist: nil,
            title: nil,
            artworkURL: nil,
            artworkURLTemplate: template,
            programmeTitle: nil,
            programmeSynopsis: nil
        )

        // When
        let fallbacks = info.fallbackArtworkURLs.map(\.absoluteString)

        // Then
        XCTAssertEqual(fallbacks, [
            "https://ichef.bbci.co.uk/images/ic/256x256/p0123456.jpg",
            "https://ichef.bbci.co.uk/images/ic/192x192/p0123456.jpg",
            "https://ichef.bbci.co.uk/images/ic/128x128/p0123456.jpg",
            "https://ichef.bbci.co.uk/images/ic/64x64/p0123456.jpg"
        ])
    }

    func testArtworkCandidatesDeduplicatePrimaryRecipeURL() {
        // Given
        let template = "https://ichef.bbci.co.uk/images/ic/{recipe}/p0123456.jpg"
        let primary = URL(string: "https://ichef.bbci.co.uk/images/ic/256x256/p0123456.jpg")!

        let info = NowPlayingInfo(
            artist: "Artist",
            title: "Title",
            artworkURL: primary,
            artworkURLTemplate: template,
            programmeTitle: nil,
            programmeSynopsis: nil
        )

        // When
        let candidates = info.artworkCandidates.map(\.absoluteString)

        // Then - first is primary, rest are unique fallbacks
        XCTAssertEqual(candidates, [
            "https://ichef.bbci.co.uk/images/ic/256x256/p0123456.jpg",
            "https://ichef.bbci.co.uk/images/ic/192x192/p0123456.jpg",
            "https://ichef.bbci.co.uk/images/ic/128x128/p0123456.jpg",
            "https://ichef.bbci.co.uk/images/ic/64x64/p0123456.jpg"
        ])
    }
}
