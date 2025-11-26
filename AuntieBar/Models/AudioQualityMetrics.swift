import Foundation

/// Audio quality metrics extracted from the live stream
struct AudioQualityMetrics: Equatable {
    /// Indicated bitrate in bits per second (from stream manifest)
    let indicatedBitrate: Double?

    /// Observed average bitrate in bits per second (actual measured)
    let observedBitrate: Double?

    /// Sample rate in Hz (e.g., 44100, 48000)
    let sampleRate: Double?

    /// Number of audio channels (1 = mono, 2 = stereo)
    let channelCount: Int?

    /// Audio codec name (e.g., "AAC", "MP3")
    let codec: String?

    /// Number of stall/buffer events
    let stallCount: Int?

    /// Total bytes transferred
    let bytesTransferred: Int64?

    // MARK: - Computed Properties

    /// Indicated bitrate in kbps for display
    var indicatedBitrateKbps: Int? {
        indicatedBitrate.map { Int($0 / 1000) }
    }

    /// Observed bitrate in kbps for display
    var observedBitrateKbps: Int? {
        observedBitrate.map { Int($0 / 1000) }
    }

    /// Sample rate in kHz for display
    var sampleRateKHz: Double? {
        sampleRate.map { $0 / 1000 }
    }

    /// Channel description (Mono/Stereo/etc)
    var channelDescription: String? {
        guard let count = channelCount else { return nil }
        switch count {
        case 1: return "Mono"
        case 2: return "Stereo"
        default: return "\(count) channels"
        }
    }

    /// Megabytes transferred for display
    var megabytesTransferred: Double? {
        bytesTransferred.map { Double($0) / 1_048_576 }
    }
}
