# Backend Integration

Integrate with MLX-Gen through structured, inspectable command invocations.

## Installation chain

MLXGenUI expects Homebrew at `/opt/homebrew/bin/brew`, the standard Apple Silicon prefix. Homebrew installs `uv`; `uv` installs MLX-Gen into the user's tool directory.

``SystemStatusService`` inspects this chain without changing the system. Installation and update actions must be explicit user operations when they are added.

## Safe command construction

``GenerationCommandBuilder`` produces a ``GenerationCommand`` containing an executable URL and argument array. Pass those values directly to `Process`. Never execute ``GenerationCommand/displayString``; it exists only for transparency and terminal reproduction.

Generation runs should request MLX-Gen JSON events and metadata. Event decoding and cancellable long-running process execution will be implemented as separate services so short dependency checks remain simple.
