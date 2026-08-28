import AVKit
import SwiftUI

/// Presents generated-video history with native AVKit playback.
struct GeneratedVideosView: View {
    /// The shared application state supplied by the root scene.
    @Environment(AppModel.self) private var appModel
    /// The history item selected for playback.
    @State private var selection: GeneratedVideoRecord?

    /// The generated-video library hierarchy.
    var body: some View {
        HSplitView {
            Group {
                if appModel.generatedVideos.isEmpty {
                    ContentUnavailableView(
                        "No Generated Videos",
                        systemImage: "play.rectangle.on.rectangle",
                        description: Text("Successful generations will be retained here.")
                    )
                } else {
                    List(appModel.generatedVideos, selection: $selection) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.task.name)
                                .font(.headline)
                            Text(record.createdAt, format: .dateTime)
                                .foregroundStyle(.secondary)
                        }
                        .tag(record)
                        .contextMenu {
                            DeleteGeneratedVideoButton(record: record)
                        }
                    }
                }
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 340)

            Group {
                if let selection {
                    GeneratedVideoDetailView(record: selection)
                } else {
                    ContentUnavailableView("Choose a Video", systemImage: "play.rectangle")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Generated Videos")
        .onChange(of: appModel.generatedVideos) { _, videos in
            if let selection, videos.contains(where: { $0.id == selection.id }) == false {
                self.selection = nil
            }
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
}

/// Plays one generated video and displays its reproducibility details.
private struct GeneratedVideoDetailView: View {
    /// The generated artifact to present.
    let record: GeneratedVideoRecord
    /// The stable AVKit player retained across SwiftUI body updates.
    @State private var player: AVPlayer

    /// Creates a detail view and its stable local video player.
    ///
    /// - Parameter record: The generated artifact to present.
    init(record: GeneratedVideoRecord) {
        self.record = record
        _player = State(initialValue: AVPlayer(url: record.outputURL))
    }

    /// The video player and metadata hierarchy.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VideoPlayer(player: player)
                    .aspectRatio(
                        Double(record.task.width) / Double(record.task.height),
                        contentMode: .fit
                    )
                    .frame(maxWidth: .infinity)

                Text(record.task.name)
                    .font(.title2)
                Text(record.task.prompt)
                LabeledContent("Created", value: record.createdAt.formatted(.dateTime))
                LabeledContent("File", value: record.outputURL.path)
                    .textSelection(.enabled)

                DeleteGeneratedVideoButton(record: record)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(record.outputURL.lastPathComponent)
        .onChange(of: record.id) {
            player.pause()
            player.replaceCurrentItem(with: AVPlayerItem(url: record.outputURL))
        }
        .onDisappear {
            player.pause()
        }
    }
}

/// Offers a confirmed, accessible deletion control for one generated artifact.
private struct DeleteGeneratedVideoButton: View {
    @Environment(AppModel.self) private var appModel
    let record: GeneratedVideoRecord
    @State private var isConfirmingDeletion = false

    var body: some View {
        Button("Delete Video", systemImage: "trash", role: .destructive) {
            isConfirmingDeletion = true
        }
        .buttonStyle(.borderless)
        .help("Move this generated video to the Trash")
        .confirmationDialog(
            "Move Video to Trash?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                Task {
                    await appModel.delete(record)
                }
            }
        } message: {
            Text("This removes the video from Generated Videos and moves its file to the Trash.")
        }
    }
}
