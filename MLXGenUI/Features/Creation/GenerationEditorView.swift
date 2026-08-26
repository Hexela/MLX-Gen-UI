import SwiftUI
import UniformTypeIdentifiers

/// Edits the user-facing inputs for one Wan video-generation task.
struct GenerationEditorView: View {
    /// The shared application state supplied by the root scene.
    @Environment(AppModel.self) private var appModel
    /// Controls presentation of the starting-image picker.
    @State private var isChoosingImage = false
    /// Controls presentation of advanced sampling settings.
    @State private var showsAdvancedSettings = false
    /// Controls confirmation before a potentially long generation begins.
    @State private var isConfirmingGeneration = false

    /// The generation editor hierarchy.
    var body: some View {
        @Bindable var appModel = appModel

        Form {
            presetSection
            workflowSection(task: $appModel.task)
            promptSection(task: $appModel.task)
            outputSection(task: $appModel.task)
            advancedSection(task: $appModel.task)
            commandPreviewSection
            generationSection
            BackendOperationView()
        }
        .formStyle(.grouped)
        .navigationTitle("Create Video")
        .fileImporter(
            isPresented: $isChoosingImage,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false,
            onCompletion: selectImage
        )
    }

    /// Controls for selecting a curated task preset.
    private var presetSection: some View {
        @Bindable var appModel = appModel

        return Section("Start with a Preset") {
            Picker("Preset", selection: $appModel.selectedPreset) {
                ForEach(GenerationPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .onChange(of: appModel.selectedPreset) { _, preset in
                appModel.apply(preset)
            }

            Text(appModel.selectedPreset.summary)
                .foregroundStyle(.secondary)
        }
    }

    /// Controls that select a backend route and optional starting image.
    private func workflowSection(task: Binding<GenerationTask>) -> some View {
        Section("Workflow") {
            Picker("Create from", selection: task.workflow) {
                ForEach(GenerationWorkflow.allCases) { workflow in
                    Text(workflow.title).tag(workflow)
                }
            }
            .pickerStyle(.segmented)

            if task.wrappedValue.workflow == .imageToVideo {
                LabeledContent("Starting image") {
                    HStack {
                        Text(task.wrappedValue.sourceImageURL?.lastPathComponent ?? "None selected")
                            .foregroundStyle(task.wrappedValue.sourceImageURL == nil ? .secondary : .primary)
                        Button("Choose…") {
                            isChoosingImage = true
                        }
                    }
                }
            }
        }
    }

    /// Controls for positive and negative generation prompts.
    private func promptSection(task: Binding<GenerationTask>) -> some View {
        Section("Prompt") {
            TextField("Describe the scene and motion", text: task.prompt, axis: .vertical)
                .lineLimit(4...10)
            TextField("Content to avoid (optional)", text: task.negativePrompt, axis: .vertical)
                .lineLimit(2...6)
        }
    }

    /// Controls for video geometry and timing.
    private func outputSection(task: Binding<GenerationTask>) -> some View {
        Section("Video") {
            HStack {
                TextField("Width", value: task.width, format: .number)
                Text("×")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Height", value: task.height, format: .number)
            }
            LabeledContent("Canvas", value: "\(task.wrappedValue.width) × \(task.wrappedValue.height) pixels")
            Stepper("Frames: \(task.wrappedValue.frameCount)", value: task.frameCount, in: 1...121)
            Stepper("Frame rate: \(task.wrappedValue.framesPerSecond) fps", value: task.framesPerSecond, in: 1...60)
            LabeledContent("Approximate duration", value: task.wrappedValue.duration.formatted(.units(allowed: [.seconds], width: .wide)))
        }
    }

    /// Less frequently changed sampling and reproducibility controls.
    private func advancedSection(task: Binding<GenerationTask>) -> some View {
        Section {
            DisclosureGroup("Advanced Settings", isExpanded: $showsAdvancedSettings) {
                TextField("Model", text: task.modelIdentifier)
                Stepper("Denoising steps: \(task.wrappedValue.stepCount)", value: task.stepCount, in: 1...100)
                TextField("Guidance", value: task.guidance, format: .number.precision(.fractionLength(0...2)))
                TextField("Secondary guidance", value: task.secondaryGuidance, format: .number.precision(.fractionLength(0...2)))
                Toggle("Use low-memory mode", isOn: task.usesLowMemoryMode)
                Toggle("Write generation metadata", isOn: task.writesMetadata)
            }
        }
    }

    /// Validation feedback and a reproducible command preview.
    private var commandPreviewSection: some View {
        Section("Ready Check") {
            let issues = GenerationTaskValidator().issues(in: appModel.task)
            if issues.isEmpty {
                Label("The task is ready to run.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                ForEach(issues) { issue in
                    Label(issue.message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Text(commandPreview)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .foregroundStyle(.secondary)
        }
    }

    /// Starts generation only after the user acknowledges its potential cost.
    private var generationSection: some View {
        Section {
            Button("Generate Video", systemImage: "sparkles.rectangle.stack") {
                isConfirmingGeneration = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                GenerationTaskValidator().issues(in: appModel.task).isEmpty == false
                    || appModel.systemStatus.isReady == false
                    || appModel.backendOperation?.isRunning == true
            )
            .confirmationDialog(
                "Start this generation?",
                isPresented: $isConfirmingGeneration,
                titleVisibility: .visible
            ) {
                Button("Generate") {
                    Task(name: "Generate video") {
                        await appModel.generateVideo()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Local video generation may use substantial memory and take many minutes or hours.")
            }

            if appModel.systemStatus.isReady == false {
                Text("Complete backend setup in System Status before generating.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// A display-only command for the current task or its validation error.
    private var commandPreview: String {
        do {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            return try GenerationCommandBuilder().makeCommand(
                for: appModel.task,
                executableURL: homeDirectory.appending(path: ".local/bin/mlxgen"),
                outputURL: homeDirectory.appending(path: "Movies/output.mp4")
            ).displayString
        } catch {
            return "Complete the required fields to preview the command."
        }
    }

    /// Applies the single image returned by the system file importer.
    private func selectImage(_ result: Result<[URL], any Error>) {
        guard case .success(let URLs) = result, let URL = URLs.first else { return }
        appModel.task.sourceImageURL = URL
    }
}
