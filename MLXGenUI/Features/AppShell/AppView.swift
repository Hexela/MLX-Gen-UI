import SwiftUI

/// The root navigation and detail presentation for the primary app window.
struct AppView: View {
    /// The shared application state supplied by ``MLXGenUIApp``.
    @Environment(AppModel.self) private var appModel

    /// The root view hierarchy.
    var body: some View {
        @Bindable var appModel = appModel

        NavigationSplitView {
            List(AppDestination.allCases, selection: $appModel.selection) { destination in
                Label(destination.title, systemImage: destination.systemImage)
                    .tag(destination)
            }
            .navigationTitle("MLXGenUI")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            detailView(for: appModel.selection)
        }
        .task {
            await appModel.refreshSystemStatus()
            await appModel.loadLibraries()
        }
    }

    /// Creates the detail view for a selected sidebar destination.
    @ViewBuilder
    private func detailView(for destination: AppDestination?) -> some View {
        switch destination {
        case .createVideo:
            GenerationEditorView()
        case .history:
            GenerationHistoryView()
        case .systemStatus:
            SystemStatusView()
        case .savedTasks:
            SavedTasksView()
        case .generatedVideos:
            GeneratedVideosView()
        case .models:
            ModelsView()
        case nil:
            ContentUnavailableView("Choose a Section", systemImage: "sidebar.left")
        }
    }
}
