import SwiftUI

/// WinAmp-style audio quality information popover
struct AudioQualityPopover: View {
    let metrics: AudioQualityMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stream Quality")
                .font(.headline)
                .padding(.bottom, 4)

            if let codec = metrics.codec {
                qualityRow(label: "Codec:", value: codec)
            }

            // Show nominal bitrate only
            if let bitrate = metrics.indicatedBitrateKbps {
                qualityRow(label: "Bitrate:", value: "\(bitrate) kbps")
            }

            if let channels = metrics.channelDescription {
                qualityRow(label: "Channels:", value: channels)
            }

            if let mb = metrics.megabytesTransferred {
                qualityRow(label: "Transferred:", value: String(format: "%.1f MB", mb))
            }

            if let stalls = metrics.stallCount, stalls > 0 {
                qualityRow(label: "Stalls:", value: "\(stalls)")
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .frame(minWidth: 200)
        .font(.system(.body, design: .monospaced))
    }

    private func qualityRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
        }
    }
}
