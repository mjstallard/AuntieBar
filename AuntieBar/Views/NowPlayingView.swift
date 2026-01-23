import SwiftUI

/// Compact view showing currently playing station and track information
struct NowPlayingView: View {
    let station: RadioStation
    let nowPlayingInfo: NowPlayingInfo?
    let nowNextInfo: NowNextInfo?
    let audioQualityMetrics: AudioQualityMetrics?
    @State private var isHoveringStation = false
    @State private var isHoveringProgramme = false

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
                        .lineLimit(nil)
                        .onHover { hovering in
                            isHoveringProgramme = hovering
                        }
                        .popover(
                            isPresented: Binding(
                                get: { isHoveringProgramme && nowNextInfo != nil },
                                set: { isHoveringProgramme = $0 }
                            ),
                            arrowEdge: .trailing
                        ) {
                            if let nowNextInfo {
                                ProgrammeSchedulePopover(nowNextInfo: nowNextInfo)
                            }
                        }
                }

                if let trackInfo = nowPlayingInfo?.formattedTrackInfo {
                    Text(trackInfo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil) // allow full wrapping for long track titles
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
            .background(.thinMaterial)
            .cornerRadius(4)
    }
}

/// Popover showing current and upcoming programme timing details
private struct ProgrammeSchedulePopover: View {
    let nowNextInfo: NowNextInfo

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Started \(format(nowNextInfo.current.startTime)), ends \(format(nowNextInfo.current.endTime))")
                .font(.callout)
                .foregroundStyle(.secondary)

            if !upcomingSlots.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                ForEach(upcomingSlots, id: \.startTime) { slot in
                    Text("\(format(slot.startTime)): \(slot.title)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                }
            } else {
                Text("Next programme information unavailable")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
    }

    private func format(_ date: Date) -> String {
        ProgrammeSchedulePopover.timeFormatter.string(from: date)
    }

    private var upcomingSlots: [ProgrammeSlot] {
        Array(nowNextInfo.upcoming.prefix(3))
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
        .background(.thinMaterial)
        .cornerRadius(4)
    }

    private func advanceIfPossible() {
        guard currentIndex + 1 < urls.count else { return }
        currentIndex += 1
    }
}
