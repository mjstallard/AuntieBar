import XCTest
@testable import AuntieBar

final class NowPlayingServiceTests: XCTestCase {
    var service: NowPlayingService!
    var mockURLSession: URLSession!

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
}

// MARK: - Mock URLProtocol

class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockError: Error?
    static var lastRequestedURL: URL?

    static func reset() {
        mockData = nil
        mockError = nil
        lastRequestedURL = nil
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

        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}
