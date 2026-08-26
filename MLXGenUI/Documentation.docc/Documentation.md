# ``MLXGenUI``

Create reproducible Wan videos through a native macOS interface to MLX-Gen.

## Overview

MLXGenUI separates user-facing generation tasks from command-line execution. Domain values remain portable and testable, while services locate and invoke Homebrew, `uv`, and MLX-Gen without passing user input through a shell.

The Xcode project is the source of truth and the app has no third-party Swift dependencies.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:BackendIntegration>
- <doc:TaskDocumentsAndHistory>
- <doc:ModelManagement>

### Generation

- ``GenerationTask``
- ``GenerationPreset``
- ``GenerationTaskValidator``
- ``GenerationCommandBuilder``
- ``BackendProcessRunner``
- ``MLXGenEvent``
- ``MLXGenEventDecoder``

### Models and maintenance

- ``WanModel``
- ``BackendAction``
- ``BackendActionCommandBuilder``
- ``HuggingFaceModelService``
- ``ModelInstallationStatus``

### Documents and history

- ``GenerationTaskDocument``
- ``LibraryStore``
- ``SavedTaskRecord``
- ``GeneratedVideoRecord``

### System readiness

- ``SystemStatus``
- ``SystemStatusService``
- ``ProcessCommandRunner``
