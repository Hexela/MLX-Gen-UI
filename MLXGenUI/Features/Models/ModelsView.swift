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
                    let status = appModel.modelStatuses[model.id] ?? .checking
                    Text(model.summary)
                    Label(status.title, systemImage: status.systemImage)
                    LabeledContent("Workflows", value: workflowSummary(for: model))
                    LabeledContent("Storage", value: model.storageSummary)
                    Text(model.id)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                    if let actionTitle = status.actionTitle {
                        Button(actionTitle, systemImage: "arrow.down.circle") {
                            pendingDownload = model
                        }
                        .disabled(appModel.backendOperation?.isRunning == true)
                        .confirmationDialog(
                            "\(actionTitle): \(model.name)?",
                            isPresented: downloadConfirmation(for: model),
                            titleVisibility: .visible
                        ) {
                            Button(actionTitle) {
                                pendingDownload = nil
                                Task(name: "Download \(model.name)") {
                                    await appModel.perform(.downloadModel(model))
                                }
                            }
                            Button("Cancel", role: .cancel) {
                                pendingDownload = nil
                            }
                        } message: {
                            Text("MLX-Gen will reuse unchanged cached files. New or changed files may still require a large download.")
                        }
                    }
                }
            }

            BackendOperationView()
        }
        .formStyle(.grouped)
        .navigationTitle("Models")
        .task {
            await appModel.refreshModelStatuses()
        }
        .toolbar {
            Button("Refresh Models", systemImage: "arrow.clockwise") {
                Task(name: "Refresh model status") {
                    await appModel.refreshModelStatuses()
                }
            }
        }
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
