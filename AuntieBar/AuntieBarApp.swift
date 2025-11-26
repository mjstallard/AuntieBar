import SwiftUI

@main
struct AuntieBarApp: App {
    @State private var viewModel = RadioViewModel()

    private var menuBarSystemImage: String {
        viewModel.playbackState.isPlaying ? "radio.fill" : "radio"
    }

    var body: some Scene {
        MenuBarExtra("AuntieBar", systemImage: menuBarSystemImage) {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
