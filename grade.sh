#!/usr/bin/env bash
set -u
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
fail=0
pass() { echo "PASS: $*"; }
bad() { echo "FAIL: $*"; fail=1; }
for f in README.md app/app.sh scripts/lint.sh scripts/build.sh tests/test.sh .github/workflows/ci.yml Dockerfile compose.yaml .dockerignore grade.sh; do
  [[ -f "$f" ]] && pass "required file: $f" || bad "missing file: $f"
done
./scripts/lint.sh || bad "linting failed"
grep -Eq '^[[:space:]]*on:' .github/workflows/ci.yml && pass "workflow trigger section exists" || bad "workflow on trigger missing"
grep -q 'push:' .github/workflows/ci.yml && pass "push trigger" || bad "push trigger missing"
grep -q 'pull_request:' .github/workflows/ci.yml && pass "pull_request trigger" || bad "pull_request trigger missing"
grep -q 'needs: validate' .github/workflows/ci.yml && pass "test depends on validate" || bad "test job dependency missing"
grep -q 'needs: test' .github/workflows/ci.yml && pass "docker depends on test" || bad "docker job dependency missing"
./tests/test.sh || bad "application tests failed"
if docker info >/dev/null 2>&1; then
  ./scripts/build.sh || bad "Docker build/smoke tests failed"
  docker compose config -q && pass "Compose configuration" || bad "Compose configuration invalid"
else
  echo "ERROR: Docker is not running; start Docker Desktop and rerun grade.sh." >&2
  fail=1
fi
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commits="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
  [[ "$commits" -ge 5 ]] && pass "at least five commits ($commits)" || echo "WARN: make at least five meaningful Git commits"
else
  echo "WARN: Git history checks skipped because this is not a Git repository yet"
fi
exit "$fail"
