import Foundation

/// Lightweight HLS manifest parser to extract the nominal audio bitrate.
struct HLSManifestParser {

    /// Parse a nominal bitrate from an HLS manifest string.
    /// Prefers AVERAGE-BANDWIDTH, otherwise falls back to the largest BANDWIDTH.
    static func parseNominalBitrate(from manifest: String) -> Double? {
        let averageBandwidth = matchFirstNumber(
            in: manifest,
            pattern: #"AVERAGE-BANDWIDTH\s*=\s*(\d+)"#
        )

        let bandwidths = matchAllNumbers(
            in: manifest,
            pattern: #"BANDWIDTH\s*=\s*(\d+)"#
        )

        if let average = averageBandwidth {
            return average
        }

        if let maxBandwidth = bandwidths.max() {
            return maxBandwidth
        }

        return nil
    }

    /// Attempt to fetch and parse the manifest at the given URL.
    static func fetchNominalBitrate(from url: URL) async -> Double? {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let manifest = String(data: data, encoding: .utf8) else {
            return nil
        }

        return parseNominalBitrate(from: manifest)
    }

    /// Extract the nominal bitrate from a BBC-style URL (e.g., audio%3d320000).
    static func parseBitrateFromURL(_ url: URL) -> Double? {
        let urlString = url.absoluteString
        let pattern = #"audio(?:%3[dD]|=)(\d+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: urlString,
                range: NSRange(location: 0, length: urlString.utf16.count)
              ),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: urlString),
              let value = Double(urlString[range]) else {
            return nil
        }

        return value
    }

    // MARK: - Helpers

    private static func matchFirstNumber(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(location: 0, length: text.utf16.count)
              ),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text),
              let value = Double(text[range]) else {
            return nil
        }

        return value
    }

    private static func matchAllNumbers(in text: String, pattern: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let fullRange = NSRange(location: 0, length: text.utf16.count)
        return regex.matches(in: text, range: fullRange).compactMap { match in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: text),
                  let value = Double(text[range]) else {
                return nil
            }
            return value
        }
    }
}
