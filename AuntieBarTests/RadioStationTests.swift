import XCTest
@testable import AuntieBar

final class RadioStationTests: XCTestCase {

    func testRadioStationInitialization() {
        // Given
        let name = "Radio 6 Music"
        let url = URL(string: "http://example.com/stream.m3u8")!
        let category = RadioStationCategory.national

        // When
        let station = RadioStation(
            name: name,
            streamURL: url,
            category: category
        )

        // Then
        XCTAssertEqual(station.name, name)
        XCTAssertEqual(station.streamURL, url)
        XCTAssertEqual(station.category, category)
        XCTAssertFalse(station.isUKOnly)
    }

    func testRadioStationUKOnly() {
        // Given
        let url = URL(string: "http://example.com/stream.m3u8")!

        // When
        let station = RadioStation(
            name: "Radio 1 Anthems",
            streamURL: url,
            category: .national,
            isUKOnly: true
        )

        // Then
        XCTAssertTrue(station.isUKOnly)
    }

    func testRadioStationCategoryRawValues() {
        // Then
        XCTAssertEqual(RadioStationCategory.national.rawValue, "National")
        XCTAssertEqual(RadioStationCategory.regional.rawValue, "Regional")
        XCTAssertEqual(RadioStationCategory.nations.rawValue, "Nations & Regions")
    }

    func testRadioStationCategorySortOrder() {
        // Then
        XCTAssertEqual(RadioStationCategory.national.sortOrder, 0)
        XCTAssertEqual(RadioStationCategory.nations.sortOrder, 1)
        XCTAssertEqual(RadioStationCategory.regional.sortOrder, 2)
    }
}
