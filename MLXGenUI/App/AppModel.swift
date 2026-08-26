import Foundation
import Observation

/// Coordinates user-visible application state and long-lived services.
@MainActor
@Observable
final class AppModel {
    /// The destination currently selected in the main sidebar.
    var selection: AppDestination? = .createVideo

    /// The generation task currently being edited.
    var task: GenerationTask

    /// The preset on which the current editable task is based.
    var selectedPreset: GenerationPreset = .quickTextPreview

    /// The most recently observed backend installation state.
    private(set) var systemStatus: SystemStatus = .checking

    /// `true` while the app is refreshing dependency information.
    private(set) var isRefreshingSystemStatus = false

    /// A user-facing description of the most recent status error.
    private(set) var systemStatusError: String?

    /// The currently running or most recently completed backend operation.
    private(set) var backendOperation: BackendOperationState?

    /// A user-facing description of the most recent backend operation error.
    private(set) var backendOperationError: String?

    /// The service used to inspect locally installed command-line tools.
    private let systemStatusService: SystemStatusService

    /// The runner that owns long-lived installation, download, and generation processes.
    private let backendProcessRunner: BackendProcessRunner

    /// Creates an application model with injectable service dependencies.
    ///
    /// - Parameters:
    ///   - systemStatusService: The service that inspects backend dependencies.
    ///   - backendProcessRunner: The runner that owns long-lived backend processes.
    init(
        systemStatusService: SystemStatusService = SystemStatusService(),
        backendProcessRunner: BackendProcessRunner = BackendProcessRunner()
    ) {
        self.systemStatusService = systemStatusService
        self.backendProcessRunner = backendProcessRunner
        task = GenerationPreset.quickTextPreview.makeTask()
    }

    /// Refreshes the Homebrew, uv, and MLX-Gen installation state.
    func refreshSystemStatus() async {
        guard isRefreshingSystemStatus == false else { return }
        isRefreshingSystemStatus = true
        systemStatusError = nil
        defer { isRefreshingSystemStatus = false }

        do {
            systemStatus = try await systemStatusService.currentStatus()
        } catch is CancellationError {
            return
        } catch {
            systemStatus = .unavailable
            systemStatusError = error.localizedDescription
        }
    }

    /// Replaces the editor contents with a task created from a preset.
    ///
    /// - Parameter preset: The preset whose defaults should be applied.
    func apply(_ preset: GenerationPreset) {
        selectedPreset = preset
        task = preset.makeTask()
    }

    /// Performs a confirmed installation, update, or model-download action.
    ///
    /// - Parameter action: The action the user explicitly approved.
    func perform(_ action: BackendAction) async {
        let command = BackendActionCommandBuilder().makeCommand(
            for: action,
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        await run(command, title: action.title)
        await refreshSystemStatus()
    }

    /// Starts generation using a unique output file in the user's Movies directory.
    func generateVideo() async {
        let issues = GenerationTaskValidator().issues(in: task)
        guard issues.isEmpty else {
            backendOperationError = issues.map(\.message).joined(separator: " ")
            return
        }

        do {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            let outputURL = homeDirectory
                .appending(path: "Movies")
                .appending(path: "mlxgen-\(task.identifier.uuidString.prefix(8)).mp4")
            let command = try GenerationCommandBuilder().makeCommand(
                for: task,
                executableURL: homeDirectory.appending(path: ".local/bin/mlxgen"),
                outputURL: outputURL
            )
            await run(command, title: "Generating \(task.name)")
        } catch {
            backendOperationError = error.localizedDescription
        }
    }

    /// Cancels the active backend process when it is safe to do so.
    func cancelBackendOperation() async {
        await backendProcessRunner.cancel()
    }

    /// Consumes a backend stream and reduces it into user-visible operation state.
    private func run(_ command: GenerationCommand, title: String) async {
        backendOperation = BackendOperationState(title: title)
        backendOperationError = nil

        do {
            let events = await backendProcessRunner.events(for: command)
            for try await event in events {
                apply(event)
            }
        } catch is CancellationError {
            backendOperation?.message = "Cancelled"
            backendOperation?.isRunning = false
        } catch {
            backendOperation?.message = "Stopped"
            backendOperation?.isRunning = false
            backendOperationError = error.localizedDescription
        }
    }

    /// Applies one normalized backend event to the visible operation state.
    private func apply(_ event: BackendEvent) {
        switch event {
        case .started:
            backendOperation?.message = "Running…"
        case .output(let line):
            backendOperation?.message = line
            backendOperation?.appendOutput(line)
        case .structured(let event):
            backendOperation?.message = event.message ?? event.type.capitalized
            backendOperation?.progressFraction = event.progressFraction
            if let path = event.path {
                backendOperation?.appendOutput("Saved: \(path)")
            }
        case .completed:
            backendOperation?.message = "Complete"
            backendOperation?.progressFraction = 1
            backendOperation?.isComplete = true
            backendOperation?.isRunning = false
        }
    }
}
