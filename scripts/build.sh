#!/usr/bin/env bash
set -u
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
IMAGE="${IMAGE_NAME:-devops-tool}"
if ! docker info >/dev/null 2>&1; then echo "ERROR: Docker daemon is unavailable." >&2; exit 1; fi
docker build -t "$IMAGE" .
docker run --rm "$IMAGE" help >/dev/null || { echo "FAIL: Docker help smoke test"; exit 1; }
docker run --rm "$IMAGE" system-info >/dev/null || { echo "FAIL: Docker system-info smoke test"; exit 1; }
docker run --rm "$IMAGE" invalid-command >/dev/null 2>&1
rc=$?
if [[ $rc -ne 2 ]]; then echo "FAIL: invalid command should exit 2 (got $rc)"; exit 1; fi
echo "Docker build and smoke tests passed."
