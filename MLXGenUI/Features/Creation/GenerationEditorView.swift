import AppKit
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
    /// Controls export of the current portable task document.
    @State private var isExportingTask = false

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
        .fileExporter(
            isPresented: $isExportingTask,
            document: GenerationTaskDocument(task: appModel.task),
            contentType: .mlxGenTask,
            defaultFilename: appModel.task.name
        ) { result in
            if case .success = result {
                Task(name: "Save exported task to library") {
                    await appModel.saveCurrentTask()
                }
            }
        }
        .toolbar {
            Button("Save Task", systemImage: "square.and.arrow.down") {
                isExportingTask = true
            }
        }
        .task {
            selectCompatibleModel(for: appModel.task.workflow)
            await appModel.refreshModelStatuses()
        }
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
        let availableModels = WanModel.available(for: task.wrappedValue.workflow)
        let hasValidModelSelection = availableModels.contains {
            $0.id == task.wrappedValue.modelIdentifier
        }

        return Section("Workflow") {
            Picker("Create from", selection: task.workflow) {
                ForEach(GenerationWorkflow.allCases) { workflow in
                    Text(workflow.title).tag(workflow)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: task.wrappedValue.workflow) { _, workflow in
                selectCompatibleModel(for: workflow)
            }

            if hasValidModelSelection {
                Picker("Model", selection: task.modelIdentifier) {
                    ForEach(availableModels) { model in
                        Label(
                            model.name,
                            systemImage: (appModel.modelStatuses[model.id] ?? .checking).systemImage
                        )
                        .tag(model.id)
                    }
                }
                .accessibilityHint("Selects the Wan model used for this generation")
            } else {
                LabeledContent("Model", value: "Selecting a compatible model…")
                    .foregroundStyle(.secondary)
                    .task(id: task.wrappedValue.workflow) {
                        selectCompatibleModel(for: task.wrappedValue.workflow)
                    }
            }

            if let model = WanModel.model(withIdentifier: task.wrappedValue.modelIdentifier) {
                Text(model.summary)
                    .foregroundStyle(.secondary)
                LabeledContent(
                    "Model status",
                    value: (appModel.modelStatuses[model.id] ?? .checking).title
                )
            }

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
            Stepper("Frame rate: \(task.wrappedValue.framesPerSecond) fps", value: task.framesPerSecond, in: 1...60)
            TextField(
                "Desired duration (seconds)",
                value: targetDurationBinding,
                format: .number.precision(.fractionLength(0...2))
            )
            .accessibilityHint("Sets the exact duration of the finished, automatically assembled video")
            if let plan = longVideoPlan {
                LabeledContent(
                    "Generation plan",
                    value: plan.segments.count == 1
                        ? "1 segment"
                        : "\(plan.segments.count) segments with automatic handovers"
                )
                if plan.requiresAssembly {
                    Text("The app will generate each segment in order, prepare continuation frames, and join them into one video.")
                        .foregroundStyle(.secondary)
                }
            }
            LabeledContent("Output") {
                HStack {
                    Text(task.wrappedValue.outputURL?.path ?? "Movies folder (automatic name)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(task.wrappedValue.outputURL == nil ? .secondary : .primary)
                    Button("Choose…", action: chooseOutputURL)
                }
            }
        }
    }

    /// Less frequently changed sampling and reproducibility controls.
    private func advancedSection(task: Binding<GenerationTask>) -> some View {
        Section {
            DisclosureGroup("Advanced Settings", isExpanded: $showsAdvancedSettings) {
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

            if let continuationModel = requiredContinuationModel,
               requiredContinuationModelStatus.isInstalled == false {
                Label(
                    "Download \(continuationModel.name) before creating this longer video.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.orange)
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
                    || selectedModelStatus.isInstalled == false
                    || requiredContinuationModelStatus.isInstalled == false
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
            if selectedModelStatus == .notInstalled {
                Text("Download the selected model from Models before generating.")
                    .foregroundStyle(.secondary)
            }
            if let continuationModel = requiredContinuationModel,
               requiredContinuationModelStatus.isInstalled == false {
                Text("This longer video also needs \(continuationModel.name) for its continuation segments.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// The current local installation state of the selected model.
    private var selectedModelStatus: ModelInstallationStatus {
        appModel.modelStatuses[appModel.task.modelIdentifier] ?? .checking
    }

    /// The calculated segment plan for the editor's current values.
    private var longVideoPlan: LongVideoPlan? {
        guard let model = WanModel.model(withIdentifier: appModel.task.modelIdentifier) else { return nil }
        return LongVideoPlanner().makePlan(for: appModel.task, model: model)
    }

    /// The additional image-to-video model needed for a multi-segment text video.
    private var requiredContinuationModel: WanModel? {
        guard let plan = longVideoPlan,
              plan.requiresAssembly,
              let identifier = plan.continuationModelIdentifier,
              identifier != appModel.task.modelIdentifier else {
            return nil
        }
        return WanModel.model(withIdentifier: identifier)
    }

    /// Installation state of the paired continuation model, or installed when none is needed.
    private var requiredContinuationModelStatus: ModelInstallationStatus {
        guard let model = requiredContinuationModel else { return .installed(localRevision: nil) }
        return appModel.modelStatuses[model.id] ?? .checking
    }

    /// A nonoptional editor binding backed by the task's portable optional duration field.
    private var targetDurationBinding: Binding<Double> {
        Binding(
            get: {
                appModel.task.targetDurationSeconds
                    ?? Double(appModel.task.frameCount) / Double(appModel.task.framesPerSecond)
            },
            set: { appModel.task.targetDurationSeconds = $0 }
        )
    }

    /// A display-only command for the current task or its validation error.
    private var commandPreview: String {
        do {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            let outputURL = appModel.task.outputURL
                ?? homeDirectory.appending(path: "Movies/automatic-output-name.mp4")
            return try GenerationCommandBuilder().makeCommand(
                for: appModel.task,
                executableURL: homeDirectory.appending(path: ".local/bin/mlxgen"),
                outputURL: outputURL
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

    /// Presents the native macOS save panel for the generated MP4 destination.
    private func chooseOutputURL() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Movies")
        panel.nameFieldStringValue = "mlxgen-\(appModel.task.identifier.uuidString.prefix(8)).mp4"
        if panel.runModal() == .OK, let URL = panel.url {
            appModel.setOutputURL(URL)
        }
    }

    /// Selects the preferred curated model when the current model cannot run a workflow.
    ///
    /// - Parameter workflow: The newly selected generation workflow.
    private func selectCompatibleModel(for workflow: GenerationWorkflow) {
        let availableModels = WanModel.available(for: workflow)
        guard availableModels.contains(where: { $0.id == appModel.task.modelIdentifier }) == false,
              let preferredModel = availableModels.first else {
            return
        }
        appModel.task.modelIdentifier = preferredModel.id
    }
}
