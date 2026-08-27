import SwiftUI

/// Lists previous generation attempts and restores their settings into the editor.
struct GenerationHistoryView: View {
    /// The shared application state supplied by the root scene.
    @Environment(AppModel.self) private var appModel

    /// The generation-attempt history hierarchy.
    var body: some View {
        Group {
            if appModel.generationHistory.isEmpty {
                ContentUnavailableView(
                    "No Generation History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Each confirmed generation attempt will appear here, including attempts that do not complete.")
                )
            } else {
                List(appModel.generationHistory) { record in
                    HStack {
                        Button {
                            appModel.restore(record)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(record.task.prompt)
                                    .font(.headline)
                                    .lineLimit(2)
                                Label(record.task.workflow.title, systemImage: "film")
                                Text(
                                    "\(record.task.width) × \(record.task.height) · \(record.task.framesPerSecond) fps · \(record.task.stepCount) steps"
                                )
                                .foregroundStyle(.secondary)
                                Text(record.attemptedAt, format: .dateTime)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .help("Restore every option from this attempt in Create Video, ready to generate again.")
                        .accessibilityHint("Loads this attempt's settings into Create Video")

                        DeleteGenerationHistoryButton(record: record)
                    }
                }
            }
        }
        .navigationTitle("History")
        .safeAreaInset(edge: .bottom) {
            if let error = appModel.libraryError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .padding()
                    .background(.bar)
            }
        }
    }
}

/// Offers a confirmed, accessible deletion control for one generation attempt.
private struct DeleteGenerationHistoryButton: View {
    @Environment(AppModel.self) private var appModel
    let record: GenerationHistoryRecord
    @State private var isConfirmingDeletion = false

    var body: some View {
        Button("Delete History Item", systemImage: "trash", role: .destructive) {
            isConfirmingDeletion = true
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .help("Delete this generation history item")
        .confirmationDialog(
            "Delete History Item?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await appModel.delete(record)
                }
            }
        } message: {
            Text("This removes the saved generation attempt. It does not delete any generated video.")
        }
    }
}
