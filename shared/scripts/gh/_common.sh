#!/bin/bash
# _common.sh — shared helpers for the gh tracker scripts.
# Source: source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

[[ -n "${_GH_COMMON_LOADED:-}" ]] && return 0
_GH_COMMON_LOADED=1

GH_REST_TIMEOUT="${GH_REST_TIMEOUT:-30}"
GH_GQL_TIMEOUT="${GH_GQL_TIMEOUT:-45}"

gh_with_timeout() {
  local secs="$1"; shift
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
  elif command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
  else
    perl -e 'my $s=shift; alarm $s; exec @ARGV or die "exec failed: $!\n"' "$secs" "$@"
  fi
}
