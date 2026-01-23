import SwiftUI
import AppKit

@main
struct AuntieBarApp: App {
    @State private var viewModel = RadioViewModel()
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue

    private var menuBarSystemImage: String {
        viewModel.playbackState.isPlaying ? "radio.fill" : "radio"
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        Image(systemName: menuBarSystemImage)
            .accessibilityLabel("AuntieBar")
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
                .preferredColorScheme(preferredColorScheme)
                .onAppear {
                    applyAppAppearance()
                }
                .onChange(of: appearanceMode) { _, _ in
                    applyAppAppearance()
                }
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var preferredColorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    private func applyAppAppearance() {
        guard let mode = AppearanceMode(rawValue: appearanceMode) else {
            NSApp.appearance = nil
            return
        }

        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
