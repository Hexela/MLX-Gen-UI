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
        NavigationSplitView {
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
                }
            }
        } detail: {
            if let selection {
                GeneratedVideoDetailView(record: selection)
            } else {
                ContentUnavailableView("Choose a Video", systemImage: "play.rectangle")
            }
        }
        .navigationTitle("Generated Videos")
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
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(minHeight: 280)

                Text(record.task.name)
                    .font(.title2)
                Text(record.task.prompt)
                LabeledContent("Created", value: record.createdAt.formatted(.dateTime))
                LabeledContent("File", value: record.outputURL.path)
                    .textSelection(.enabled)
            }
            .padding()
        }
        .navigationTitle(record.outputURL.lastPathComponent)
    }
}
