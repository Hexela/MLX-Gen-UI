import SwiftUI

/// Presents the readiness of Homebrew, uv, and MLX-Gen.
struct SystemStatusView: View {
    /// The shared application state supplied by the root scene.
    @Environment(AppModel.self) private var appModel
    /// The backend action awaiting explicit confirmation.
    @State private var pendingAction: BackendAction?

    /// The system status hierarchy.
    var body: some View {
        Form {
            Section {
                Label(appModel.systemStatus.title, systemImage: appModel.systemStatus.systemImage)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)

                statusDetails

                actionButton

                if let systemStatusError = appModel.systemStatusError {
                    Text(systemStatusError)
                        .foregroundStyle(.red)
                }
            }

            Section("How Installation Works") {
                Text("Homebrew installs uv. uv installs and updates MLX-Gen in your user account. The app never interprets installation values through a shell.")
                    .foregroundStyle(.secondary)
            }

            BackendOperationView()
        }
        .formStyle(.grouped)
        .navigationTitle("System Status")
        .toolbar {
            Button("Refresh", systemImage: "arrow.clockwise") {
                Task(name: "Refresh system status") {
                    await appModel.refreshSystemStatus()
                }
            }
            .disabled(appModel.isRefreshingSystemStatus)
        }
    }

    /// Version information or guidance appropriate to the current state.
    @ViewBuilder
    private var statusDetails: some View {
        switch appModel.systemStatus {
        case .checking:
            ProgressView("Inspecting installed tools…")
        case .homebrewMissing:
            Text("Install Homebrew from brew.sh, then refresh this page.")
        case .uvMissing(let homebrewVersion):
            versionRow("Homebrew", value: homebrewVersion)
            Text("Install uv with `brew install uv`.")
        case .mlxGenMissing(let homebrewVersion, let uvVersion):
            versionRow("Homebrew", value: homebrewVersion)
            versionRow("uv", value: uvVersion)
            Text("Install MLX-Gen with `uv tool install --upgrade mlx-gen`.")
        case .ready(let homebrewVersion, let uvVersion, let mlxGenVersion):
            versionRow("Homebrew", value: homebrewVersion)
            versionRow("uv", value: uvVersion)
            versionRow("MLX-Gen", value: mlxGenVersion)
        case .unavailable:
            Text("Refresh to inspect the installation again.")
        }
    }

    /// The installation or update action appropriate to the current state.
    @ViewBuilder
    private var actionButton: some View {
        switch appModel.systemStatus {
        case .uvMissing:
            confirmedActionButton("Install uv", action: .installUV)
        case .mlxGenMissing:
            confirmedActionButton("Install MLX-Gen", action: .installMLXGen)
        case .ready:
            confirmedActionButton("Update MLX-Gen", action: .updateMLXGen)
        case .checking, .homebrewMissing, .unavailable:
            EmptyView()
        }
    }

    /// Creates a button with a model-owned confirmation dialog.
    private func confirmedActionButton(_ title: String, action: BackendAction) -> some View {
        Button(title) {
            pendingAction = action
        }
        .disabled(appModel.backendOperation?.isRunning == true)
        .confirmationDialog(
            "\(title)?",
            isPresented: confirmationBinding(for: action),
            titleVisibility: .visible
        ) {
            Button(title) {
                pendingAction = nil
                Task(name: title) {
                    await appModel.perform(action)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingAction = nil
            }
        } message: {
            Text(commandDescription(for: action))
        }
    }

    /// Binds an action-specific dialog to the pending action.
    private func confirmationBinding(for action: BackendAction) -> Binding<Bool> {
        Binding(
            get: { pendingAction == action },
            set: { isPresented in
                if isPresented == false, pendingAction == action {
                    pendingAction = nil
                }
            }
        )
    }

    /// Explains the exact package-management command before it runs.
    private func commandDescription(for action: BackendAction) -> String {
        let command = BackendActionCommandBuilder().makeCommand(
            for: action,
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        return "MLXGenUI will run: \(command.displayString)"
    }

    /// Displays a discovered tool version without exposing an empty value.
    private func versionRow(_ name: String, value: String?) -> some View {
        LabeledContent(name, value: value ?? "Installed")
    }
}
