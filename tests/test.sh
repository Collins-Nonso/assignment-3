#!/usr/bin/env bash
set -u
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app/app.sh"
fail=0
count=0
pass() { count=$((count+1)); echo "PASS: $*"; }
bad() { count=$((count+1)); fail=1; echo "FAIL: $*"; }
run_expect() {
  local expected="$1" description="$2"; shift 2
  "$APP" "$@" >/tmp/devops-tool-test.out 2>&1
  local rc=$?
  if [[ "$rc" -eq "$expected" ]]; then pass "$description (exit $rc)"; else bad "$description (expected $expected, got $rc)"; cat /tmp/devops-tool-test.out; fi
}
"$APP" help >/tmp/devops-tool-test.out 2>&1
rc=$?
[[ $rc -eq 0 && "$(cat /tmp/devops-tool-test.out)" == *"Usage:"* ]] && pass "help displays usage" || bad "help displays usage"
"$APP" system-info >/tmp/devops-tool-test.out 2>&1
rc=$?
[[ $rc -eq 0 && "$(cat /tmp/devops-tool-test.out)" == *"Hostname:"* ]] && pass "system-info shows hostname" || bad "system-info shows hostname"
run_expect 2 "unknown command" invalid-command
run_expect 2 "missing host" check-host
run_expect 2 "missing port" check-port example.com
run_expect 2 "nonnumeric port" check-port example.com abc
run_expect 2 "port too low" check-port example.com 0
run_expect 2 "port too high" check-port example.com 65536
run_expect 2 "invalid host" check-host "-bad host"
# A loopback TCP listener is not guaranteed to exist; invalid input tests above remain deterministic.
echo "Executed $count tests."
rm -f /tmp/devops-tool-test.out
exit "$fail"
