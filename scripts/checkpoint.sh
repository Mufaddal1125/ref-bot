#!/usr/bin/env bash
# Jump to a phase tag, keeping your own work safe in a stash.
#
#   scripts/checkpoint.sh phase-2-start
#
# Recover what you had with:  git stash list  /  git stash pop

set -euo pipefail
cd "$(dirname "$0")/.."

tag="${1:-}"
if [ -z "$tag" ]; then
  echo "Usage: scripts/checkpoint.sh <tag>"
  git tag --list "phase-*"
  exit 1
fi

if ! git rev-parse --verify "refs/tags/$tag" >/dev/null 2>&1; then
  echo "No such tag: $tag"
  echo "Available:"
  git tag --list "phase-*"
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  git stash push --include-untracked -m "before $tag ($(date '+%Y-%m-%d %H:%M'))"
  echo "Your work is stashed. Restore it later with: git stash pop"
fi

git checkout "$tag"
echo
echo "Now at $tag. What this phase asks you to write:"
git diff "$tag..${tag%-start}-complete" --stat
