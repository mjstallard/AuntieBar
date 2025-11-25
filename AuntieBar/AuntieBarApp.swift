import SwiftUI

@main
struct AuntieBarApp: App {
    @State private var viewModel = RadioViewModel()

    var body: some Scene {
        MenuBarExtra("AuntieBar", systemImage: "dot.radiowaves.left.and.right") {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
