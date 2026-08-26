import SwiftUI

/// The application entry point for MLXGenUI.
@main
struct MLXGenUIApp: App {
    /// The shared application model owned for the lifetime of the app.
    @State private var appModel = AppModel()

    /// The scenes presented by MLXGenUI.
    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appModel)
                .frame(minWidth: 980, minHeight: 640)
        }
        .defaultSize(width: 1_180, height: 760)

        Settings {
            SettingsView()
        }
    }
}
