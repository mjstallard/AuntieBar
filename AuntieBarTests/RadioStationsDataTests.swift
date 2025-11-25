import XCTest
@testable import AuntieBar

final class RadioStationsDataTests: XCTestCase {

    func testAllStationsNotEmpty() {
        // When
        let stations = RadioStationsData.allStations

        // Then
        XCTAssertFalse(stations.isEmpty)
        XCTAssertGreaterThan(stations.count, 50, "Should have at least 50 BBC stations")
    }

    func testStationsByCategory() {
        // When
        let stationsByCategory = RadioStationsData.stationsByCategory

        // Then
        XCTAssertTrue(stationsByCategory.keys.contains(.national))
        XCTAssertTrue(stationsByCategory.keys.contains(.regional))
        XCTAssertTrue(stationsByCategory.keys.contains(.nations))
    }

    func testNationalStationsExist() {
        // When
        let nationalStations = RadioStationsData.stationsByCategory[.national]

        // Then
        XCTAssertNotNil(nationalStations)
        XCTAssertTrue(nationalStations!.contains { $0.name.contains("Radio 1") })
        XCTAssertTrue(nationalStations!.contains { $0.name.contains("Radio 6") })
    }

    func testSortedCategoriesOrder() {
        // When
        let sorted = RadioStationsData.sortedCategories

        // Then
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0], .national)
        XCTAssertEqual(sorted[1], .nations)
        XCTAssertEqual(sorted[2], .regional)
    }

    func testAllStationsHaveValidURLs() {
        // When
        let stations = RadioStationsData.allStations

        // Then
        for station in stations {
            XCTAssertNotNil(station.streamURL.scheme, "Station \(station.name) should have a URL scheme")
            XCTAssertTrue(
                station.streamURL.absoluteString.contains("akamaized.net"),
                "Station \(station.name) should use Akamai CDN"
            )
        }
    }

    func testUKOnlyStationsMarked() {
        // When
        let stations = RadioStationsData.allStations

        // Then
        let ukOnlyStations = stations.filter { $0.isUKOnly }
        XCTAssertGreaterThan(ukOnlyStations.count, 0, "Should have some UK-only stations")

        for station in ukOnlyStations {
            XCTAssertTrue(
                station.streamURL.absoluteString.contains("/uk/"),
                "UK-only station \(station.name) should have /uk/ in URL"
            )
        }
    }

    func testAllStationsHaveServiceIds() {
        // When
        let stations = RadioStationsData.allStations

        // Then
        for station in stations {
            XCTAssertFalse(station.serviceId.isEmpty, "Station \(station.name) should have a service ID")
            XCTAssertTrue(
                station.serviceId.starts(with: "bbc_"),
                "Station \(station.name) service ID should start with 'bbc_', got: \(station.serviceId)"
            )
        }
    }

    func testServiceIdsAreUnique() {
        // When
        let stations = RadioStationsData.allStations
        let serviceIds = stations.map { $0.serviceId }

        // Then
        let uniqueServiceIds = Set(serviceIds)
        XCTAssertEqual(
            serviceIds.count,
            uniqueServiceIds.count,
            "All service IDs should be unique"
        )
    }
}
