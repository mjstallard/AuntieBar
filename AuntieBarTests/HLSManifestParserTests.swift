import XCTest
@testable import AuntieBar

final class HLSManifestParserTests: XCTestCase {
    func testParseNominalBitratePrefersAverage() {
        let manifest = """
        #EXTM3U
        #EXT-X-STREAM-INF:BANDWIDTH=96000,AVERAGE-BANDWIDTH=128000,CODECS="mp4a.40.2"
        audio_96.m3u8
        #EXT-X-STREAM-INF:BANDWIDTH=192000,CODECS="mp4a.40.2"
        audio_192.m3u8
        """

        let bitrate = HLSManifestParser.parseNominalBitrate(from: manifest)
        XCTAssertEqual(bitrate, 128_000)
    }

    func testParseNominalBitrateFallsBackToMaxBandwidth() {
        let manifest = """
        #EXTM3U
        #EXT-X-STREAM-INF:BANDWIDTH=96000,CODECS="mp4a.40.2"
        audio_96.m3u8
        #EXT-X-STREAM-INF:BANDWIDTH=192000,CODECS="mp4a.40.2"
        audio_192.m3u8
        """

        let bitrate = HLSManifestParser.parseNominalBitrate(from: manifest)
        XCTAssertEqual(bitrate, 192_000)
    }

    func testParseBitrateFromURL() {
        let url = URL(string: "https://example.com/stream/bbc_radio_one-audio%3d320000.m3u8")!
        let bitrate = HLSManifestParser.parseBitrateFromURL(url)
        XCTAssertEqual(bitrate, 320_000)
    }

    func testParseBitrateFromURLWithEqualsSign() {
        let url = URL(string: "https://example.com/stream/audio=192000/playlist.m3u8")!
        let bitrate = HLSManifestParser.parseBitrateFromURL(url)
        XCTAssertEqual(bitrate, 192_000)
    }
}
