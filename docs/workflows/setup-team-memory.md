# Team Memory Setup (claude-mem-sync)

> **When to use**: Setting up shared team memory so Claude Code observations (decisions, bug fixes, discoveries) are synced across a team via a shared GitHub repo
> **Prerequisites**: Each developer must have `claude-mem` installed individually first (see README §6)
> **Command**: `/setup-team-memory`

## Overview

Installs and configures `claude-mem-sync` on a developer's machine. The command is idempotent — safe to re-run and will skip steps already completed. Shared infrastructure files (GitHub Actions workflow, `.claude/memories/`) are committed once and shared via the repo; each developer runs the command once locally to wire up their own config and schedule.

---

## How It Works

```
Individual developer
  └── claude-mem (local SQLite DB, captures session observations)
        └── mem-sync export → .claude/memories/contributions/<dev>.json
              └── GitHub Actions (merge-memories.yml) → .claude/memories/merged/<project>/
                    └── mem-sync import ← all other developers pull merged output
```

Raw contributions are `.gitignore`d. Only the merged output is committed.

---

## Running the Command

Inside a Claude Code session:

```
> /setup-team-memory
```

The command runs 13 steps:

| Step | What It Does | Skip Condition |
|------|-------------|----------------|
| 1 | Check prerequisites (Node ≥18, Bun, gh CLI) | — |
| 2 | Detect current installation state | — |
| 3 | Install `claude-mem` | DB + hooks + worker already present |
| 4 | Configure claude-mem for this workspace | `~/.claude-mem/settings.json` already set |
| 5 | Install `claude-mem-sync` plugin + build CLI | `mem-sync --version` succeeds |
| 6 | Create `.claude/memories/` folder structure | Merged folder already exists |
| 7 | Add GitHub Actions `merge-memories.yml` | Workflow file already exists |
| 8 | Update `.gitignore` | Entry already present |
| 9 | Write `~/.claude-mem-sync/config.json` | Config already exists |
| 10 | Install cron/launchd schedule | Schedule already registered |
| 11 | End-to-end verification (all components) | — |
| 12 | Print final pass/fail report | — |
| 13 | Print next steps if READY | — |

---

## After Setup — What Each Developer Does

**First week — accumulate observations** (automatic, no action needed):
- claude-mem captures decisions, bug fixes, and discoveries as you work

**After first week — share with the team**:
```bash
mem-sync preview --project <project-name>   # see what will be exported
mem-sync export --project <project-name>    # push your observations to the repo
```

**Pull teammate observations**:
```bash
mem-sync import --project <project-name>
```

**Automated weekly schedule** (installed by the command):
- Export: Fridays 4pm
- Import: Saturdays 9am

**Monthly distillation** (optional — promotes patterns to `.claude/rules/`):
```bash
mem-sync distill --project <project-name>
```

---

## Files Created in the Repo

```
.claude/memories/
  merged/<project>/.gitkeep      # committed — merged team observations land here
  contributions/                 # gitignored — each developer's raw export

.github/workflows/
  merge-memories.yml             # auto-merges contributions on push to develop
```

`.gitignore` additions:
```
# claude-mem-sync: raw contributions ignored, merged output committed
.claude/memories/contributions/
!.claude/memories/merged/
```

---

## Troubleshooting

**`mem-sync --version` fails after install**
```bash
cd ~/.claude/plugins/marketplaces/claude-mem-sync
bun install && bun run build && npm link
```

**Worker not running**
```bash
npx claude-mem start
curl http://localhost:37777/health
```

**Hooks not registered (0 count)**
```bash
npx claude-mem install
grep "claude-mem" ~/.claude/settings.json
```

**Export preview shows nothing**
Normal on first install — claude-mem needs at least one session of activity to capture observations.
