import SwiftUI

/// Presents progress, cancellation, diagnostics, and errors for a backend operation.
struct BackendOperationView: View {
    /// The shared application state supplied by the root scene.
    @Environment(AppModel.self) private var appModel
    /// Controls disclosure of bounded diagnostic output.
    @State private var showsDetails = false

    /// The backend operation presentation.
    var body: some View {
        if let operation = appModel.backendOperation {
            Section(operation.title) {
                if operation.isRunning, let progressFraction = operation.progressFraction {
                    ProgressView(value: progressFraction) {
                        Text(operation.message)
                    }
                } else if operation.isRunning {
                    ProgressView {
                        Text(operation.message)
                    }
                } else if operation.isComplete {
                    Label(operation.message, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label(operation.message, systemImage: "stop.circle.fill")
                        .foregroundStyle(.secondary)
                }

                if let error = appModel.backendOperationError {
                    Label(error, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }

                HStack {
                    if operation.isRunning {
                        Button("Cancel", role: .cancel) {
                            Task(name: "Cancel backend operation") {
                                await appModel.cancelBackendOperation()
                            }
                        }
                    }
                    if operation.outputLines.isEmpty == false {
                        Button(showsDetails ? "Hide Details" : "Show Details") {
                            showsDetails.toggle()
                        }
                    }
                }

                if showsDetails {
                    Text(operation.outputLines.joined(separator: "\n"))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxHeight: 180)
                }
            }
        }
    }
}
