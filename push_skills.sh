#!/usr/bin/env bash
# Commit every change in this repo and push to GitHub.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

echo "== repo: $(pwd) =="
git add -A

if git diff --cached --quiet; then
  echo "[push_skills] Nothing to push - working tree is clean."
  echo
  git status -sb
  exit 0
fi

echo "== staged changes =="
git diff --cached --name-status

MSG="update skills $(date +%Y-%m-%d_%H%M)"
if ! git commit -m "$MSG"; then
  echo "[push_skills] ERROR: commit failed." >&2
  exit 1
fi

if ! git push; then
  echo "[push_skills] ERROR: push failed (auth? network? remote ahead?)." >&2
  echo "[push_skills] Fix, then re-run. Nothing is lost - the commit is local." >&2
  exit 1
fi

echo
echo "[push_skills] DONE - pushed to GitHub."
git log --oneline -1
git status -sb
