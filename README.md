# Claude Code — Team Onboarding Kit

**Get your team from zero to productive with Claude Code in under 30 minutes.**

This repository is a pre-configured basic starter kit with agents, skills, slash commands, and MCP integrations for tech stack: **Java v21**, **Spring Boot Reactive Web(Web Flux) v3.5x**, **Node.sj v24.13**, **TypeScript 5.x**, **Angular 21.x**, **Python v3.14**, **Flutter v3.38**, **Dartv3.11**, **PostgreSQL**, and **Firebase**.

Clone it, install Claude Code, and start building.

## Table of Contents

- [1. Prerequisites](#1-prerequisites)
- [2. Install VS Code](#2-install-vs-code)
- [3. Install Claude Code](#3-install-claude-code)
- [4. Clone This Repo & Launch](#4-clone-this-repo--launch)
- [5. Install Claude-Mem (Persistent Memory)](#5-install-claude-mem-persistent-memory)
- [6. Understanding Claude Code Components](#6-understanding-claude-code-components)
- [7. What's in This Repo](#7-whats-in-this-repo)
- [8. Hands-On Exercises](#8-hands-on-exercises)
- [9. Tips & Best Practices](#9-tips--best-practices)
- [10. Troubleshooting](#10-troubleshooting)
- [11. Resources](#11-resources)


## What is Claude Code?

**[Claude Code](https://code.claude.com/docs/en/overview)** is an **agentic AI coding assistant that lives in your terminal**. It understands your codebase, edits files directly, runs commands, and helps you code faster through natural language conversation.

Think of it as a senior developer sitting in your terminal who knows your entire project, follows your team's conventions, and never gets tired.


## 1. Prerequisites

Before you begin, make sure you have:
- **A Claude subscription** — Claude Pro or Max at [claude.ai](https://claude.ai), OR an Anthropic API key from the [Console](https://console.anthropic.com)

**Optional for Quick Start: But Required for MCP server**
- **[Node.js v24.13](https://nodejs.org/en/download)**
- **[Python v3.14](https://www.python.org/downloads/)**


## 2. Clone This Repo

```bash
# Clone the onboarding kit
git clone https://github.com/kumaran-is/claude-code-onboarding.git
cd claude-code-onboarding

```

## 3. Install VS Code

We use **[Visual Studio Code](https://code.visualstudio.com/)** as IDE. Download and install **[Visual Studio Code](https://code.visualstudio.com/)** from the official site:

After installing, open the cloned project `claude-code-onboarding` with VS Code and go the **integrated terminal** 

## 4. Install Claude Code

Open the VS Code terminal and run the following:

### Native Binary (Recommended)

1. For macOS / Linux

```bash
]curl -fsSL https://claude.ai/install.sh | bash
``
2. Reload your shell

```bash
source ~/.bashrc   # or: source ~/.zshrc
```
3. Verify installation

```bash
claude --version
```

### 5. First-time Using Claude Code

**Note:** First time Claude Code user should login using our **Claude Pro/Max subscription**.

From vscode terminal run below command to launch Claude Code CLI

```bash
claude
```

First time Claude Code user will be prompted to login. You'll authenticate with your **Claude Pro/Max subscription** or **Anthropic Console API key**.

🔗 **Official Docs:** [https://code.claude.com/docs/en/quickstart](https://code.claude.com/docs/en/quickstart)

That's it! Claude Code will automatically detect and load:
- `CLAUDE.md` — project context and conventions
- `.mcp.json` — MCP server configurations
- `.claude/agents/` — specialized AI agents
- `.claude/skills/` — domain knowledge and templates
- `.claude/commands/` — slash commands

Try these right away:

```
> /project-status
> What agents and skills are available in this project?
> Explain the tech stack from CLAUDE.md
```

## 5. Install Claude-Mem (Persistent Memory)

Claude Code forgets everything between sessions. **[Claude-Mem](https://github.com/thedotmack/claude-me)** gives Claude persistent memory across sessions. 

### Install

Inside a Claude Code CLI session, run:

```
> /plugin marketplace add thedotmack/claude-mem
> /plugin install claude-mem
```

Then **restart Claude Code** (`/exit`) or restart(close and reopen) the vscode.

### What It Does

- **Automatically captures** what Claude does (file edits, decisions, tool usage)
- **Compresses** sessions into searchable memory using AI
- **Injects relevant context** at the start of new sessions
- **Web viewer** at `http://localhost:37777` to browse memory

### Verify

```
> Do you have any memory from previous sessions?
```

## 6. Understanding Claude Code Components

Here's a quick reference for every building block. Knowing *when to use what* is the key to being productive.


### Quick Overview

| # | Component | What It Does | Location | Invoked By |
|---|-----------|-------------|----------|------------|
| 1 | **CLAUDE.md** | Markdown files Claude reads at startup for project context — tech stack, coding standards, commands, architecture, workflows | `./CLAUDE.md` (project), `~/.claude/CLAUDE.md` (global), `.claude/rules/` (conditional) | Auto-loaded at startup |
| 2 | **settings.json** | JSON configuration for permissions, hooks, and environment — allow/deny/ask permission rules, hooks config, env vars | `.claude/settings.json` (project), `~/.claude/settings.json` (user) | Auto-loaded at startup |
| 3 | **Skills** | Modular expertise Claude uses **automatically** based on context — lazy-loaded when needed, not user-invoked. Best for complex, recurring workflows (code review, API design patterns) | `.claude/skills/<skill-name>/SKILL.md` | Claude decides (auto) |
| 4 | **Slash Commands** | `/command` shortcuts for repeatable prompts — quick actions you trigger manually | `.claude/commands/<command-name>.md` | You type `/command` |
| 5 | **Sub-agents** | Specialized AI with isolated context for complex tasks — parallel processing, focused expertise, preserves main context | `.claude/agents/<agent-name>.md` | You type `@agent` |
| 6 | **Hooks** | Scripts that run at lifecycle events (pre/post tool use, session start/stop) — auto-formatting, validation, notifications | Defined in `settings.json` → `"hooks"` | Automatic on events |
| 7 | **MCP Servers** | Tool connections to external services — GitHub, Slack, databases, live docs, APIs | `.mcp.json` (project root) | Claude uses as needed |

### The Golden Formula

```
┌──────────────────────────────────────────────────────────────┐
│  CLAUDE.md          → What Claude knows about your project   │
│  settings.json      → What Claude can / can't do             │
│  Skills             → How Claude handles recurring tasks     │
│  Commands           → Quick actions you trigger manually     │
│  Sub-agents         → Specialists for complex work           │
│  Hooks              → Automatic formatting / validation      │
│  MCP Servers        → External tool connections              │
└──────────────────────────────────────────────────────────────┘
```

### When to Use What — Decision Matrix

| You Need To... | Use | Example |
|-----------------|-----|---------|
| Set project conventions & context | `CLAUDE.md` | Tech stack, coding standards, git workflow |
| Control what Claude can do | `settings.json` | Allow `git` commands, deny `sudo` |
| Auto-apply patterns for a domain | Skill | Always use Riverpod when building Flutter |
| Run a repeatable prompt yourself | Slash Command | `/scaffold-spring-api weather-service` |
| Get deep domain expertise in isolation | Sub-agent | `@database-designer Design schema for...` |
| Enforce hard rules every time | Hook | Block commits without passing tests |
| Connect to external services | MCP Server | GitHub PRs, Context7 live docs, Firebase |
| Remember things across sessions | Claude-Mem plugin | Persistent memory of past decisions |

### MCP Servers in This Repo

| Server | What It Does |
|--------|-------------|
| **Context7** | Live, up-to-date documentation for any library — add `use context7` to prompts |
| **GitHub** | Create issues, PRs, browse repos, review code |
| **Filesystem** | Advanced file search and manipulation |
| **Firebase** | Firestore and Auth operations |


### CLAUDE.md — Project Memory

**What:** A Markdown file at the project root that gives Claude persistent context about your project — tech stack, conventions, common commands, and rules.

**When to use:** Every project should have one. It's the first thing Claude reads.

**Where:** `./CLAUDE.md` (project root) or `~/.claude/CLAUDE.md` (global, all projects)

You can create CLAUDE.md by running the command `/init` inside Claude Code session. Since we already have one we don't need it. 
```bash
# Auto-generate one from your codebase
claude
> /init
```

#### CLAUDE.md Tips

- Keep it under 20KB — too much will overload the LLM Context Window. 200K is Max token capacity for Anthropic LLM.
- Put the most important rules at the top
- Use imports for large docs: `@docs/api-reference.md`


### Slash Commands — Quick-Fire Actions

**What:** Saved prompts you trigger with `/command-name`. Think of them as reusable prompt shortcuts.

**When to use:** When you have a repeatable workflow you run often — scaffolding, reviewing, deploying.

**Where:** `.claude/commands/my-command.md` (project) or `~/.claude/commands/` (global)

```
> /scaffold-spring-api weather-service
> /scaffold-flutter-app fitness-tracker
> /design-database fitness tracking with users, workouts, and goals
```

Use `$ARGUMENTS` in the command file to accept parameters.


### Agents (Subagents) — Specialist AI Personas

**What:** Specialized Claude instances with their own system prompt and tool restrictions. They run in a **separate context window**, so they don't pollute your main conversation.

**When to use:** When you need deep expertise in a specific domain — a dedicated backend developer, database architect, or codereviewer.

**Where:** `.claude/agents/my-agent.md` (project) or `~/.claude/agents/` (global)

```
> @java-spring-api Create a CRUD API for a Product entity with name, price, and category
> @flutter-mobile Build a login screen with Firebase Auth
> @database-designer Design the schema for an e-commerce platform
> @architect Design the system architecture for a real-time chat feature
```

### Skills — Auto-Activated Knowledge

**What:** Markdown files with domain knowledge, templates, and code patterns. Unlike commands, **Claude decides when to use them** based on the task context — you don't invoke them explicitly.

**When to use:** When you want Claude to *automatically* apply certain patterns whenever a matching task comes up (e.g., always use your team's DTO pattern when creating Spring entities).

**Where:** `.claude/skills/my-skill/SKILL.md`

The skills in this repo auto-activate when:
- You ask about Spring Boot → `java-spring-api` skill activates
- You build Angular components → `angular-spa` skill activates
- You create Flutter screens → `flutter-mobile` skill activates
- You design schemas → `database-design` skill activates
- You design architecture → `architecture-design` skill activates


### MCP Servers — External Tool Integrations

**What:** The Model Context Protocol connects Claude Code to external services (GitHub, databases, documentation servers) so Claude can use them as tools.

**When to use:** When Claude needs to interact with services beyond the local filesystem — creating GitHub PRs, querying live databases, fetching up-to-date documentation.

**Where:** `.mcp.json` (project root)

This repo comes with:
- **Context7** — live, up-to-date documentation for any library
- **GitHub** — create issues, PRs, browse repos
- **Filesystem** — advanced file search and manipulation
- **Firebase** — Firestore and Auth operations


### Hooks — Automated Guardrails

**What:** Shell scripts that run automatically at specific lifecycle events (before/after tool use, on session start/end). They're **deterministic** — they always run the same way.

**When to use:** When you need hard rules enforced every time, like "run linter before commit" or "block commits without passing tests."

| Hook Type | Fires When | Common Uses |
|-----------|-----------|-------------|
| `PreToolUse` | Before a tool executes | Validation, tmux reminders for long commands, block risky operations |
| `PostToolUse` | After a tool finishes | Auto-format with Prettier/ruff, type-check, warn about `console.log` |
| `UserPromptSubmit` | When you send a message | Input validation, context injection |
| `Stop` | When Claude finishes responding | Audit modified files, run linter on changes |
| `PreCompact` | Before context compaction | Save important state before context is compressed |
| `Notification` | On permission requests | Custom notification routing |

**Where:** `.claude/settings.json` → `hooks` section

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit && .ts/.tsx",
      "hooks": [{
        "type": "command",
        "command": "npx prettier --write $FILEPATH && npx tsc --noEmit"
      }]
    }],
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "git diff --name-only | xargs grep -l 'console.log' && echo '[Hook] console.log detected in changes' >&2"
      }]
    }]
  }
}
```

### Keyboard Shortcuts (Inside Claude Code)

| Shortcut | Action |
|----------|--------|
| `/help` | Show all available commands |
| `/clear` | Clear conversation context |
| `/compact` | Manually trigger context compaction |
| `/rewind` | Go back to a previous state |
| `/checkpoints` | File-level undo points |
| `/statusline` | Customize status bar (branch, context %, model, todos) |
| `/exit` | Exit Claude Code |
| `/memory` | Open CLAUDE.md in your editor |
| `/agents` | List / create agents |
| `/mcp` | Check MCP server status |
| `!` | Quick bash command prefix |
| `@` | Search for files |
| `Tab` | Toggle thinking display |
| `Shift+Enter` | Multi-line input |
| `Ctrl+U` | Delete entire line (faster than backspace) |
| `Esc` | Cancel current generation |
| `Esc Esc` | Interrupt Claude / restore code |



## 7. What's in This Repo

```
claude-code-onboarding/
├── CLAUDE.md                           # Project memory — tech stack, conventions, rules
├── .mcp.json                           # MCP servers: Context7, GitHub, Filesystem, Firebase
├── .gitignore
├── README.md                           # ← You are here
│
└── .claude/
    ├── settings.json                   # Permissions and hook configs
    │
    ├── agents/                         # Specialist AI personas
    │   ├── java-spring-api.md          # Spring Boot WebFlux expert
    │   ├── nodejs-typescript.md        # Node.js 24 / TypeScript 5.x expert
    │   ├── python-dev.md              # Python 3.14 / FastAPI expert
    │   ├── angular-spa.md              # Angular frontend expert
    │   ├── flutter-mobile.md           # Flutter mobile expert
    │   ├── database-designer.md        # PostgreSQL + Firestore architect
    │   └── architect.md                # Solution architect
    │
    ├── commands/                        # Slash commands (triggered with /name)
    │   ├── scaffold-spring-api.md      # /scaffold-spring-api <name>
    │   ├── scaffold-node-api.md        # /scaffold-node-api <name>
    │   ├── scaffold-python-api.md      # /scaffold-python-api <name>
    │   ├── scaffold-angular-app.md     # /scaffold-angular-app <name>
    │   ├── scaffold-flutter-app.md     # /scaffold-flutter-app fitness tracker
    │   ├── design-database.md          # /design-database <domain description>
    │   ├── design-architecture.md      # /design-architecture <system description>
    │   ├── add-feature.md              # /add-feature <feature description>
    │   └── project-status.md           # /project-status
    │
    └── skills/                          # Auto-activated domain knowledge
        ├── java-spring-api/SKILL.md    # Spring Boot patterns & templates
        ├── nodejs-typescript/SKILL.md  # Node.js / TypeScript patterns & templates
        ├── python-dev/SKILL.md         # Python / FastAPI patterns & templates
        ├── angular-spa/SKILL.md        # Angular patterns & templates
        ├── flutter-mobile/SKILL.md     # Flutter patterns & templates
        ├── database-design/SKILL.md    # Schema design patterns
        └── architecture-design/SKILL.md # Architecture patterns & templates
```

## 8. Hands-On Exercises

Work through these exercises to get familiar with Claude Code. Each one uses different components from this kit.

### Exercise 1: Scaffold a Flutter Fitness App

```
> /scaffold-flutter-app fitness tracker
```

Then iterate:

```
> Add a workout logging feature with Firestore integration
> Create the database schema for tracking workouts, exercises, and user stats
> Add a dashboard screen showing weekly workout summary with charts
```

### Exercise 2: Build a Weather REST API (Java)

```
> /scaffold-spring-api weather-service
> @java-spring-api Add a WeatherController that accepts a city name and returns mock weather data with temperature, humidity, and condition
> Add integration tests for the weather endpoint
```

### Exercise 3: Build a Todo API (Node.js/TypeScript)

```
> /scaffold-node-api todo-service
> @nodejs-typescript Add a Todo model with Zod, a CRUD router, and an in-memory store
> Add Vitest tests for create and list endpoints
> Add a PUT endpoint to mark todos as complete
```

### Exercise 4: Build an Analytics API (Python)

```
> /scaffold-python-api analytics-service
> @python-dev Add an async endpoint that accepts event data and stores it with timestamps
> Create a Pydantic model for events with type, payload, and metadata
> Add pytest tests for the event endpoints
```

### Exercise 5: Design a Full-Stack E-Commerce System

```
> /design-architecture An e-commerce platform with product catalog, shopping cart, checkout, and order tracking. Angular SPA for web, Flutter for mobile, Spring Boot backend.
> /design-database e-commerce platform with products, categories, users, orders, order items, payments, and shipping
> /scaffold-spring-api ecommerce-api
> @java-spring-api Create CRUD endpoints for Products with name, description, price, category, and image URL
```

### Exercise 6: Use Context7 for Latest Docs

```
> Create a Spring Boot WebFlux endpoint that uses Spring Security with JWT. use context7
> Build an Angular component using the new Angular signals API. use context7
> Set up Firebase App Check in Flutter. use context7
> Create a FastAPI endpoint with async SQLAlchemy. use context7
> Build an Express middleware with Zod request validation. use context7
```

### Exercise 7: Design & Review Architecture

```
> @architect Review the current project structure and suggest improvements
> @architect Design a real-time notification system that works across Angular web and Flutter mobile using Firebase Cloud Messaging
> @database-designer Design the notification schema with PostgreSQL for persistence and Firestore for real-time delivery
```

### Exercise 8: Add a Feature End-to-End

```
> /add-feature User profile management — users can update their name, avatar, and preferences. Backend API + Angular settings page + Flutter profile screen
```

## 9. Claude Code Power Features

### Thinking Mode

Claude Code supports extended thinking for complex reasoning. Opus 4.5 has thinking enabled by default.

| Trigger | Thinking Budget | When to Use |
|---------|----------------|-------------|
| `think` | Standard | General reasoning, code analysis |
| `think harder` | Extended | Complex debugging, multiple approaches |
| `ultrathink` | Maximum | Critical architecture decisions, deep security review |

```
> think about how to restructure the auth module
> think harder about why this race condition occurs
> ultrathink about the migration strategy from monolith to microservices
```

Toggle thinking: `Alt+T` (Win/Linux) or `Option+T` (macOS). `Tab` makes it sticky across prompts.

### Essential CLI Flags

| Flag | What It Does | Example |
|------|-------------|---------|
| `claude` | Start interactive session | `claude` |
| `claude -p "task"` | Print mode — non-interactive, prints result and exits | `claude -p "explain this codebase"` |
| `claude --continue` | Continue last session | `claude --continue` |
| `claude --resume <id>` | Resume specific session by ID or name | `claude --resume auth-refactor` |
| `claude --model <name>` | Use specific model (sonnet, opus, haiku) | `claude --model opus` |
| `claude --output-format json` | JSON output (great for CI/CD) | `claude -p "run tests" --output-format json` |
| `claude --max-turns N` | Limit agentic turns (print mode) | `claude -p --max-turns 3 "fix lint errors"` |
| `claude --max-budget-usd N` | Cap API spend (print mode) | `claude -p --max-budget-usd 5.00 "run tests"` |
| `claude --add-dir <path>` | Add extra working directories | `claude --add-dir ../frontend ../shared` |
| `claude --dangerously-skip-permissions` | Skip all permission prompts ⚠️ | Use with extreme caution |
| `claude --debug` | Enable debug logging | `claude --debug "api,mcp"` |

### Core Tools

Every tool Claude Code has access to:

| Tool | Purpose | Needs Permission? |
|------|---------|:-:|
| **Read** | Read files, images, PDFs | No |
| **Write** | Create new files | Yes |
| **Edit** | Modify existing files (exact string replacement) | Yes |
| **Bash** | Execute shell commands | Yes |
| **Grep** | Search content with regex (ripgrep) | No |
| **Glob** | Find files by pattern | No |
| **Task** | Launch sub-agents | No |
| **TodoWrite** | Track multi-step task progress | No |
| **WebFetch** | Fetch and analyze web pages | Yes |
| **WebSearch** | Search the web | Yes |
| **LSP** | Go-to-definition, find references, hover docs | No |
| **NotebookRead/Edit** | Read/edit Jupyter notebooks | Read: No, Edit: Yes |

### @ File References

Reference files directly in prompts with `@` — Claude reads them automatically:

```
> Review @src/auth/login.ts for security issues
> Compare @src/api/v1/users.ts and @src/api/v2/users.ts — what changed?
> Generate tests for @src/utils/validator.ts
> This bug is in @src/services/auth.ts, check @logs/error.log for clues
```

Works in both regular prompts and slash command arguments. Reduces token usage compared to reading entire directories.

### Prompting Best Practices

| Instead of... | Write... |
|---------------|----------|
| "Add tests" | "Write Jest tests for `src/utils/date.ts` covering: formatDate with valid dates, invalid inputs, and timezone handling" |
| "Fix the bug" | "Login fails when email contains `+`. Fix `src/auth/validate.ts:23` to handle plus signs in email addresses" |
| "Review this" | "Review `src/api/users.ts` for: N+1 queries, missing error handling, and SQL injection risks" |
| "Make it faster" | "Profile the `/api/products` endpoint. Identify the slowest operation. Target: < 100ms response" |
| "Add auth" | "Add JWT authentication to the Express API: login/register endpoints, middleware for protected routes, refresh tokens with 7-day expiry" |

### Permission Model

Claude Code uses an allow / deny / ask system. Configure in `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": {
      "Bash": ["git status", "git diff", "git log", "npm test", "npm run*"],
      "Read": {},
      "Edit": {}
    },
    "deny": {
      "Write": ["*.env", ".env.*", ".git/*"],
      "Edit": ["*.env", ".env.*"]
    }
  }
}
```

This lets common safe commands run without asking, blocks sensitive file edits entirely, and asks for everything else. The kit's `settings.json` comes pre-configured with sensible defaults.

---

## 10. Tips & Best Practices

### Getting the Best Results

1. **Be specific** — "Create a REST endpoint for user registration with email validation, password hashing using BCrypt, and a confirmation email trigger" beats "make a signup API"

2. **Use agents for focused work** — `@java-spring-api` gives you a specialized backend expert instead of a generalist

3. **Add `use context7`** to any prompt when you need current library documentation — it fetches live docs and prevents hallucinated APIs

4. **Use `/init` as a starting point** — it auto-generates a `CLAUDE.md` from your codebase, but always trim and curate the result by hand (see "Writing a Good CLAUDE.md" below)

5. **Resume sessions** — `claude -c` continues your last conversation, `claude --resume` lets you pick from recent sessions

6. **Chain commands in one prompt** — you can combine commands and natural language: `/scaffold-spring-api order-service then @java-spring-api add CRUD for Orders with items, totals, and status`

7. **Use sandbox mode** for risky operations — Claude runs in a restricted environment without affecting your system. Conversely, `--dangerously-skip-permissions` removes all guardrails (use with extreme caution)

### Context Window Management

Your 200K context window is your most precious resource. Mismanaging it is the #1 cause of degraded performance.

| Problem | Impact | Fix |
|---------|--------|-----|
| Too many MCPs enabled | Each MCP's tool definitions eat context before you even start. 20+ MCPs can cut usable context from 200K to ~70K | Keep MCPs in config but disable unused ones — enable ≤ 10 servers / ≤ 80 tools at a time |
| Too many plugins active | Same issue — each plugin adds tool definitions | Install many, enable only 4–5 per project |
| Long sessions without compacting | Context fills up, Claude loses track of earlier work | Use `/compact` to manually trigger compaction, or let auto-compact handle it |
| Huge CLAUDE.md | Goes into every prompt, crowding out actual task context | Keep < 300 lines, use progressive disclosure |

**Check your current state anytime:**

```
> /mcp                  # See MCP status and tool count
> /plugins              # See enabled plugins
> /statusline           # Shows context remaining %
```

### Parallel Workflows

Don't queue tasks — run them simultaneously:

| Technique | When to Use | How |
|-----------|-------------|-----|
| `/fork` | Non-overlapping tasks in the same repo | Type `/fork` to branch the conversation — each fork works independently |
| **Git worktrees** | Overlapping tasks that touch the same files | Each worktree is an independent checkout with its own Claude instance |
| **tmux** | Long-running commands (servers, test suites) | Claude runs in a tmux session you can detach/reattach to monitor |

```bash
# Git worktrees — parallel Claudes without conflicts
git worktree add ../feature-auth feature/auth
git worktree add ../feature-dashboard feature/dashboard
# Run separate `claude` instances in each directory

# tmux — monitor long-running commands
tmux new -s dev          # Start named session
# Claude runs servers here, you can detach (Ctrl+B, D) and reattach:
tmux attach -t dev
```

### Hooks Quick Reference

Hooks automate guardrails and formatting. Define them in `settings.json` under `"hooks"`:

| Hook Type | Fires When | Common Uses |
|-----------|-----------|-------------|
| `PreToolUse` | Before a tool executes | Validation, tmux reminders for long commands, block risky operations |
| `PostToolUse` | After a tool finishes | Auto-format with Prettier/ruff, type-check, warn about `console.log` |
| `UserPromptSubmit` | When you send a message | Input validation, context injection |
| `Stop` | When Claude finishes responding | Audit modified files, run linter on changes |
| `PreCompact` | Before context compaction | Save important state before context is compressed |
| `Notification` | On permission requests | Custom notification routing |

**Example:** Auto-format TypeScript after every edit + block `console.log`:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit && .ts/.tsx",
      "hooks": [{
        "type": "command",
        "command": "npx prettier --write $FILEPATH && npx tsc --noEmit"
      }]
    }],
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "git diff --name-only | xargs grep -l 'console.log' && echo '[Hook] console.log detected in changes' >&2"
      }]
    }]
  }
}
```

> 💡 **Tip:** Install the `hookify` plugin to create hooks conversationally — run `/hookify` and describe what you want in plain English.

### Plugins Ecosystem

Beyond Claude-Mem, there's a growing plugin ecosystem. Plugins bundle tools, skills, hooks, or MCP integrations for easy install.

```bash
# Install a plugin marketplace
> /plugin marketplace add <github-user/repo>

# Browse and install from /plugins menu
> /plugins
```

**Worth exploring:**

| Plugin | What It Does |
|--------|-------------|
| `typescript-lsp` | Real-time type checking + go-to-definition without an IDE |
| `pyright-lsp` | Python type checking (useful if running Claude outside an editor) |
| `hookify` | Create hooks by describing them in natural language |
| `mgrep` | Better code search than ripgrep — supports local + web search |
| `context7` | Live documentation for any library |
| `commit-commands` | Streamlined git workflow commands |

> ⚠️ **Same context warning as MCPs** — each enabled plugin adds tool definitions. Install many, enable few.

### Keyboard Shortcuts

**Slash Commands:**

| Command | Action |
|---------|--------|
| `/help` | Show all available commands |
| `/clear` | Clear conversation context |
| `/compact [focus]` | Compact context (optionally specify what to keep) |
| `/fork` | Fork conversation for parallel work |
| `/rewind` | Go back to a previous state (undo code changes) |
| `/checkpoints` | File-level undo points |
| `/statusline` | Customize status bar (branch, context %, model, todos) |
| `/context` | View context usage as a colored grid |
| `/cost` | Show token usage statistics |
| `/stats` | Usage stats with date range (7/30/all-time) |
| `/usage` | View plan limits and usage |
| `/exit` | Exit Claude Code |
| `/memory` | Open CLAUDE.md in your editor |
| `/agents` | List / create agents |
| `/mcp` | Check MCP server status |
| `/model` | Switch between models |
| `/plan` | Enter plan mode (Opus plans, Sonnet executes) |
| `/rename <name>` | Name the current session |
| `/resume <name>` | Resume a previous session by name or ID |
| `/review` | Request code review |
| `/doctor` | Run diagnostics |

**Keyboard:**

| Shortcut | Action |
|----------|--------|
| `!` | Quick bash command prefix |
| `@` | Search for files (include in prompts too) |
| `Tab` | Toggle thinking mode (sticky) |
| `Shift+Enter` | Multi-line input |
| `Ctrl+U` | Delete entire line |
| `Ctrl+R` | Search command history |
| `Ctrl+O` | View transcript (shows thinking blocks) |
| `Ctrl+G` | Edit prompt in system text editor |
| `Ctrl+B` | Background current command / agent |
| `Ctrl+Z` | Suspend / Undo |
| `Alt+T` / `Option+T` | Toggle thinking mode |
| `Alt+P` / `Option+P` | Switch models while typing |
| `Esc` | Cancel current generation |
| `Esc Esc` | Interrupt Claude / restore code |

### Writing a Good CLAUDE.md

Your `CLAUDE.md` is the **highest-leverage file** in the entire setup — it goes into every session and shapes every task. A bad line here ripples into every plan, every implementation, every artifact Claude produces. Invest time crafting it carefully.

#### The Basics: WHAT → WHY → HOW

| Tell Claude... | Example |
|----------------|---------|
| **WHAT** — your tech, stack, project structure | "Monorepo: `apps/api` (Spring Boot), `apps/web` (Angular), `packages/shared`" |
| **WHY** — the purpose of each part | "The `gateway` service handles auth + rate-limiting for all downstream APIs" |
| **HOW** — how to work on the project | "Use `bun` not `npm`. Run tests with `./gradlew test`. Flyway migrations live in `db/migrations/`" |

#### Key Principles

| Principle | Why It Matters |
|-----------|---------------|
| **Less is more** | LLMs can reliably follow ~150–200 instructions. Claude Code's system prompt already uses ~50 of those. Every line you add competes for attention — keep only what's universally applicable. |
| **Claude may ignore irrelevant content** | Claude Code wraps your CLAUDE.md in a system reminder saying *"this may or may not be relevant."* If your file is full of niche instructions, Claude is more likely to skip all of them — not just the niche ones. |
| **Progressive disclosure** | Don't dump everything into CLAUDE.md. Keep domain-specific docs in separate files and reference them so Claude reads them only when needed (see example below). |
| **Don't use it as a linter** | Never send an LLM to do a linter's job. Use deterministic tools (ruff, Biome, ESLint) via Hooks instead. Style guidelines bloat your context and degrade instruction-following. |
| **Prefer pointers over copies** | Don't paste code snippets — they go stale. Point to `file:line` references so Claude reads the actual source of truth. |
| **Craft it by hand** | Avoid auto-generating with `/init` for your primary CLAUDE.md. Auto-generated files tend to include too much irrelevant content. Use `/init` as a *starting point* only, then trim aggressively. |

#### Progressive Disclosure Example

Instead of a 500-line CLAUDE.md, keep it short and point to detail docs:

```markdown
# CLAUDE.md

## Project
E-commerce platform — Spring Boot API + Angular SPA + Flutter mobile.

## Key Docs (read the relevant ones before starting a task)
- `docs/building.md` — how to build, run, and deploy each service
- `docs/testing.md` — test commands, fixtures, CI expectations
- `docs/database.md` — schema overview, migration workflow
- `docs/api-contracts.md` — OpenAPI specs and versioning rules
- `docs/code-conventions.md` — naming, structure, PR standards

## Universal Rules
- All code must pass `./gradlew check` before committing
- Use conventional commits: feat|fix|docs|refactor(scope): message
- Never commit secrets or .env files
```

#### Quick Rules of Thumb

- **< 300 lines** is the general consensus; shorter is better (some teams use < 60 lines)
- Most important rules go **at the top and bottom** — LLMs attend most to the peripheries of the prompt
- Use `CLAUDE.local.md` for personal preferences (auto-gitignored)
- Use `.claude/rules/` for conditional rules that only apply in specific directories

---

## 11. Troubleshooting

### "command not found: claude"
```bash
# Add to your shell config
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### "Context too large" error
```
> /compact                          # Quick reset
> /compact "keep the auth work"     # Smart cleanup — preserves specified context
```
Prevention: use `/compact` every ~50 operations in long sessions, or start fresh for new features.

### Edit tool fails with "string not found"
Claude's Edit tool requires an exact string match including whitespace and indentation. Fix:
```
> Read the file again to see exact content
```
If the string appears multiple times, provide more surrounding context for uniqueness.

### MCP server not connecting
```
> /mcp
```
Check the status output. Common fixes:
- Make sure `npx` is available (Node.js installed)
- For GitHub MCP, set your token: `export GITHUB_TOKEN=ghp_your_token_here`
- Restart Claude Code after changing `.mcp.json`
- On Windows, MCP servers need `cmd /c` wrapper: `"command": "cmd", "args": ["/c", "npx", "-y", "package-name"]`

### Claude isn't using skills or agents
- Verify the files exist: `ls .claude/agents/` and `ls .claude/skills/`
- Check YAML frontmatter in each file (needs `---` delimiters)
- Try explicitly mentioning: "Use the java-spring-api skill"

### Background task not responding
```
> /tasks          # or /bashes — check status
> /kill <id>      # Stop the stuck task
```

### Permission errors
- Never use `sudo` with npm installs
- Fix npm permissions: `npm config set prefix ~/.npm-global` and add to PATH
- Pre-configure permissions in `.claude/settings.json` to avoid repeated prompts

### Run diagnostics
```bash
claude doctor          # General diagnostics
claude --debug         # Debug mode with full logging
claude --debug "mcp"   # Debug specific categories
```

---

## 12. Resources

| Resource | Link |
|----------|------|
| Claude Code Official Docs | [code.claude.com/docs](https://code.claude.com/docs) |
| Claude Code GitHub | [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) |
| Claude Code Quickstart | [code.claude.com/docs/en/quickstart](https://code.claude.com/docs/en/quickstart) |
| CLI Reference | [code.claude.com/docs/en/cli-reference](https://code.claude.com/docs/en/cli-reference) |
| Settings Reference | [code.claude.com/docs/en/settings](https://code.claude.com/docs/en/settings) |
| Skills Documentation | [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) |
| Hooks Documentation | [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks) |
| Plugins Reference | [code.claude.com/docs/en/plugins](https://code.claude.com/docs/en/plugins) |
| Sub-agents Guide | [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents) |
| MCP Documentation | [code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp) |
| Memory System | [code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory) |
| SDK Overview | [code.claude.com/docs/en/sdk](https://code.claude.com/docs/en/sdk) |
| Desktop App | [code.claude.com/docs/en/desktop](https://code.claude.com/docs/en/desktop) |
| Claude-Mem Plugin | [github.com/thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) |
| Context7 MCP | [github.com/upstash/context7](https://github.com/upstash/context7) |
| VS Code Download | [code.visualstudio.com/download](https://code.visualstudio.com/download) |
| Awesome Claude Code (Community) | [github.com/hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) |
| Awesome Claude Skills | [github.com/travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) |
| MCP Specification | [modelcontextprotocol.io](https://modelcontextprotocol.io) |
| Prompting Guide | [docs.claude.com/en/docs/build-with-claude/prompt-engineering/overview](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/overview) |
