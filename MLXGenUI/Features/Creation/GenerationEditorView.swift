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
    /// Pixel information read from the selected starting image.
    @State private var sourceImageDetails: SourceImageDetails?

    /// Whether the editor exposes a user-supplied seed rather than choosing one automatically.
    @State private var usesFixedSeed = false

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
            usesFixedSeed = appModel.task.seed != nil
            selectCompatibleModel(for: appModel.task.workflow)
            enforceCanvasRequirements()
            refreshSourceImageDetails()
            await appModel.refreshModelStatuses()
        }
        .onChange(of: appModel.task.sourceImageURL) {
            refreshSourceImageDetails()
        }
        .onChange(of: appModel.task.identifier) {
            usesFixedSeed = appModel.task.seed != nil
            enforceCanvasRequirements()
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
            .help("Choose a ready-made set of options. Quick Text Preview is best for testing an idea; use a quality or image preset for a finished result.")
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
            .help("Choose Text to Video to create everything from a prompt, or Image to Video when you want to animate a specific starting image.")
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
                .help("Selects the generation model. The first compatible model is the recommended quality-focused choice; TI2V 5B uses less storage and supports both workflows.")
                .onChange(of: task.wrappedValue.modelIdentifier) {
                    enforceCanvasRequirements()
                }
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
                        .help("Choose a clear, high-resolution image with the same shape as the video canvas for the most stable result.")
                    }
                }

                if let sourceImageDetails {
                    LabeledContent("Image resolution", value: sourceImageDetails.resolutionDescription)

                    let recommendations = sourceImageDetails.recommendations(
                        targetWidth: task.wrappedValue.width,
                        targetHeight: task.wrappedValue.height
                    )
                    if recommendations.isEmpty {
                        Label(
                            "This image is a good size and shape for the selected canvas.",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)
                    } else {
                        ForEach(recommendations, id: \.self) { recommendation in
                            Label(recommendation, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                } else if task.wrappedValue.sourceImageURL != nil {
                    Label(
                        "The image resolution could not be read. For best results, use an image at least as large as the video canvas and with the same aspect ratio.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
            }
        }
    }

    /// Controls for positive and negative generation prompts.
    private func promptSection(task: Binding<GenerationTask>) -> some View {
        Section("Prompt") {
            VStack(alignment: .leading) {
                Text("Describe the scene and motion")
                TextField("Describe the scene and motion", text: task.prompt, axis: .vertical)
                    .labelsHidden()
                    .lineLimit(4...10)
                    .accessibilityLabel("Describe the scene and motion")
                    .help("Describe the subject, setting, movement, and camera motion. Specific visual details and one clear action usually give the most coherent result. For example: A slow camera push toward a lighthouse as waves break below.")
            }

            VStack(alignment: .leading) {
                Text("Content to avoid (optional)")
                TextField("Content to avoid", text: task.negativePrompt, axis: .vertical)
                    .labelsHidden()
                    .lineLimit(2...6)
                    .accessibilityLabel("Content to avoid")
                    .help("List unwanted visual traits, separated by commas. For example: text, watermark, flicker, distorted hands. A useful default is: text, watermark, flicker, distorted subject, unstable background.")
            }
        }
    }

    /// Controls for video geometry and timing.
    private func outputSection(task: Binding<GenerationTask>) -> some View {
        let dimensionMultiple = selectedModel?.spatialDimensionMultiple ?? 1

        return Section("Video") {
            HStack {
                Stepper(
                    "Width: \(task.wrappedValue.width) px",
                    value: task.width,
                    in: dimensionMultiple...4096,
                    step: dimensionMultiple
                )
                    .help("Sets horizontal resolution. 832 is a good quality landscape width; 480 is faster and uses less memory.")
                Text("×")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Stepper(
                    "Height: \(task.wrappedValue.height) px",
                    value: task.height,
                    in: dimensionMultiple...4096,
                    step: dimensionMultiple
                )
                    .help("Sets vertical resolution. Use 480 for landscape or 832 for portrait, paired with the corresponding width.")
            }
            LabeledContent("Canvas", value: "\(task.wrappedValue.width) × \(task.wrappedValue.height) pixels")
            if dimensionMultiple > 1 {
                Text("This model requires width and height to be multiples of \(dimensionMultiple) pixels.")
                    .foregroundStyle(.secondary)
            }
            Stepper("Frame rate: \(task.wrappedValue.framesPerSecond) fps", value: task.framesPerSecond, in: 1...60)
                .help("Controls playback smoothness. 16 fps is the recommended model-native default; higher values require more generated frames for the same duration.")
            TextField(
                "Desired duration (seconds)",
                value: targetDurationBinding,
                format: .number.precision(.fractionLength(0...2))
            )
            .accessibilityHint("Sets the exact duration of the finished, automatically assembled video")
            .help("Sets the finished video length. Short clips are quicker and more consistent; longer clips are generated as multiple joined segments.")
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
            LabeledContent("Output base") {
                HStack {
                    Text(task.wrappedValue.outputURL?.path ?? "Movies folder (automatic name)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(task.wrappedValue.outputURL == nil ? .secondary : .primary)
                    Button("Choose…", action: chooseOutputURL)
                        .help("Choose where to save the finished MP4. Leave unchanged to save it automatically in Movies.")
                }
            }
        }
    }

    /// Less frequently changed sampling and reproducibility controls.
    private func advancedSection(task: Binding<GenerationTask>) -> some View {
        Section {
            DisclosureGroup("Advanced Settings", isExpanded: $showsAdvancedSettings) {
                Stepper("Denoising steps: \(task.wrappedValue.stepCount)", value: task.stepCount, in: 1...100)
                    .help("More steps can improve detail but take longer. 20 is a good quality default; about 12 is useful for previews.")
                TextField("Guidance", value: task.guidance, format: .number.precision(.fractionLength(0...2)))
                    .help("Controls how strongly the first generation stage follows the prompt. 4 is the recommended balanced default.")
                if WanModel.model(withIdentifier: task.wrappedValue.modelIdentifier)?.supportsSecondaryGuidance == true {
                    TextField("Secondary guidance", value: task.secondaryGuidance, format: .number.precision(.fractionLength(0...2)))
                        .help("Controls prompt strength in the second A14B generation stage. 3 is the recommended balanced default.")
                } else {
                    LabeledContent("Secondary guidance", value: "Not used by this model")
                        .foregroundStyle(.secondary)
                        .help("Secondary guidance is only available for A14B models with two-transformer boundary routing. The selected 5B model uses its primary guidance value instead.")
                }
                Toggle("Use a fixed seed", isOn: $usesFixedSeed)
                    .help("Use a specific seed to reproduce a single result. Multi-video batches always use unique random seeds.")
                    .onChange(of: usesFixedSeed) { _, isEnabled in
                        task.wrappedValue.seed = isEnabled ? (task.wrappedValue.seed ?? 0) : nil
                    }
                if usesFixedSeed {
                    TextField("Seed", value: fixedSeedBinding, format: .number.grouping(.never))
                        .help("Enter a whole number from 0 through \(GenerationTaskValidator.maximumSeed).")
                }
                Toggle("Use low-memory mode", isOn: task.usesLowMemoryMode)
                    .help("Reduces peak memory use, usually with a speed cost. Keep this on unless you have ample unified memory and want maximum speed.")
                Toggle("Write generation metadata", isOn: task.writesMetadata)
                    .help("Saves generation settings beside the video so the result can be reproduced. Keeping this on is recommended.")
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
            Stepper(
                "Videos to generate: \(appModel.generationCount)",
                value: generationCountBinding,
                in: 1...GenerationBatch.maximumCount
            )
            .help("Queues videos with the same settings and generates them in sequence. Each video in a batch uses a unique random seed.")

            if appModel.generationCount > 1 {
                Text("Each video will use a different random seed. The full batch runs automatically in sequence.")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Button(
                    appModel.generationCount == 1 ? "Generate Video" : "Generate \(appModel.generationCount) Videos",
                    systemImage: "sparkles.rectangle.stack"
                ) {
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

                Spacer(minLength: 0)

                GenerationTimeEstimateView(estimate: appModel.generationTimeEstimate)
            }
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
                Text(appModel.generationCount == 1
                    ? "Local video generation may use substantial memory and take many minutes or hours."
                    : "The videos will be generated one after another without further confirmation. Local generation may take many hours.")
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

    /// The curated model currently selected in the editor.
    private var selectedModel: WanModel? {
        WanModel.model(withIdentifier: appModel.task.modelIdentifier)
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

    /// A nonoptional binding shown only while the task has a fixed seed.
    private var fixedSeedBinding: Binding<Int> {
        Binding(
            get: { appModel.task.seed ?? 0 },
            set: { appModel.task.seed = $0 }
        )
    }

    /// Keeps the editor's batch count within the supported queue limit.
    private var generationCountBinding: Binding<Int> {
        Binding(
            get: { appModel.generationCount },
            set: { appModel.generationCount = min(max($0, 1), GenerationBatch.maximumCount) }
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
        sourceImageDetails = SourceImageDetails.load(from: URL)
    }

    /// Refreshes the displayed metadata when a task or starting image changes.
    private func refreshSourceImageDetails() {
        sourceImageDetails = appModel.task.sourceImageURL.flatMap(SourceImageDetails.load)
    }

    /// Presents the native macOS save panel for the generated MP4 destination.
    private func chooseOutputURL() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Movies")
        panel.nameFieldStringValue = "mlxgen.mp4"
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
        enforceCanvasRequirements()
    }

    /// Rounds imported, preset, or previously entered dimensions to the selected model's patch boundary.
    private func enforceCanvasRequirements() {
        guard let model = selectedModel else { return }
        appModel.task.width = model.adjustedSpatialDimension(appModel.task.width)
        appModel.task.height = model.adjustedSpatialDimension(appModel.task.height)
    }
}
