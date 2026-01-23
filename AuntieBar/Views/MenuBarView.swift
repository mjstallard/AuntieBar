import SwiftUI

/// Menu bar extra content showing all BBC Radio stations
struct MenuBarView: View {
    @Bindable var viewModel: RadioViewModel
    @State private var showingSettings = false
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("hideUKOnlyStations") private var hideUKOnlyStations = false

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
                    if showingSettings {
                        MenuSettingsView(viewModel: viewModel)
                    } else {
                        // Show categorized stations
                        FavoritesSection(
                            stations: viewModel.favoriteStations(hideUKOnly: hideUKOnlyStations),
                            viewModel: viewModel
                        )

                        ForEach(viewModel.categories(hideUKOnly: hideUKOnlyStations, excludingFavorites: true), id: \.self) { category in
                            CategorySection(
                                category: category,
                                stations: viewModel.stations(
                                    for: category,
                                    hideUKOnly: hideUKOnlyStations,
                                    excludingFavorites: true
                                ),
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
            .frame(height: 180)

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
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Label(
                            showingSettings ? "Stations" : "Settings",
                            systemImage: showingSettings ? "list.bullet" : "gearshape"
                        )
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(showingSettings ? "Stations" : "Settings")

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
        .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
        .background(.regularMaterial)
    }
}

private struct MenuSettingsView: View {
    let viewModel: RadioViewModel
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("hideUKOnlyStations") private var hideUKOnlyStations = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Appearance")
                .font(.headline)

            Picker("", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label)
                        .tag(mode.rawValue)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            Divider()
                .padding(.vertical, 4)

            Text("Stations")
                .font(.headline)

            Toggle("Hide UK-only stations", isOn: $hideUKOnlyStations)
                .toggleStyle(.switch)

            if hideUKOnlyStations {
                Text(hiddenStationsLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hiddenStationsLabel: String {
        let count = viewModel.ukOnlyStationCount
        if count == 1 {
            return "Hiding 1 station"
        }
        return "Hiding \(count) stations"
    }
}

private struct FavoritesSection: View {
    let stations: [RadioStation]
    let viewModel: RadioViewModel

    var body: some View {
        if !stations.isEmpty {
            Section {
                ForEach(stations) { station in
                    StationButton(station: station, viewModel: viewModel)
                }
            } header: {
                Text("Favorites")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
            }
        }
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
                .background(.thinMaterial)
        }
    }
}

// MARK: - Station Button

struct StationButton: View {
    let station: RadioStation
    let viewModel: RadioViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
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
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }

            Button {
                viewModel.toggleFavorite(for: station)
            } label: {
                Image(systemName: viewModel.isFavorite(station) ? "star.fill" : "star")
                    .foregroundStyle(viewModel.isFavorite(station) ? .yellow : .secondary)
                    .frame(width: 16)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
            .accessibilityLabel("Toggle favorite")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(isHovered ? Color.primary.opacity(0.06) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(alignment: .leading) {
            Color.clear
                .contentShape(Rectangle())
                .padding(.trailing, 28)
                .onTapGesture {
                    viewModel.togglePlayback(for: station)
                }
        }
        .onHover { isHovered in
            self.isHovered = isHovered
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
