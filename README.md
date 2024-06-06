# Purpose

Build and publish the app from Phase 1 in a containerized way.

# Requirements

Nothing beyond the standard Go toolchain and standard library, access to the `phase1` binary from a Phase 1 release, and access to publish to GitHub Container Registry.

# Instructions

When the [jkaplowitz/mondoo-phase1](https://github.com/jkaplowitz/mondoo-phase1) repository publishes a release, it will first build and publish a binary release asset via GitHub Actions and then trigger this repository to build and publish a Docker image. This image will be available to Docker (and Kubernetes) as `ghcr.io/jkaplowitz/mondoo-phase2:main`, configured to listen within the container on port 8080 unless overridden by a PORT environment variable setting, and with port 8080 configured in the Dockerfilie as an exposed port.

# Kubernetes Deployment

`kubectl apply -f kube.yml` will deploy a `Deployment` and a `Service` to your Kubernetes cluster. Appropriate ingresses and resource limits are context-dependent, so those elements would be future work based on real fact patterns rather than an interview challenge.