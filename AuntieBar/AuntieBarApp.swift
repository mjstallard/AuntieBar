import SwiftUI

@main
struct AuntieBarApp: App {
    @State private var viewModel = RadioViewModel()

    private var menuBarSystemImage: String {
        viewModel.playbackState.isPlaying ? "radio.fill" : "radio"
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if case let .playing(station) = viewModel.playbackState {
            Label(station.name, systemImage: menuBarSystemImage)
                .labelStyle(.titleAndIcon)
        } else {
            Image(systemName: menuBarSystemImage)
                .accessibilityLabel("AuntieBar")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }
}
