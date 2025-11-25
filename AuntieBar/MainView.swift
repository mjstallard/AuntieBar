import SwiftUI

struct MainView: View {
    @Bindable var viewModel: RadioViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("AuntieBar")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("BBC Radio in your menu bar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Current playback status
            VStack(spacing: 12) {
                if let station = viewModel.currentStation {
                    Label("Now Playing", systemImage: "play.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)

                    Text(station.name)
                        .font(.title3)
                        .fontWeight(.medium)

                    Text(station.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Not Playing", systemImage: "stop.circle")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Select a station from the menu bar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            // Info
            VStack(spacing: 4) {
                Text("\(viewModel.allStations.count) BBC Radio Stations")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.currentStation != nil {
                    Button("Stop Playback") {
                        viewModel.stop()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}
