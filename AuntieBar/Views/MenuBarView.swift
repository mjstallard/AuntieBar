import SwiftUI

/// Menu bar extra content showing all BBC Radio stations
struct MenuBarView: View {
    @Bindable var viewModel: RadioViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Now Playing section
            if let station = viewModel.currentStation {
                NowPlayingView(
                    station: station,
                    nowPlayingInfo: viewModel.nowPlayingInfo,
                    nowNextInfo: viewModel.nowNextInfo,
                    audioQualityMetrics: viewModel.audioQualityMetrics
                )

                Divider()
            }

            // Volume control
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                Slider(value: $viewModel.volume, in: 0...1)

                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Show categorized stations
                    ForEach(viewModel.sortedCategories, id: \.self) { category in
                        CategorySection(
                            category: category,
                            stations: viewModel.stationsByCategory[category] ?? [],
                            viewModel: viewModel
                        )
                    }
                }
            }
            .frame(maxHeight: 500)

            Divider()

            // Footer controls
            VStack(spacing: 4) {                

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                }

                HStack {
                    Button("Stop") {
                        viewModel.stop()
                    }
                    .disabled(viewModel.currentStation == nil)

                    Spacer()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 280)
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: RadioStationCategory
    let stations: [RadioStation]
    let viewModel: RadioViewModel

    var body: some View {
        Section {
            ForEach(stations.sorted { $0.name < $1.name }) { station in
                StationButton(station: station, viewModel: viewModel)
            }
        } header: {
            Text(category.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
        }
    }
}

// MARK: - Station Button

struct StationButton: View {
    let station: RadioStation
    let viewModel: RadioViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            viewModel.togglePlayback(for: station)
        } label: {
            HStack {
                Image(systemName: viewModel.isCurrentlyPlaying(station) ? "stop.circle.fill" : "play.circle")
                    .foregroundStyle(viewModel.isCurrentlyPlaying(station) ? .green : .primary)

                Text(station.name)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if station.isUKOnly {
                    Text("UK only")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(colorScheme == .dark ? Color.blue.opacity(0.3) : Color.blue.opacity(0.2))
                        .cornerRadius(3)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
