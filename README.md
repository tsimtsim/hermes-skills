# hermes-skills

My personal collection of [Hermes Agent](https://hermes-agent.nousresearch.com/docs) skills, shared as-is.
**One folder per skill.**

## Install a skill

```bash
hermes skills install tsimtsim/hermes-skills/<skill-name>
```

Hermes downloads the whole skill folder (`SKILL.md` + `scripts/` + `references/` + ...), runs a security
scan, and installs it under `~/.hermes/skills/`. Update later with `hermes skills update`.

Preview without installing:

```bash
hermes skills inspect tsimtsim/hermes-skills/<skill-name>
```

## Skills

| Skill | What it does |
| --- | --- |
| [webpage-to-markdown](webpage-to-markdown/) | Any web page to clean Markdown (5-15x fewer tokens than raw HTML). Wraps kepano's Defuddle. Needs Node.js. |

## Add a new skill

```bash
bash new_skill.sh <skill-name>
```

1. Write `SKILL.md` (frontmatter needs at least `name:` and `description:`).
2. Put helper scripts in `scripts/`, notes in `references/`.
3. Test it locally under `~/.hermes/skills/` first.
4. Double-click **`push_skills.bat`** to publish.

Full checklist: [ADDING-A-SKILL.md](ADDING-A-SKILL.md).

## Rules

- Skills here are **generic and reusable**. Never commit secrets, tokens, API keys, or machine-specific
  absolute paths (use env vars or a sensible default instead).
- `.bat` helpers stay **ASCII-only + CRLF**; shell scripts stay LF.
- Each skill folder must contain a `SKILL.md` or Hermes will not see it.
- `_template/` is a skeleton, not a skill (`SKILL.md.tmpl` keeps it out of search results).
