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

    /// The service used to inspect locally installed command-line tools.
    private let systemStatusService: SystemStatusService

    /// Creates an application model with injectable service dependencies.
    ///
    /// - Parameter systemStatusService: The service that inspects backend dependencies.
    init(systemStatusService: SystemStatusService = SystemStatusService()) {
        self.systemStatusService = systemStatusService
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
}
