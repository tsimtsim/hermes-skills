---
name: webpage-to-markdown
title: "Webpage → clean Markdown (Defuddle) — cheap article extraction"
description: "Extract the MAIN CONTENT of any web page as clean Markdown + YAML metadata (title/author/published/description) using kepano's Defuddle, via the one-shot helper scripts/web2md.sh. Use whenever the user pastes a URL or says 'read/save/summarise this page', 'save article to notes', or when you need page text WITHOUT paying for the raw HTML (typically 5-15x fewer tokens). Decision tree: HTML/news/wiki/blog → web2md.sh; PDF/docx/xlsx → skill ocr-and-documents; anti-bot 403 → Safari UA retry (built in); login wall / pure client-side JS → browser toolset, then pipe the HTML in. Triggers: defuddle, web clip, extract webpage, webpage to markdown, save this URL, summarise this link."
version: 1.0.0
tags: [web, markdown, scraping, notes, obsidian, defuddle, token-saving, research]
related_skills: [obsidian, ocr-and-documents]
---

# Webpage → clean Markdown (Defuddle)

**Why this exists:** a raw news/article page is 100–400 KB of HTML; the actual article is only 5–15 % of
that. Defuddle — kepano's extractor, the engine behind Obsidian Web Clipper — returns the main content
only, plus metadata, so reading a page costs a fraction of the tokens and the result drops straight into
a note. It replaces the ad-hoc "curl the page and paste it into context" habit.

## Bootstrap (once — Hermes can do this itself on first use)

Requirement: **Node.js + npm** (`node -v && npm -v`).

Point the helper at a stable path outside the skill dir so it survives skill updates:

```bash
SKILL_DIR="$(ls -d ~/.hermes/skills/*/webpage-to-markdown 2>/dev/null | head -1)"
mkdir -p ~/.hermes/scripts
cp "$SKILL_DIR/scripts/web2md.sh" ~/.hermes/scripts/web2md.sh
chmod +x ~/.hermes/scripts/web2md.sh
```

If `~/.hermes/scripts/web2md.sh` is missing at the start of a task, just run the block above — it is safe
to re-run and takes under a second.

Defuddle itself is installed automatically on the first real use
(`npm install -g --prefix ~/.local defuddle`, no sudo). A plain global install to
`/usr/lib/node_modules` fails with permission denied — don't use sudo.

## Preflight (once per session, ~0.2 s)

```bash
~/.hermes/scripts/web2md.sh --check
```

Prints `defuddle: <path>`, its version, and whether the notes dir exists. If defuddle is missing it
self-installs user-level on first real use.

## Normal usage — one command does fetch + extract + save

```bash
~/.hermes/scripts/web2md.sh <URL>              # save a note to the notes dir (see below)
~/.hermes/scripts/web2md.sh <URL> -            # print markdown to stdout only (no file)
~/.hermes/scripts/web2md.sh <URL> /path/out.md # explicit destination
cat page.html | ~/.local/bin/defuddle parse - --markdown --frontmatter   # from HTML you already have
```

The helper already does, in order: `defuddle parse` → on failure retry with a Safari User-Agent → on
failure `curl -sSL -A <UA>` and pipe the HTML into stdin → then **guard**: if the text hits an anti-bot
wall (`are you a robot | just a moment | attention required | access denied | captcha | enable
javascript and cookies`) or is under 200 non-space characters it prints `BLOCKED:` / `TOO SHORT` and
**exits 4 without writing a junk note**. Exit 4 means "get the HTML another way", not "site is broken".

## Notes directory

The helper picks a default automatically:

1. `$WEB2MD_NOTES` env var, if set — use this to point at your own folder.
2. `/mnt/e/web2md note` on WSL when an E: drive is mounted.
3. `~/web2md-notes` on Linux / macOS.

Set it explicitly if you prefer: `export WEB2MD_NOTES="$HOME/Documents/web-clips"`.

## Decision tree — pick the right extractor

1. **Normal HTML page** (news, blog, Wikipedia, docs, forum) → `web2md.sh`. ✅
2. **PDF / .docx / .xlsx / scan** → skill `ocr-and-documents` (markitdown / PyMuPDF). Defuddle is HTML-only.
3. **403 / bot wall** → the helper retries UA then curls automatically; if it still exits 4, drive the page
   with the **browser toolset** (real session, JS enabled) → save the rendered HTML → pipe into
   `defuddle parse -`. Login-gated content (paywalls, X/Twitter, Bloomberg) *always* needs this.
4. **Free middle rung — Jina Reader (no API key, no install):**
   ```bash
   curl -s --max-time 60 'https://r.jina.ai/<FULL-URL-WITH-SCHEME>' | head -c 4000
   ```
   Server-side render + markdown, so it beats the fetcher on JS-heavy pages. Rate-limited (~20 req/min),
   one page at a time.
5. **Pure client-side SPA with no SSR** → same as 3. Defuddle parses HTML; it cannot run JS.
6. **You only need one field** (`title`, `description`, `domain`, `author`) → `defuddle parse <URL> --property title`.
7. **Machine-readable metadata** (schema.org, image, favicon, parseTime) → `defuddle parse <URL> --json`.

## How to use it inside a task (the point of the skill)

1. A URL arrives (or "read / save / summarise this") → run `web2md.sh <URL>` **once**; do NOT fetch the
   page again with another tool.
2. Read the saved `.md` (5–15 % of the HTML size) — never read the raw HTML.
3. Answer in chat: conclusion first, 3–8 bullets, quote concrete numbers from the article.
4. If the user wants it kept, confirm the path and send the file back with `MEDIA:<path>`.

## Pitfalls (measured, defuddle 0.19.4)

- 🔴 **`npx defuddle` costs 3–4 s + npm-notice noise on every call.** Use the installed binary
  (`~/.local/bin/defuddle`, ~0.5 s/page) — that is why the helper resolves the binary first.
- 🔴 **Never measure a CJK page with `wc -w`.** Chinese has no spaces, so a 13 KB / 3,200-word article
  reports ~269 words, and a "< 40 words = empty page" guard would wrongly reject a real article. The
  helper counts **non-space characters** and the floor is **200 chars**; it prints `CHARS:` not `WORDS:`.
- 🔴 **Never `cut` a filename that may contain CJK** — `cut -c1-70` slices a multibyte character in half
  and produces an invalid-UTF-8 filename. Truncate with bash `${var:0:40}` (locale-aware).
- 🟡 **Percent-encoded URLs make garbage slugs.** The helper names files from the extracted `<title>`
  (`<host>-<title-40ch>-<date>.md`), falling back to the URL host.
- 🔴 **Anti-bot walls return HTTP 200 with an "are you a robot" body** — the extractor happily returns
  that garbage. Hence the guard; never trust "SAVED" without checking the `CHARS:` line.
- 🟡 **Global npm install without `--prefix ~/.local` fails** with a permissions error. The helper
  handles it; don't switch to sudo.
- 🟡 **JS-heavy sites sometimes DO work** (e.g. TradingView parses because it server-renders) — try
  first, only fall back to the browser when the guard trips.
- 🟡 **Chinese pages work** (zh.wikipedia.org → correct content + metadata); slugs keep CJK characters.
- ⚠️ Defuddle is upstream-marked "work in progress". Pin the version if output shape matters
  (`npm install -g --prefix ~/.local defuddle@0.19.4`).
- ⚠️ `--frontmatter` output is YAML; when re-publishing keep the `source:` line so the note stays traceable.

## Verification (prove it works, ~5 s)

```bash
~/.hermes/scripts/web2md.sh 'https://stephango.com/saw'                # expect SAVED + TITLE + CHARS≈1000
~/.hermes/scripts/web2md.sh 'https://zh.wikipedia.org/wiki/黃金'        # expect CHARS≈10000+, no mojibake
~/.hermes/scripts/web2md.sh 'https://www.bloomberg.com/news/' 2>&1 | tail -2   # expect BLOCKED: (exit 4)
```

## Support files

- `scripts/web2md.sh` — the helper. Copy it to `~/.hermes/scripts/web2md.sh` (keep them in sync when editing).
