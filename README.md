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
- Exact-duration video requests with automatic Wan continuation segments.
- Multi-frame motion handovers, native AVFoundation assembly, and overlap-aware trimming.
- Persistent run manifests and idle-sleep prevention for long unattended generations.

## Longer videos

Enter the desired finished duration on the Create Video screen. When the request exceeds the selected Wan model's recommended shot length, MLXGenUI automatically generates the required segments sequentially, extracts an ordered handover window, and joins the results into one MP4. Text-to-video jobs using Wan A14B require the paired A14B image-to-video model for continuation; the Ready Check identifies that requirement before generation starts.

Intermediate files and a machine-readable run manifest are retained under `/tmp/MLXGenUI/LongVideoRuns` if a generation is cancelled or interrupted. The final output is moved to the selected destination only after assembly succeeds. macOS may clear these temporary workspaces automatically.

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


You can also build from Terminal:

```sh
xcodebuild -project MLXGenUI.xcodeproj -scheme MLXGenUI -destination 'platform=macOS' build
```

Run unit tests with:

```sh
xcodebuild -project MLXGenUI.xcodeproj -scheme MLXGenUI -destination 'platform=macOS' test
```


## Privacy

Generation runs locally. The app does not upload prompts or media. MLX-Gen model downloads are retrieved from their upstream hosting providers when explicitly requested by the user.

## Contributing

Contributions are welcome. Please keep changes focused, add Swift Testing coverage for domain logic, and build both the app and DocC documentation before opening a pull request. Public and architectural APIs must have current DocC comments.
