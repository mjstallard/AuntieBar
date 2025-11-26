import SwiftUI

/// Compact view showing currently playing station and track information
struct NowPlayingView: View {
    let station: RadioStation
    let nowPlayingInfo: NowPlayingInfo?
    let audioQualityMetrics: AudioQualityMetrics?
    @State private var isHoveringStation = false
    @State private var isHoveringTrack = false

    var body: some View {
        HStack(spacing: 12) {
            // Artwork or placeholder
            if let artworkURLs = nowPlayingInfo?.artworkCandidates, !artworkURLs.isEmpty {
                ArtworkLoader(
                    urls: artworkURLs,
                    placeholder: placeholderImage
                )
                .frame(width: 64, height: 64)
            } else if nowPlayingInfo?.hasMetadata == true {
                placeholderImage
                    .frame(width: 64, height: 64)
            }

            // Station name, programme, and track info
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.headline)
                    .lineLimit(1)
                    .onHover { hovering in
                        isHoveringStation = hovering
                    }
                    .popover(isPresented: $isHoveringStation, arrowEdge: .trailing) {
                        if let metrics = audioQualityMetrics {
                            AudioQualityPopover(metrics: metrics)
                        } else {
                            Text("Loading quality info...")
                                .font(.callout)
                                .padding(8)
                        }
                    }

                if let programmeTitle = nowPlayingInfo?.programmeTitle {
                    Text(programmeTitle)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                if let trackInfo = nowPlayingInfo?.formattedTrackInfo {
                    Text(trackInfo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .onHover { hovering in
                            isHoveringTrack = hovering
                        }
                        .popover(isPresented: $isHoveringTrack, arrowEdge: .bottom) {
                            Text(trackInfo)
                                .font(.callout)
                                .padding(8)
                                .frame(maxWidth: 280)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var placeholderImage: some View {
        Image(systemName: "music.note")
            .font(.title)
            .foregroundStyle(.secondary)
            .frame(width: 64, height: 64)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
    }
}

/// Async image view that falls back through multiple URLs before showing a placeholder
private struct ArtworkLoader<Placeholder: View>: View {
    let urls: [URL]
    let placeholder: Placeholder

    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            placeholder

            if !urls.isEmpty {
                AsyncImage(url: urls[currentIndex]) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    case .failure:
                        Color.clear
                            .task {
                                advanceIfPossible()
                            }
                    case .empty:
                        Color.clear
                    @unknown default:
                        Color.clear
                    }
                }
            }
        }
        .frame(width: 64, height: 64)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(4)
    }

    private func advanceIfPossible() {
        guard currentIndex + 1 < urls.count else { return }
        currentIndex += 1
    }
}
