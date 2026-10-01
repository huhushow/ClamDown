import SwiftUI

@main
struct MyApp: App {
    @State private var model = ClamDownModel()

    var body: some Scene {
        MenuBarExtra("Clam Down", image: "MenuBarIcon") {
            MenuBarContentView(model: model)
        }
        .menuBarExtraStyle(.window)

        Window("About ClamDown", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
