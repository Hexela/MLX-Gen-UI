# Model Management

Inspect installed Wan packages and offer only relevant download actions.

## Cache detection

``HuggingFaceModelService`` honors `HF_HUB_CACHE` and `HF_HOME`, then falls back to `~/.cache/huggingface/hub`. A model counts as downloaded only when its repository contains a cached snapshot. When `refs/main` exists, its commit must have a matching snapshot directory.

This follows Hugging Face's documented cache structure instead of estimating installation from directory names alone.

## Update checks

For a complete local snapshot, ``HubModelRevisionProvider`` requests lightweight model metadata from the Hugging Face Hub and compares its `sha` with the cached `refs/main` commit.

- Matching commits produce ``ModelInstallationStatus/current(revision:)`` and no action button.
- Different commits produce ``ModelInstallationStatus/updateAvailable(localRevision:remoteRevision:)`` and an **Update Model** action.
- Offline or failed metadata checks produce ``ModelInstallationStatus/installed(localRevision:)`` and no destructive or redundant action.
- Missing snapshots produce ``ModelInstallationStatus/notInstalled`` and a **Download Model** action.

Downloads and updates use the same MLX-Gen command because the Hugging Face cache reuses unchanged blobs.
