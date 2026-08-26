import SwiftUI

/// Presents the curated Wan model catalog and explicit download actions.
struct ModelsView: View {
    /// The shared application state supplied by the root scene.
    @Environment(AppModel.self) private var appModel
    /// The model awaiting download confirmation.
    @State private var pendingDownload: WanModel?

    /// The model-management hierarchy.
    var body: some View {
        Form {
            Section {
                Text("Models are large and download from their upstream host only after you confirm. Existing cached files are reused by MLX-Gen.")
                    .foregroundStyle(.secondary)
            }

            ForEach(WanModel.catalog) { model in
                Section(model.name) {
                    Text(model.summary)
                    LabeledContent("Workflows", value: workflowSummary(for: model))
                    LabeledContent("Storage", value: model.storageSummary)
                    Text(model.id)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                    Button("Download Model", systemImage: "arrow.down.circle") {
                        pendingDownload = model
                    }
                    .disabled(appModel.backendOperation?.isRunning == true)
                    .confirmationDialog(
                        "Download \(model.name)?",
                        isPresented: downloadConfirmation(for: model),
                        titleVisibility: .visible
                    ) {
                        Button("Download") {
                            pendingDownload = nil
                            Task(name: "Download \(model.name)") {
                                await appModel.perform(.downloadModel(model))
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            pendingDownload = nil
                        }
                    } message: {
                        Text("This may download tens of gigabytes and can take a long time.")
                    }
                }
            }

            BackendOperationView()
        }
        .formStyle(.grouped)
        .navigationTitle("Models")
    }

    /// Creates a readable workflow list for a model.
    private func workflowSummary(for model: WanModel) -> String {
        model.workflows.map(\.title).sorted().joined(separator: ", ")
    }

    /// Binds a model-specific confirmation dialog to the pending download.
    private func downloadConfirmation(for model: WanModel) -> Binding<Bool> {
        Binding(
            get: { pendingDownload?.id == model.id },
            set: { isPresented in
                if isPresented == false, pendingDownload?.id == model.id {
                    pendingDownload = nil
                }
            }
        )
    }
}
