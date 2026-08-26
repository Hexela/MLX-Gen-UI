import SwiftUI

/// Presents locally retained tasks and imports portable `.mlxgentask` documents.
struct SavedTasksView: View {
    /// The shared application state supplied by the root scene.
    @Environment(AppModel.self) private var appModel
    /// Controls presentation of the portable task importer.
    @State private var isImportingTask = false
    /// A user-facing import error.
    @State private var importError: String?

    /// The saved-task library hierarchy.
    var body: some View {
        Group {
            if appModel.savedTasks.isEmpty {
                ContentUnavailableView(
                    "No Saved Tasks",
                    systemImage: "doc.on.doc",
                    description: Text("Save the current editor values or import a .mlxgentask document.")
                )
            } else {
                List(appModel.savedTasks) { record in
                    Button {
                        appModel.load(record)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.task.name)
                                .font(.headline)
                            Text(record.task.workflow.title)
                            Text(record.savedAt, format: .dateTime)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Loads this task into the video editor")
                }
            }
        }
        .navigationTitle("Saved Tasks")
        .toolbar {
            Button("Save Current Task", systemImage: "square.and.arrow.down") {
                Task(name: "Save current task") {
                    await appModel.saveCurrentTask()
                }
            }
            Button("Import Task", systemImage: "square.and.arrow.down.on.square") {
                isImportingTask = true
            }
        }
        .fileImporter(
            isPresented: $isImportingTask,
            allowedContentTypes: [.mlxGenTask],
            allowsMultipleSelection: false,
            onCompletion: importTask
        )
        .alert("Unable to Import Task", isPresented: importErrorIsPresented) {
        } message: {
            Text(importError ?? "The selected document could not be read.")
        }
        .safeAreaInset(edge: .bottom) {
            if let error = appModel.libraryError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .padding()
                    .background(.bar)
            }
        }
    }

    /// Imports the first selected portable task document.
    private func importTask(_ result: Result<[URL], any Error>) {
        do {
            let URL = try result.get().first
            guard let URL else { return }
            let data = try Data(contentsOf: URL)
            let task = try JSONDecoder().decode(GenerationTask.self, from: data)
            appModel.importTask(from: GenerationTaskDocument(task: task))
        } catch {
            importError = error.localizedDescription
        }
    }

    /// Presents the import alert whenever an error message exists.
    private var importErrorIsPresented: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { isPresented in
                if isPresented == false { importError = nil }
            }
        )
    }
}
