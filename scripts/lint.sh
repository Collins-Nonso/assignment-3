#!/usr/bin/env bash
set -u
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
fail=0
required=(README.md app/app.sh scripts/lint.sh scripts/build.sh tests/test.sh Dockerfile compose.yaml .dockerignore .github/workflows/ci.yml)
for f in "${required[@]}"; do
  if [[ -f "$f" ]]; then echo "PASS: found $f"; else echo "FAIL: missing $f"; fail=1; fi
done
for f in app/*.sh scripts/*.sh tests/*.sh grade.sh; do
  [[ -f "$f" ]] || continue
  if bash -n "$f"; then echo "PASS: bash -n $f"; else echo "FAIL: bash syntax $f"; fail=1; fi
done
for f in app/*.sh scripts/*.sh tests/*.sh grade.sh; do
  [[ -x "$f" ]] && echo "PASS: executable $f" || { echo "FAIL: not executable $f (run chmod +x app/*.sh scripts/*.sh tests/*.sh grade.sh)"; fail=1; }
done
exit "$fail"
