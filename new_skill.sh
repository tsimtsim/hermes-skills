#!/usr/bin/env bash
# Scaffold a new skill folder from _template.
set -euo pipefail
cd "$(dirname "$0")"

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "usage: ./new_skill.sh <skill-name>" >&2
  exit 2
fi
case "$NAME" in
  *[!a-z0-9_-]*|"") echo "invalid name '$NAME' - use lowercase letters, digits, - or _ only" >&2; exit 2;;
esac
if [ -e "$NAME" ]; then
  echo "ERROR: '$NAME' already exists" >&2
  exit 1
fi

mkdir -p "$NAME/scripts"
sed "s/SKILL_NAME/$NAME/g" _template/SKILL.md.tmpl > "$NAME/SKILL.md"
echo "[new_skill] created $NAME/"
echo "  edit   $NAME/SKILL.md"
echo "  add    $NAME/scripts/...   then double-click push_skills.bat"
