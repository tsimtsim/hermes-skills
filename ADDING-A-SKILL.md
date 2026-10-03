# Adding a new skill

## 1. Scaffold

```bash
bash new_skill.sh my-new-skill
```

That creates:

```
my-new-skill/
├── SKILL.md          # fill this in
└── scripts/          # optional helpers
```

## 2. Write SKILL.md

Frontmatter (YAML) - `name` and `description` are mandatory:

```yaml
---
name: my-new-skill
description: "One or two sentences: WHAT it does and WHEN to use it (list trigger words)."
version: 1.0.0
tags: [tag1, tag2]
---
```

Then the body: why it exists, exact commands, a decision tree / numbered steps, pitfalls, verification.

## 3. Checklist before pushing

- [ ] Folder name == `name:` in frontmatter (lowercase, hyphens).
- [ ] `SKILL.md` + `description` present.
- [ ] No secrets, tokens, API keys anywhere.
- [ ] No personal absolute paths baked in (use `$VAR` or a portable default).
- [ ] Helper scripts are executable (`chmod +x`) and self-install their dependencies.
- [ ] Tested locally: the skill actually runs.
- [ ] `_template/` untouched (or updated deliberately).
- [ ] Any `.bat` file is ASCII-only with CRLF line endings.

## 4. Publish

Double-click **`push_skills.bat`**, or from WSL:

```bash
cd /mnt/e/hermes-skills && ./push_skills.sh
```

## Layout

```
hermes-skills/
├── README.md
├── ADDING-A-SKILL.md
├── push_skills.bat      # double-click: commit + push everything
├── push_skills.sh       # the actual logic (called by the .bat)
├── new_skill.sh         # scaffold a new skill folder
├── _template/           # skeleton (not installable)
└── <skill-name>/        # one folder per skill
    ├── SKILL.md
    ├── scripts/
    └── references/
```
