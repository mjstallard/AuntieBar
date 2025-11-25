import AppKit
import SwiftUI

final class AuntieWindowController {
    static let shared = AuntieWindowController()

    private var window: NSWindow?
    private let viewModel: RadioViewModel

    init(viewModel: RadioViewModel = RadioViewModel()) {
        self.viewModel = viewModel
    }

    func showMainWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(rootView: MainView(viewModel: viewModel))

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "AuntieBar"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
