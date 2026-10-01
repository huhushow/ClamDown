import SwiftUI

@main
struct MyApp: App {
    @State private var model = ClamDownModel()

    var body: some Scene {
        MenuBarExtra("Clam Down", systemImage: model.menuBarIconName) {
            MenuBarContentView(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}
