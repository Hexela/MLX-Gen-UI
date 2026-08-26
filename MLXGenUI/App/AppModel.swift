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

    /// Installation and update state keyed by model repository identifier.
    private(set) var modelStatuses: [String: ModelInstallationStatus] = Dictionary(
        uniqueKeysWithValues: WanModel.catalog.map { ($0.id, .checking) }
    )

    /// Tasks retained in the app's local library.
    private(set) var savedTasks: [SavedTaskRecord] = []

    /// Successfully generated local video artifacts.
    private(set) var generatedVideos: [GeneratedVideoRecord] = []

    /// A user-facing persistence error from the task or video library.
    private(set) var libraryError: String?

    /// The service used to inspect locally installed command-line tools.
    private let systemStatusService: SystemStatusService

    /// The runner that owns long-lived installation, download, and generation processes.
    private let backendProcessRunner: BackendProcessRunner

    /// The service that inspects the local Hugging Face cache and Hub revisions.
    private let modelService: HuggingFaceModelService

    /// The store that persists tasks and generated-video history.
    private let libraryStore: LibraryStore

    /// Creates an application model with injectable service dependencies.
    ///
    /// - Parameters:
    ///   - systemStatusService: The service that inspects backend dependencies.
    ///   - backendProcessRunner: The runner that owns long-lived backend processes.
    ///   - modelService: The service that compares local and remote model revisions.
    ///   - libraryStore: The store that persists task and generated-video libraries.
    init(
        systemStatusService: SystemStatusService = SystemStatusService(),
        backendProcessRunner: BackendProcessRunner = BackendProcessRunner(),
        modelService: HuggingFaceModelService = HuggingFaceModelService(),
        libraryStore: LibraryStore = LibraryStore()
    ) {
        self.systemStatusService = systemStatusService
        self.backendProcessRunner = backendProcessRunner
        self.modelService = modelService
        self.libraryStore = libraryStore
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
        _ = await run(command, title: action.title)
        await refreshSystemStatus()
        if case .downloadModel = action {
            await refreshModelStatuses()
        }
    }

    /// Refreshes local installation and remote update state for curated models.
    func refreshModelStatuses() async {
        modelStatuses = await modelService.statuses(for: WanModel.catalog)
    }

    /// Loads saved tasks and generated-video history from Application Support.
    func loadLibraries() async {
        do {
            async let tasks = libraryStore.loadTasks()
            async let videos = libraryStore.loadVideos()
            savedTasks = try await tasks
            generatedVideos = try await videos
            libraryError = nil
        } catch {
            libraryError = error.localizedDescription
        }
    }

    /// Saves the currently edited task to the local task library.
    func saveCurrentTask() async {
        do {
            savedTasks = try await libraryStore.save(task, in: savedTasks)
            libraryError = nil
        } catch {
            libraryError = error.localizedDescription
        }
    }

    /// Replaces the editor with a task from the local library.
    ///
    /// - Parameter record: The saved task to load.
    func load(_ record: SavedTaskRecord) {
        task = record.task
        selection = .createVideo
    }

    /// Replaces the editor with a task imported from a portable document.
    ///
    /// - Parameter document: The decoded portable task document.
    func importTask(from document: GenerationTaskDocument) {
        task = document.task
        selection = .createVideo
    }

    /// Sets the destination used by the next generation.
    ///
    /// - Parameter URL: The user-selected MP4 destination.
    func setOutputURL(_ URL: URL) {
        task.outputURL = URL
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
            let outputURL = task.outputURL ?? homeDirectory
                .appending(path: "Movies")
                .appending(
                    path: "mlxgen-\(task.identifier.uuidString.prefix(8))-\(UUID().uuidString.prefix(8)).mp4"
                )
            let command = try GenerationCommandBuilder().makeCommand(
                for: task,
                executableURL: homeDirectory.appending(path: ".local/bin/mlxgen"),
                outputURL: outputURL
            )
            let completed = await run(command, title: "Generating \(task.name)")
            if completed {
                let record = GeneratedVideoRecord(
                    id: UUID(),
                    task: task,
                    outputURL: outputURL,
                    createdAt: .now
                )
                generatedVideos = try await libraryStore.add(record, to: generatedVideos)
                libraryError = nil
            }
        } catch {
            backendOperationError = error.localizedDescription
        }
    }

    /// Cancels the active backend process when it is safe to do so.
    func cancelBackendOperation() async {
        await backendProcessRunner.cancel()
    }

    /// Consumes a backend stream and reduces it into user-visible operation state.
    private func run(_ command: GenerationCommand, title: String) async -> Bool {
        backendOperation = BackendOperationState(title: title)
        backendOperationError = nil

        do {
            let events = await backendProcessRunner.events(for: command)
            for try await event in events {
                apply(event)
            }
            return backendOperation?.isComplete == true
        } catch is CancellationError {
            backendOperation?.message = "Cancelled"
            backendOperation?.isRunning = false
            return false
        } catch {
            backendOperation?.message = "Stopped"
            backendOperation?.isRunning = false
            backendOperationError = error.localizedDescription
            return false
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
