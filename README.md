### Purpose

Build and publish the app from Phase 1 in a containerized way.

### Requirements

Nothing beyond the standard Go toolchain and standard library, access to the `phase1` binary from a Phase 1 release, and access to publish to GitHub Container Registry.

### Instructions

Build the Docker image as usual with `docker build .`, but the `phase` binary must first be in the root of this repository.