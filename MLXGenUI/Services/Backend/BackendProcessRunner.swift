@preconcurrency import Foundation

/// Runs one long-lived backend process and streams its output with cooperative cancellation.
actor BackendProcessRunner {
    /// The currently running process, if any.
    private var activeProcess: Process?
    /// The task consuming the active process output.
    private var activeTask: Task<Void, Never>?

    /// Starts a command and returns a single-consumer event stream.
    ///
    /// - Parameter command: The executable and arguments to launch directly.
    /// - Returns: Events that finish when the process exits or the consumer cancels.
    /// - Important: Only one backend process may run at a time.
    func events(for command: GenerationCommand) -> AsyncThrowingStream<BackendEvent, any Error> {
        AsyncThrowingStream { continuation in
            guard activeProcess == nil else {
                continuation.finish(throwing: BackendProcessError.alreadyRunning)
                return
            }

            let task = Task(name: "MLX-Gen backend process") {
                await self.run(command, continuation: continuation)
            }
            activeTask = task
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Requests termination of the current process and cancels output consumption.
    func cancel() {
        activeTask?.cancel()
        if let activeProcess, activeProcess.isRunning {
            activeProcess.terminate()
        }
    }

    /// Owns the process lifecycle and translates output lines into backend events.
    private func run(
        _ command: GenerationCommand,
        continuation: AsyncThrowingStream<BackendEvent, any Error>.Continuation
    ) async {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = command.executableURL
        process.arguments = command.arguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        activeProcess = process

        do {
            try process.run()
            continuation.yield(.started)

            for try await line in outputPipe.fileHandleForReading.bytes.lines {
                try Task.checkCancellation()
                if let event = MLXGenEventDecoder().decode(line) {
                    continuation.yield(.structured(event))
                } else if line.isEmpty == false {
                    continuation.yield(.output(line))
                }
            }

            process.waitUntilExit()
            try Task.checkCancellation()
            guard process.terminationStatus == 0 else {
                throw BackendProcessError.nonzeroExit(process.terminationStatus)
            }
            continuation.yield(.completed)
            continuation.finish()
        } catch is CancellationError {
            if process.isRunning {
                process.terminate()
            }
            continuation.finish(throwing: CancellationError())
        } catch {
            if process.isRunning {
                process.terminate()
            }
            continuation.finish(throwing: error)
        }

        activeProcess = nil
        activeTask = nil
    }
}

/// Failures specific to long-running backend process execution.
enum BackendProcessError: LocalizedError, Equatable {
    /// A second process was requested while one is already active.
    case alreadyRunning
    /// The backend exited unsuccessfully.
    case nonzeroExit(Int32)

    /// A localized explanation suitable for presentation to the user.
    var errorDescription: String? {
        switch self {
        case .alreadyRunning: "Another backend operation is already running."
        case .nonzeroExit(let status): "The backend stopped with exit status \(status)."
        }
    }
}
