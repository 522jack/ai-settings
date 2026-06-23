#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

im_error() { local msg="$1" code="${2:-unknown}"; printf '{"error":%s,"code":%s}\n' "$(printf '%s' "$msg" | jq -Rs .)" "$(printf '%s' "$code" | jq -Rs .)"; }
im_parse_ref() {
  local ref="$1"; IM_NUMBER=""; IM_REPO=""
  if [[ "$ref" =~ ^https?://github\.com/([^/]+/[^/]+)/issues/([0-9]+) ]]; then IM_REPO="${BASH_REMATCH[1]}"; IM_NUMBER="${BASH_REMATCH[2]}"
  elif [[ "$ref" =~ ^([^#]+)#([0-9]+)$ ]]; then IM_REPO="${BASH_REMATCH[1]}"; IM_NUMBER="${BASH_REMATCH[2]}"
  elif [[ "$ref" =~ ^([0-9]+)$ ]]; then IM_NUMBER="${BASH_REMATCH[1]}"
  else return 1; fi
}

[[ $# -lt 1 ]] && { im_error "Usage: fetch_issue.sh <issue-ref> [-R <owner/repo>]" "usage"; exit 1; }
RAW_REF="$1"; shift; REPO_OVERRIDE=""
while [[ $# -gt 0 ]]; do case "$1" in -R) REPO_OVERRIDE="$2"; shift 2 ;; *) im_error "Unknown flag: $1" "usage"; exit 1 ;; esac; done

im_parse_ref "$RAW_REF" || { im_error "Cannot parse issue ref: $RAW_REF" "invalid_ref"; exit 1; }
[[ -n "$REPO_OVERRIDE" ]] && IM_REPO="$REPO_OVERRIDE"
[[ -z "$IM_REPO" ]] && { out=$(gh_with_timeout "$GH_REST_TIMEOUT" gh repo view --json nameWithOwner -q .nameWithOwner 2>&1) || { im_error "Cannot resolve repo: $out" "repo_resolve_failed"; exit 1; }; IM_REPO="$out"; }
[[ -z "$IM_NUMBER" ]] && { im_error "No issue number in ref: $RAW_REF" "invalid_ref"; exit 1; }

out=$(gh_with_timeout "$GH_REST_TIMEOUT" gh issue view "$IM_NUMBER" -R "$IM_REPO" --json id,number,title,state,body,labels,url 2>&1) || { im_error "$out" "gh_failed"; exit 1; }
printf '%s' "$out" | jq '{number:.number,title:.title,state:.state,body:.body,labels:[.labels[]|{id:.id,name:.name,color:.color}],url:.url,node_id:.id}'
