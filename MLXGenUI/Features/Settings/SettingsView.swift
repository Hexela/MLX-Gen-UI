import SwiftUI

/// Application-wide preferences that do not belong to one generation task.
struct SettingsView: View {
    /// The settings window content.
    var body: some View {
        Form {
            Section("Updates") {
                Text("Automatic update checks will be added with installation management. Updates will always require confirmation.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 220)
    }
}
