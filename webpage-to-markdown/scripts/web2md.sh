#!/usr/bin/env bash
# web2md.sh — Webpage / HTML -> clean Markdown (a thin wrapper around kepano's Defuddle)
# Saves 5-15x tokens vs reading raw HTML. Portable: works on WSL, Linux, macOS.
#
# Usage:
#   web2md.sh <URL|file.html> [out.md]   # save a note (default dir: see NOTE_DIR below)
#   web2md.sh <URL|file.html> -          # print markdown to stdout only, write no file
#   web2md.sh --check                    # verify defuddle is installed
#
# Features: --frontmatter (title/author/date/desc) + automatic 403 retry (Safari UA)
#           + curl fallback + anti-bot / empty-page guard.
set -uo pipefail

# --- Where saved notes go. Override with:  export WEB2MD_NOTES="/your/path" ---
if [ -n "${WEB2MD_NOTES:-}" ]; then
  NOTE_DIR="$WEB2MD_NOTES"
elif [ -d "/mnt/e" ] && [ -w "/mnt/e" ]; then
  NOTE_DIR="/mnt/e/web2md note"          # WSL with an E: drive mounted
else
  NOTE_DIR="$HOME/web2md-notes"          # Linux / macOS default
fi

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

find_df() {
  local c
  for c in "$HOME/.local/bin/defuddle"; do
    [ -x "$c" ] && { printf '%s' "$c"; return 0; }
  done
  c="$(command -v defuddle 2>/dev/null)" && [ -n "$c" ] && { printf '%s' "$c"; return 0; }
  return 1
}

ensure_df() {
  local df; df="$(find_df)" && { printf '%s' "$df"; return 0; }
  echo "[web2md] defuddle not found, installing user-level (no sudo needed)..." >&2
  npm install -g --prefix "$HOME/.local" defuddle >/dev/null 2>&1
  find_df
}

DF="$(ensure_df)" || { echo "[web2md] ERROR: failed to install defuddle -> run: npm install -g --prefix ~/.local defuddle" >&2; exit 3; }

if [ "${1:-}" = "--check" ]; then
  echo "defuddle: $DF"; "$DF" --version 2>&1 | head -1
  echo "notes dir: $NOTE_DIR (exists: $([ -d "$NOTE_DIR" ] && echo yes || echo no))"
  exit 0
fi

SRC="${1:-}"; OUT="${2:-}"
if [ -z "$SRC" ]; then echo "usage: web2md.sh <URL|html-file> [out.md|-]" >&2; exit 2; fi

TMP="$(mktemp)"; ERRLOG="$(mktemp)"
trap 'rm -f "$TMP" "$ERRLOG" "$TMP.html"' EXIT

run() {  # $1... = extra defuddle args
  : > "$TMP"
  if [ -f "$SRC" ]; then
    "$DF" parse - --markdown --frontmatter "$@" < "$SRC" > "$TMP" 2>"$ERRLOG"
  else
    "$DF" parse "$SRC" --markdown --frontmatter "$@" > "$TMP" 2>"$ERRLOG"
  fi
  [ -s "$TMP" ]
}

if ! run; then
  echo "[web2md] attempt 1 failed ($(head -c 120 "$ERRLOG" | tr -d '\n')) -> retry with Safari UA" >&2
  if ! run --user-agent "$UA"; then
    echo "[web2md] UA retry failed -> fetch with curl and pipe into stdin" >&2
    if [ ! -f "$SRC" ]; then
      if curl -sSL --max-time 45 -A "$UA" "$SRC" -o "$TMP.html" 2>>"$ERRLOG" && [ -s "$TMP.html" ]; then
        "$DF" parse - --markdown --frontmatter < "$TMP.html" > "$TMP" 2>>"$ERRLOG"
      fi
    fi
  fi
fi

if [ ! -s "$TMP" ]; then
  echo "[web2md] FAILED: could not extract content (login wall / JS-only page?)." >&2
  echo "[web2md] Fallback: get the HTML with a browser -> cat page.html | \"$DF\" parse - --markdown" >&2
  exit 1
fi

# --- anti-bot / empty-content guard (never save a junk note) ---
# CJK note: `wc -w` is useless for Chinese (no spaces) -> count non-space characters.
chars_now="$(tr -d '[:space:]' < "$TMP" | wc -c | tr -d ' ')"
head_txt="$(head -c 400 "$TMP")"
if printf '%s' "$head_txt" | grep -qiE 'are you a robot|just a moment|attention required|access denied|captcha|verify you are human|enable javascript and cookies'; then
  echo "[web2md] BLOCKED: site returned an anti-bot wall (content = \"$(printf '%s' "$head_txt" | tr -d '\n' | cut -c1-90)\")" >&2
  echo "[web2md] Fallback: use a real browser session -> cat page.html | \"$DF\" parse - --markdown" >&2
  exit 4
fi
if [ "$chars_now" -lt 200 ]; then
  echo "[web2md] TOO SHORT (${chars_now} chars) - probably an empty shell / JS page, not saving." >&2
  echo "[web2md] content preview: $(printf '%s' "$head_txt" | tr -d '\n' | cut -c1-120)" >&2
  exit 4
fi

if [ "$OUT" = "-" ]; then cat "$TMP"; exit 0; fi

if [ -z "$OUT" ]; then
  base="$SRC"
  if [ ! -f "$SRC" ]; then
    base="$(printf '%s' "$SRC" | sed -E 's#^[a-z]+://##; s#[/?&=]+#-#g; s#[^[:alnum:]._-]+#-#g; s#-{2,}#-#g; s#^-|-$##g' | cut -c1-60)"
  else
    base="$(basename "$SRC" | sed -E 's/\.[A-Za-z0-9]+$//')"
  fi
  host="$(printf '%s' "$SRC" | sed -E 's#^[a-z]+://##; s#/.*$##')"
  slug="$(awk '/^title:/{sub(/^title:[ ]*/,""); gsub(/^"|"$/,""); print; exit}' "$TMP" \
          | sed -E 's#[/\\:*?"<>|]+#-#g; s#[[:space:]]+#-#g; s#-{2,}#-#g; s#^-|-$##g' | cut -c1-200)"
  slug="${slug:0:40}"   # truncate with bash, not cut (cut splits multibyte CJK -> invalid filename)
  [ -z "$slug" ] && slug="$base"
  mkdir -p "$NOTE_DIR"
  OUT="$NOTE_DIR/${host}-${slug}-$(date +%Y%m%d-%H%M).md"
fi

mkdir -p "$(dirname "$OUT")"
cp "$TMP" "$OUT"

title="$(awk '/^title:/{sub(/^title:[ ]*/,""); gsub(/"/,""); print; exit}' "$OUT")"
chars="$(tr -d '[:space:]' < "$OUT" | wc -c | tr -d ' ')"
echo "SAVED: $OUT"
echo "TITLE: ${title:-（no title metadata）}"
echo "CHARS: $chars"
