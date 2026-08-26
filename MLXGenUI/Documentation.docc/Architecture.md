# Architecture

Keep presentation, portable task values, and process execution independently testable.

## Feature boundaries

SwiftUI views are organized by user-facing feature. ``AppModel`` owns window-level presentation state, while domain types such as ``GenerationTask`` remain value types with no dependency on SwiftUI.

Backend services accept explicit dependencies and return `Sendable` values. Long-lived mutable process state belongs in actors. UI mutation remains on the main actor.

## Source-of-truth policy

`MLXGenUI.xcodeproj` is edited and reviewed directly. Do not add a project generator. Add new source files to the appropriate Xcode target and keep one primary declaration per file.

## Documentation policy

Document public and architectural declarations from the caller's perspective. Update symbol comments and relevant articles alongside behavioral changes. Explain cancellation, isolation, side effects, and filesystem behavior where they affect callers.
