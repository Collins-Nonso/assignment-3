#!/usr/bin/env bash
set -u

usage() {
  cat <<'USAGE'
Usage:
  app.sh system-info
  app.sh check-host <host>
  app.sh check-port <host> <port>
  app.sh help

Exit codes: 0 success, 1 operational failure, 2 invalid command/input.
USAGE
}
valid_host() { [[ -n "${1:-}" && "$1" != -* && "$1" =~ ^[A-Za-z0-9._:-]+$ ]]; }
valid_port() { [[ "${1:-}" =~ ^[0-9]+$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 )); }

system_info() {
  echo "=== System Information ==="
  printf 'Hostname: %s\n' "$(hostname 2>/dev/null || echo unknown)"
  printf 'User: %s\n' "$(id -un 2>/dev/null || echo unknown)"
  printf 'Date/time: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  if [[ -r /etc/os-release ]]; then . /etc/os-release; printf 'Operating system: %s\n' "${PRETTY_NAME:-Unknown Linux}"; else uname -s; fi
  printf 'Kernel: %s\n' "$(uname -r 2>/dev/null || echo unknown)"
  printf 'Uptime: %s\n' "$(uptime -p 2>/dev/null || uptime 2>/dev/null || echo unknown)"
  echo "CPU:"
  grep -m 1 -E '^(model name|Hardware|Processor)[[:space:]]*:' /proc/cpuinfo 2>/dev/null || echo "CPU details unavailable"
  echo "Memory:"
  if command -v free >/dev/null 2>&1; then free -h; else grep -E '^(MemTotal|MemAvailable):' /proc/meminfo 2>/dev/null || true; fi
  printf 'Working directory: %s\n' "$PWD"
}
check_host() {
  local host="$1" addresses
  if ! valid_host "$host"; then echo "Error: invalid host." >&2; return 2; fi
  addresses="$(getent ahosts "$host" 2>/dev/null | awk '!seen[$1]++ {print $1}' | paste -sd ', ' -)"
  if [[ -z "$addresses" ]]; then echo "Error: could not resolve host '$host'." >&2; return 1; fi
  echo "Host: $host"
  echo "Resolved address(es): $addresses"
  if command -v ping >/dev/null 2>&1; then
    if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then echo "ICMP ping: reachable"; else echo "ICMP ping: no response (may be blocked)"; fi
  else echo "ICMP ping: skipped (ping unavailable)"; fi
}
check_port() {
  local host="$1" port="$2"
  if ! valid_host "$host"; then echo "Error: invalid host." >&2; return 2; fi
  if ! valid_port "$port"; then echo "Error: port must be an integer from 1 to 65535." >&2; return 2; fi
  if ! command -v nc >/dev/null 2>&1; then echo "Error: nc is required for TCP checks." >&2; return 1; fi
  if nc -z -w 3 "$host" "$port" >/dev/null 2>&1; then echo "TCP $host:$port: OPEN"; return 0; fi
  echo "TCP $host:$port: CLOSED or unreachable" >&2
  return 1
}

if [[ $# -lt 1 ]]; then usage >&2; exit 2; fi
cmd="$1"; shift
case "$cmd" in
  system-info)
    [[ $# -eq 0 ]] || { echo "system-info takes no arguments" >&2; exit 2; }
    system_info
    ;;
  check-host)
    [[ $# -eq 1 ]] || { echo "check-host requires exactly one host" >&2; usage >&2; exit 2; }
    check_host "$1"; exit $?
    ;;
  check-port)
    [[ $# -eq 2 ]] || { echo "check-port requires a host and port" >&2; usage >&2; exit 2; }
    check_port "$1" "$2"; exit $?
    ;;
  help|-h|--help)
    [[ $# -eq 0 ]] || { echo "help takes no arguments" >&2; exit 2; }
    usage
    ;;
  *) echo "Error: invalid command '$cmd'." >&2; usage >&2; exit 2 ;;
esac
if true; then
