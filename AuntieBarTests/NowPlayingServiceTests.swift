import XCTest
@testable import AuntieBar

final class NowPlayingServiceTests: XCTestCase {
    var service: NowPlayingService!
    var mockURLSession: URLSession!
    private var isoFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: config)
        service = NowPlayingService(urlSession: mockURLSession)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        mockURLSession = nil
        service = nil
        super.tearDown()
    }

    func testFetchNowPlayingWithoutArtwork() async {
        // Given
        let jsonResponse = """
        {
            "data": [
                {
                    "segment_type": "music",
                    "titles": {
                        "primary": "Radiohead",
                        "secondary": "Creep"
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockData = jsonResponse.data(using: .utf8)!

        // When
        let result = await service.fetchNowPlaying(for: "bbc_radio_one")

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.artist, "Radiohead")
        XCTAssertEqual(result?.title, "Creep")
        XCTAssertNil(result?.artworkURL)
    }

    func testFetchNowPlayingWithNonMusicSegment() async {
        // Given
        let jsonResponse = """
        {
            "data": [
                {
                    "segment_type": "speech",
                    "titles": {
                        "primary": "News",
                        "secondary": "BBC News"
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockData = jsonResponse.data(using: .utf8)!

        // When
        let result = await service.fetchNowPlaying(for: "bbc_radio_four")

        // Then
        XCTAssertNil(result)
    }

    func testFetchNowPlayingWithEmptyData() async {
        // Given
        let jsonResponse = """
        {
            "data": []
        }
        """
        MockURLProtocol.mockData = jsonResponse.data(using: .utf8)!

        // When
        let result = await service.fetchNowPlaying(for: "bbc_radio_two")

        // Then
        XCTAssertNil(result)
    }

    func testFetchNowPlayingWithNetworkError() async {
        // Given
        MockURLProtocol.mockError = URLError(.notConnectedToInternet)

        // When
        let result = await service.fetchNowPlaying(for: "bbc_6music")

        // Then - should fail quietly and return nil
        XCTAssertNil(result)
    }

    func testFetchNowPlayingWithInvalidJSON() async {
        // Given
        MockURLProtocol.mockData = "invalid json".data(using: .utf8)!

        // When
        let result = await service.fetchNowPlaying(for: "bbc_radio_three")

        // Then - should fail quietly and return nil
        XCTAssertNil(result)
    }

    func testFetchNowPlayingConstructsCorrectURL() async {
        // Given
        let serviceId = "bbc_6music"
        MockURLProtocol.mockData = """
        {
            "data": []
        }
        """.data(using: .utf8)!

        // When
        _ = await service.fetchNowPlaying(for: serviceId)

        // Then
        let expectedURLString = "https://rms.api.bbc.co.uk/v2/services/bbc_6music/segments/latest?experience=domestic&offset=0&limit=1"
        XCTAssertEqual(MockURLProtocol.lastRequestedURL?.absoluteString, expectedURLString)
    }

    func testFetchNowPlayingWithPartialTitles() async {
        // Given
        let jsonResponse = """
        {
            "data": [
                {
                    "segment_type": "music",
                    "titles": {
                        "primary": "Artist Name"
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockData = jsonResponse.data(using: .utf8)!

        // When
        let result = await service.fetchNowPlaying(for: "bbc_radio_one")

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.artist, "Artist Name")
        XCTAssertNil(result?.title)
    }

    func testFetchNowPlayingIncludesProgrammeInfo() async {
        // Given - Mock both segments and broadcasts endpoints
        let serviceId = "bbc_6music"

        // First request will be segments, second will be broadcasts
        var requestCount = 0
        MockURLProtocol.mockDataProvider = { url in
            requestCount += 1
            if url.absoluteString.contains("/segments/") {
                return """
                {
                    "data": [
                        {
                            "segment_type": "music",
                            "titles": {
                                "primary": "Radiohead",
                                "secondary": "Creep"
                            }
                        }
                    ]
                }
                """.data(using: .utf8)!
            } else if url.absoluteString.contains("/broadcasts/") {
                return """
                {
                    "data": [
                        {
                            "titles": {
                                "primary": "Chris Hawkins"
                            },
                            "synopses": {
                                "short": "Chris with the early morning breakfast show"
                            }
                        }
                    ]
                }
                """.data(using: .utf8)!
            }
            return "{}".data(using: .utf8)!
        }

        // When
        let result = await service.fetchNowPlaying(for: serviceId)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.artist, "Radiohead")
        XCTAssertEqual(result?.title, "Creep")
        XCTAssertEqual(result?.programmeTitle, "Chris Hawkins")
        XCTAssertEqual(result?.programmeSynopsis, "Chris with the early morning breakfast show")
    }

    func testFetchNowPlayingSucceedsEvenIfBroadcastFails() async {
        // Given - Mock segments to succeed but broadcasts to fail
        MockURLProtocol.mockDataProvider = { url in
            if url.absoluteString.contains("/segments/") {
                return """
                {
                    "data": [
                        {
                            "segment_type": "music",
                            "titles": {
                                "primary": "The Beatles",
                                "secondary": "Hey Jude"
                            }
                        }
                    ]
                }
                """.data(using: .utf8)!
            } else if url.absoluteString.contains("/broadcasts/") {
                // Return invalid JSON to simulate failure
                return "invalid json".data(using: .utf8)!
            }
            return "{}".data(using: .utf8)!
        }

        // When
        let result = await service.fetchNowPlaying(for: "bbc_radio_one")

        // Then - Should still return track info even if programme info fails
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.artist, "The Beatles")
        XCTAssertEqual(result?.title, "Hey Jude")
        XCTAssertNil(result?.programmeTitle)
        XCTAssertNil(result?.programmeSynopsis)
    }

    func testFetchNowNextParsesCurrentAndNextProgrammes() async {
        // Given
        let jsonResponse = """
        {
            "data": [
                {
                    "start": "2024-05-01T19:00:00Z",
                    "end": "2024-05-01T19:30:00Z",
                    "titles": { "primary": "Evening Show" },
                    "synopses": { "short": "Current show" }
                },
                {
                    "start": "2024-05-01T19:30:00Z",
                    "end": "2024-05-01T20:00:00Z",
                    "titles": { "primary": "Night Programme" }
                }
            ]
        }
        """
        MockURLProtocol.mockData = jsonResponse.data(using: .utf8)!

        // When
        let result = await service.fetchNowNext(for: "bbc_radio_four")

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.current.title, "Evening Show")
        XCTAssertEqual(result?.next?.title, "Night Programme")
        XCTAssertEqual(result?.current.startTime, isoFormatter.date(from: "2024-05-01T19:00:00Z"))
        XCTAssertEqual(result?.current.endTime, isoFormatter.date(from: "2024-05-01T19:30:00Z"))
        XCTAssertEqual(result?.next?.startTime, isoFormatter.date(from: "2024-05-01T19:30:00Z"))
    }

    func testFetchNowNextUsesCorrectURL() async {
        // Given
        MockURLProtocol.mockData = """
        {
            "data": []
        }
        """.data(using: .utf8)!

        // When
        _ = await service.fetchNowNext(for: "bbc_6music")

        // Then
        let expectedURLString = "https://rms.api.bbc.co.uk/v2/broadcasts/poll/bbc_6music?experience=domestic&offset=0&limit=2"
        XCTAssertEqual(MockURLProtocol.lastRequestedURL?.absoluteString, expectedURLString)
    }

    func testFetchNowNextHandlesFractionalSeconds() async {
        // Given
        let jsonResponse = """
        {
            "data": [
                {
                    "start": "2024-06-01T07:00:00.123Z",
                    "end": "2024-06-01T09:00:00.456Z",
                    "titles": { "primary": "Breakfast" }
                }
            ]
        }
        """
        MockURLProtocol.mockData = jsonResponse.data(using: .utf8)!

        // When
        let result = await service.fetchNowNext(for: "bbc_radio_two")

        // Then
        XCTAssertEqual(result?.current.title, "Breakfast")
        XCTAssertEqual(result?.current.startTime, isoFormatter.date(from: "2024-06-01T07:00:00.123Z"))
        XCTAssertEqual(result?.current.endTime, isoFormatter.date(from: "2024-06-01T09:00:00.456Z"))
    }
}

// MARK: - Mock URLProtocol

class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockError: Error?
    static var lastRequestedURL: URL?
    static var mockDataProvider: ((URL) -> Data)?

    static func reset() {
        mockData = nil
        mockError = nil
        lastRequestedURL = nil
        mockDataProvider = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        MockURLProtocol.lastRequestedURL = request.url

        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let url = request.url {
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        // Use mockDataProvider if available, otherwise use mockData
        let data: Data?
        if let provider = MockURLProtocol.mockDataProvider, let url = request.url {
            data = provider(url)
        } else {
            data = MockURLProtocol.mockData
        }

        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}
