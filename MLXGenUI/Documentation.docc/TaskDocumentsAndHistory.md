# Task Documents and History

Preserve generation inputs and completed local artifacts without hiding their locations.

## Portable task documents

``GenerationTaskDocument`` stores a versioned ``GenerationTask`` as readable JSON with the `.mlxgentask` extension. Exported tasks can be shared, inspected, imported, and loaded back into the editor. The app also retains explicitly saved tasks in its Application Support library through ``LibraryStore``.

Task documents store source and output URLs as references to locations on the current Mac. When a document moves between Macs, the user may need to choose those files again.

## Output destinations

The editor uses the native macOS save panel to choose an MP4 destination. If no destination is selected, the app creates a stable task-derived filename in the user's Movies directory.

## Generated-video history

After MLX-Gen reports successful completion, ``GeneratedVideoRecord`` retains the task, output URL, and completion date. Failed and cancelled operations are not added. The Generated Videos feature uses AVKit for local playback and shows the prompt and artifact path needed to understand the result.
