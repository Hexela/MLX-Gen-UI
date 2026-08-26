import SwiftUI
import UniformTypeIdentifiers

/// A portable `.mlxgentask` document containing reproducible generation values.
struct GenerationTaskDocument: FileDocument {
    /// The generation task stored by the document.
    var task: GenerationTask

    /// File types the document can read.
    static var readableContentTypes: [UTType] { [.mlxGenTask] }

    /// Creates a document around an existing task.
    ///
    /// - Parameter task: The task to serialize.
    init(task: GenerationTask) {
        self.task = task
    }

    /// Decodes a task from a file wrapper.
    ///
    /// - Parameter configuration: The file contents supplied by SwiftUI.
    /// - Throws: A Cocoa error when regular-file data is absent, or a decoding error for invalid contents.
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        task = try JSONDecoder.taskDocumentDecoder.decode(GenerationTask.self, from: data)
    }

    /// Encodes the task as a JSON file wrapper.
    ///
    /// - Parameter configuration: The requested write configuration.
    /// - Returns: A regular-file wrapper containing formatted JSON.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try JSONEncoder.taskDocumentEncoder.encode(task))
    }
}

/// The exported uniform type for portable MLXGenUI task documents.
extension UTType {
    /// A JSON-backed, versioned MLXGenUI generation task.
    static let mlxGenTask = UTType(exportedAs: "com.example.mlxgenui.task", conformingTo: .json)
}

/// Shared JSON configuration for stable task-document dates and formatting.
private extension JSONEncoder {
    /// An encoder configured for readable, deterministic task documents.
    static var taskDocumentEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

/// Shared JSON configuration for task documents.
private extension JSONDecoder {
    /// A decoder matching ``JSONEncoder/taskDocumentEncoder``.
    static var taskDocumentDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
