import XCTest
@testable import AuntieBar

final class AudioQualityMetricsTests: XCTestCase {

    func testAudioQualityMetricsWithAllFields() {
        // Given/When
        let metrics = AudioQualityMetrics(
            indicatedBitrate: 96000,
            observedBitrate: 98000,
            sampleRate: 48000,
            channelCount: 2,
            codec: "AAC",
            stallCount: 0,
            bytesTransferred: 5242880
        )

        // Then
        XCTAssertEqual(metrics.indicatedBitrate, 96000)
        XCTAssertEqual(metrics.observedBitrate, 98000)
        XCTAssertEqual(metrics.sampleRate, 48000)
        XCTAssertEqual(metrics.channelCount, 2)
        XCTAssertEqual(metrics.codec, "AAC")
        XCTAssertEqual(metrics.stallCount, 0)
        XCTAssertEqual(metrics.bytesTransferred, 5242880)
    }

    func testAudioQualityMetricsWithNilFields() {
        // Given/When
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: nil,
            channelCount: nil,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertNil(metrics.indicatedBitrate)
        XCTAssertNil(metrics.observedBitrate)
        XCTAssertNil(metrics.sampleRate)
        XCTAssertNil(metrics.channelCount)
        XCTAssertNil(metrics.codec)
        XCTAssertNil(metrics.stallCount)
        XCTAssertNil(metrics.bytesTransferred)
    }

    func testIndicatedBitrateKbpsConversion() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: 96000,
            observedBitrate: nil,
            sampleRate: nil,
            channelCount: nil,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertEqual(metrics.indicatedBitrateKbps, 96)
    }

    func testObservedBitrateKbpsConversion() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: 128000,
            sampleRate: nil,
            channelCount: nil,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertEqual(metrics.observedBitrateKbps, 128)
    }

    func testSampleRateKHzConversion() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: 48000,
            channelCount: nil,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertEqual(metrics.sampleRateKHz, 48.0)
    }

    func testSampleRateKHzConversionWith44_1kHz() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: 44100,
            channelCount: nil,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertEqual(metrics.sampleRateKHz, 44.1)
    }

    func testChannelDescriptionMono() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: nil,
            channelCount: 1,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertEqual(metrics.channelDescription, "Mono")
    }

    func testChannelDescriptionStereo() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: nil,
            channelCount: 2,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertEqual(metrics.channelDescription, "Stereo")
    }

    func testChannelDescriptionMultiChannel() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: nil,
            channelCount: 6,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertEqual(metrics.channelDescription, "6 channels")
    }

    func testChannelDescriptionNil() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: nil,
            channelCount: nil,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertNil(metrics.channelDescription)
    }

    func testMegabytesTransferredConversion() {
        // Given - 5 MB
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: nil,
            channelCount: nil,
            codec: nil,
            stallCount: nil,
            bytesTransferred: 5242880
        )

        // Then
        XCTAssertNotNil(metrics.megabytesTransferred)
        XCTAssertEqual(metrics.megabytesTransferred ?? 0, 5.0, accuracy: 0.1)
    }

    func testMegabytesTransferredNil() {
        // Given
        let metrics = AudioQualityMetrics(
            indicatedBitrate: nil,
            observedBitrate: nil,
            sampleRate: nil,
            channelCount: nil,
            codec: nil,
            stallCount: nil,
            bytesTransferred: nil
        )

        // Then
        XCTAssertNil(metrics.megabytesTransferred)
    }

    func testEquality() {
        // Given
        let metrics1 = AudioQualityMetrics(
            indicatedBitrate: 96000,
            observedBitrate: 98000,
            sampleRate: 48000,
            channelCount: 2,
            codec: "AAC",
            stallCount: 0,
            bytesTransferred: 1024
        )

        let metrics2 = AudioQualityMetrics(
            indicatedBitrate: 96000,
            observedBitrate: 98000,
            sampleRate: 48000,
            channelCount: 2,
            codec: "AAC",
            stallCount: 0,
            bytesTransferred: 1024
        )

        let metrics3 = AudioQualityMetrics(
            indicatedBitrate: 128000,
            observedBitrate: 98000,
            sampleRate: 48000,
            channelCount: 2,
            codec: "AAC",
            stallCount: 0,
            bytesTransferred: 1024
        )

        // Then
        XCTAssertEqual(metrics1, metrics2)
        XCTAssertNotEqual(metrics1, metrics3)
    }

    func testTypicalBBCRadioMetrics() {
        // Given - typical BBC Radio stream
        let metrics = AudioQualityMetrics(
            indicatedBitrate: 96000,
            observedBitrate: 98000,
            sampleRate: 48000,
            channelCount: 2,
            codec: "AAC",
            stallCount: 0,
            bytesTransferred: 10485760
        )

        // Then
        XCTAssertEqual(metrics.indicatedBitrateKbps, 96)
        XCTAssertEqual(metrics.observedBitrateKbps, 98)
        XCTAssertEqual(metrics.sampleRateKHz, 48.0)
        XCTAssertEqual(metrics.channelDescription, "Stereo")
        XCTAssertEqual(metrics.codec, "AAC")
        XCTAssertNotNil(metrics.megabytesTransferred)
        XCTAssertEqual(metrics.megabytesTransferred ?? 0, 10.0, accuracy: 0.1)
    }
}
