# webpage-to-markdown

A Hermes skill that turns any web page into clean Markdown (5–15x fewer tokens than raw HTML),
using [Defuddle](https://github.com/kepano/defuddle) — the extractor behind Obsidian Web Clipper.

## What's inside

```
webpage-to-markdown/
├── SKILL.md              # the skill
├── SETUP.md              # this file
└── scripts/
    └── web2md.sh         # one-shot helper: fetch + extract + save
```

## Install

**Prerequisite: Node.js + npm** (`node -v && npm -v`). Everything else is automatic.

```bash
hermes skills install <owner>/<repo>/webpage-to-markdown
```

Hermes downloads the whole folder (including `scripts/`), scans it, and installs it under
`~/.hermes/skills/`. Then bootstrap the helper and verify:

```bash
SKILL_DIR="$(ls -d ~/.hermes/skills/*/webpage-to-markdown 2>/dev/null | head -1)"
mkdir -p ~/.hermes/scripts
cp "$SKILL_DIR/scripts/web2md.sh" ~/.hermes/scripts/web2md.sh
chmod +x ~/.hermes/scripts/web2md.sh

~/.hermes/scripts/web2md.sh --check
~/.hermes/scripts/web2md.sh 'https://stephango.com/saw'
```

`--check` auto-installs Defuddle (user-level, no sudo). The second run saves a `.md` note.

Update later with `hermes skills update`.

## Where notes go

Defaults automatically:
- `$WEB2MD_NOTES` if you set it (recommended if you want them somewhere specific)
- `/mnt/e/web2md note` on WSL with an E: drive
- `~/web2md-notes` otherwise

Change it any time:

```bash
export WEB2MD_NOTES="$HOME/Documents/web-clips"
```

## Use it

```bash
~/.hermes/scripts/web2md.sh <URL>          # save a note
~/.hermes/scripts/web2md.sh <URL> -        # just print the markdown (no file)
```

Once the skill is installed, just paste a URL and say "read / save / summarise this".

## Notes

- Defuddle parses **HTML only**. PDFs / Word / Excel → use a document converter (Hermes skill
  `ocr-and-documents`). Login walls / JS-only pages → use the browser toolset and pipe the HTML in.
- Exit code 4 means "anti-bot wall or too little content" — get the HTML another way, the site isn't broken.
