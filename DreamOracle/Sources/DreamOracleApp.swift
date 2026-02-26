import SwiftUI

@main
struct DreamOracleApp: App {
    @StateObject private var viewModel = DreamInterpreterViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}

