# MLXGenUI

MLXGenUI is an open-source, native macOS interface for [MLX-Gen](https://github.com/lpalbou/mlx-gen). It is designed to make local Wan video generation approachable while keeping every task reproducible from the command line.

The project is in active development. The current foundation provides:

- Homebrew, `uv`, and MLX-Gen installation detection.
- Wan text-to-video and image-to-video task editing.
- Built-in presets with documented, reproducible defaults.
- Validation and a copyable `mlxgen` command preview.
- Confirmed installation and update actions using Homebrew and `uv` directly.
- A curated Wan model catalog with explicit downloads.
- Installed-model detection and remote revision checks with Download or Update actions only when needed.
- Cancellable generation with structured MLX-Gen progress and bounded diagnostics.
- Portable `.mlxgentask` documents and a persistent saved-task library.
- User-selected MP4 output destinations and generated-video history with AVKit playback.
- Workflow-aware model selection using the curated Wan catalog and local installation state.

## Requirements

- An Apple Silicon Mac.
- macOS 15 or later.
- Xcode 26 or later.
- [Homebrew](https://brew.sh).
- Git.

MLX-Gen is installed as a `uv` tool. Homebrew manages `uv`, and `uv` manages MLX-Gen:

```sh
brew install uv
uv tool install --upgrade mlx-gen
```

The app detects these components and will provide guided setup as installation support is completed.

## Build from source

1. Clone this repository.
2. Open `MLXGenUI.xcodeproj` in Xcode.
3. Select the **MLXGenUI** scheme and **My Mac**.
4. If Xcode requests a development team, choose your personal team under Signing & Capabilities.
5. Press Command-R.

The checked-in Xcode project is the source of truth. No project generator, package manager, or third-party Swift dependency is required.

You can also build from Terminal:

```sh
xcodebuild -project MLXGenUI.xcodeproj -scheme MLXGenUI -destination 'platform=macOS' build
```

Run unit tests with:

```sh
xcodebuild -project MLXGenUI.xcodeproj -scheme MLXGenUI -destination 'platform=macOS' test
```

## Documentation

Developer documentation is written using DocC. In Xcode, choose **Product > Build Documentation**. The catalog covers architecture, backend integration, and the conventions contributors must preserve.

Documentation is part of the definition of done. Changes to behavior or APIs must update their symbol comments and any affected DocC articles in the same pull request.

## Privacy

Generation runs locally. The app does not upload prompts or media. MLX-Gen model downloads are retrieved from their upstream hosting providers when explicitly requested by the user.

## Contributing

Contributions are welcome. Please keep changes focused, add Swift Testing coverage for domain logic, and build both the app and DocC documentation before opening a pull request. Public and architectural APIs must have current DocC comments.

## License

A project license will be selected before the first public release. Until then, the source is provided for development and evaluation only.
