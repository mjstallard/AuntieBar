import SwiftUI

/// Compact view showing currently playing station and track information
struct NowPlayingView: View {
    let station: RadioStation
    let nowPlayingInfo: NowPlayingInfo?
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Artwork or placeholder
            if let artworkURL = nowPlayingInfo?.artworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(width: 64, height: 64)
                .cornerRadius(4)
            } else if nowPlayingInfo?.hasMetadata == true {
                placeholderImage
                    .frame(width: 64, height: 64)
            }

            // Station name and track info
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.headline)
                    .lineLimit(1)

                if let trackInfo = nowPlayingInfo?.formattedTrackInfo {
                    Text(trackInfo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .onHover { hovering in
                            isHovering = hovering
                        }
                        .popover(isPresented: $isHovering, arrowEdge: .bottom) {
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
