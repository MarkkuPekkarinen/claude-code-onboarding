# Claude Code — Team Onboarding Kit

**Get your team from zero to productive with Claude Code in under 30 minutes.**

This repository is a pre-configured starter kit packed with agents, skills, slash commands, and MCP integrations — ready to go for the following tech stack:

| Layer | Technologies |
|---|---|
| **Backend** | Java 21, Spring Boot WebFlux 3.5.x, Python 3.12+ |
| **Frontend** | Angular 21.x, TypeScript 5.x |
| **Mobile** | Flutter 3.38, Dart 3.11 |
| **Data & Infra** | PostgreSQL, Firebase |
| **AI Tooling** | Claude Code, MCP servers |

Clone it, install Claude Code, and start building.

---

## Table of Contents

- [What is Claude Code?](#what-is-claude-code)
- [1. Prerequisites](#1-prerequisites)
- [2. Clone This Repo](#2-clone-this-repo)
- [3. Set Up Your Editor (Install VS Code)](#3-set-up-your-editor-install-vs-code)
- [4. Install Claude Code](#4-install-claude-code)
  - [Native Binary (Recommended)](#native-binary-recommended)
- [5. First-time Using Claude Code](#5-first-time-using-claude-code)
- [6. Install Claude-Mem (Persistent Memory)](#6-install-claude-mem-persistent-memory-optional)
  - [What Claude-Mem Does](#what-claude-mem-does)
- [7. Try It Out — Your First 5 Minutes](#7-try-it-out--your-first-5-minutes)
  - [Ask about the project](#ask-about-the-project)
  - [Scaffold something](#scaffold-something)
  - [Use a sub-agent](#use-a-sub-agent)
  - [Pull live docs with MCP](#pull-live-docs-with-mcp)
  - [Check what's loaded](#check-whats-loaded)
  - [A note on permissions](#a-note-on-permissions)
- [8. Understanding Claude Code Components](#8-understanding-claude-code-components)
  - [How They Fit Together](#how-they-fit-together)
  - [Decision Matrix - When to Use What](#decision-matrix---when-to-use-what)
  - [CLAUDE.md](#claudemd)
  - [Slash Commands — Reusable Prompt Shortcuts](#slash-commands--reusable-prompt-shortcuts)
  - [Agents (Subagents) — Specialist AI Personas](#agents-subagents--specialist-ai-personas)
  - [Skills — Auto-Activated Knowledge](#skills--auto-activated-knowledge)
  - [MCP Servers — External Tool Integrations](#mcp-servers--external-tool-integrations)
  - [Hooks — Automated Guardrails](#hooks--automated-guardrails)
- [9. What Gets Sent to the LLM?](#9-what-gets-sent-to-the-llm)
  - [Context Window Anatomy](#context-window-anatomy)
  - [What Each Layer Contains](#what-each-layer-contains)
  - [Key Takeaways](#key-takeaways)
- [10. What's in This Repo](#10-whats-in-this-repo)
- [11. Hands-On Exercises](#11-hands-on-exercises)
  - [Exercise 1: Scaffold a Flutter Fitness App](#exercise-1-scaffold-a-flutter-fitness-app)
  - [Exercise 2: Build a Weather REST API (Java)](#exercise-2-build-a-weather-rest-api-java)
  - [Exercise 3: Build a Todo API (Node.js/TypeScript)](#exercise-3-build-a-todo-api-nodejstypescript)
  - [Exercise 4: Build an Analytics API (Python)](#exercise-4-build-an-analytics-api-python)
  - [Exercise 5: Design a Full-Stack E-Commerce System](#exercise-5-design-a-full-stack-e-commerce-system)
  - [Exercise 6: Pull Live Docs with Context7 (MCP)](#exercise-6-pull-live-docs-with-context7-mcp)
  - [Exercise 7: Design & Review Architecture](#exercise-7-design--review-architecture)
  - [Exercise 8: Add a Feature End-to-End](#exercise-8-add-a-feature-end-to-end)
- [12. Claude Code Power Features](#12-claude-code-power-features)
  - [Keyboard Shortcuts (Inside Claude Code)](#keyboard-shortcuts-inside-claude-code)
  - [Essential CLI Flags](#essential-cli-flags)
  - [Core Tools](#core-tools)
  - [Permission Model](#permission-model)
- [13. Tips & Best Practices](#13-tips--best-practices)
  - [Prompting Best Practices](#prompting-best-practices)
  - [@ File References](#-file-references)
  - [Context Window Management](#context-window-management)
  - [Parallel Workflows](#parallel-workflows)
  - [Plugins Ecosystem](#plugins-ecosystem)
  - [Writing a Good CLAUDE.md](#writing-a-good-claudemd)
- [14. Troubleshooting](#14-troubleshooting)
- [15. Resources](#15-resources)

---

## What is Claude Code?

**[Claude Code](https://code.claude.com/docs/en/overview)** is an **agentic AI coding assistant that lives in your terminal**. It understands your codebase, edits files, runs commands, and writes code — all through natural language.

Think of it as a senior developer pair-programming with you who knows your entire project, follows your team's conventions, and never gets tired.

## 1. Prerequisites

Before you begin, make sure you have:

- **A Claude subscription** — Claude Pro or Max at [claude.ai](https://claude.ai), or an Anthropic API key from the [Console](https://console.anthropic.com)

**Optional for Quick Start (required for MCP servers):**

- [Node.js v22+](https://nodejs.org/en/download)
- [Python v3.12+](https://www.python.org/downloads/)

## 2. Clone This Repo

This repo is your playground — use it to learn and practice Claude Code (Agentic AI coding assistant) and get familiar with its components (agents, skills, slash commands, MCP servers) so you can automate your development workflow.

```bash
git clone https://github.com/kumaran-is/claude-code-onboarding.git
cd claude-code-onboarding
```

## 3. Set Up Your Editor (Install VS Code)

We recommend open source **[Visual Studio Code](https://code.visualstudio.com/)** as your IDE, though Claude Code works from any terminal — no specific editor is required. Download and install **[Visual Studio Code](https://code.visualstudio.com/)** from the official site:

After installing, open the cloned project `claude-code-onboarding` with **[Visual Studio Code](https://code.visualstudio.com/)** and use the **integrated terminal** for the remaining steps.

## 4. Install Claude Code

Open the **[Visual Studio Code](https://code.visualstudio.com/)** integrated terminal and run the following:

### Native Binary (Recommended)

1. For macOS / Linux

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

2. Reload your shell

```bash
source ~/.bashrc   # or: source ~/.zshrc
```

3. After installation, **restart VS Code(Close and reopen VS Code)** so the terminal picks up the new PATH, then verify installation

```bash
claude --version
```

> For Windows, see the [official installation docs](https://code.claude.com/docs/en/quickstart).

## 5. First-time Using Claude Code

> **Note:** First-time users will be prompted to authenticate with a Claude Pro/Max subscription or an Anthropic API key.

From the VS Code terminal, launch the CLI:

```bash
claude
```

Follow the on-screen prompts to log in. Once authenticated with your **Claude Pro/Max subscription** or **Anthropic Console API key**. Claude Code automatically detects and loads the project configuration:

That's it! Claude Code will automatically detect and load:
| File / Directory | Purpose |
|---|---|
| `CLAUDE.md` | Project context and conventions |
| `.mcp.json` | MCP server configurations |
| `.claude/agents/` | Specialized AI agents |
| `.claude/skills/` | Domain knowledge and templates |
| `.claude/commands/` | Slash commands |

Try these right away:

```
> /project-status
> What agents and skills are available in this project?
> Explain the tech stack from CLAUDE.md
```

🔗 **Official Docs:** [https://code.claude.com/docs/en/quickstart](https://code.claude.com/docs/en/quickstart)

## 6. Install Claude-Mem (Persistent Memory) *(Optional)*

Claude Code forgets everything between sessions. **[Claude-Mem](https://github.com/thedotmack/claude-me)** gives Claude persistent memory across sessions. 

Inside a Claude Code CLI session, run:

```
> /plugin marketplace add thedotmack/claude-mem
> /plugin install claude-mem
```

Then **restart Claude Code** (`/exit`) or restart (close and reopen) the vscode.

### What Claude-Mem Does

- **Automatically captures** what Claude Code does (file edits, decisions, tool usage)
- **Compresses** sessions into searchable memory using AI
- **Injects relevant context** at the start of new sessions
- **Web viewer** at `http://localhost:37777` to browse memory

Verify with: Inside a Claude Code CLI session, run:

```
> Do you have any memory from previous sessions?
```

## 7. Try It Out — Your First 5 Minutes

You're set up. Before diving into components and theory, take Claude Code for a spin. Run these inside your Claude Code session:

### Ask about the project

```
> What is this project? Summarize the tech stack and structure
```

```
> /project-status
```

### Scaffold something

```
> /scaffold-spring-api hello-world
```

Watch how Claude creates the full project structure, files, and boilerplate — all from a single command.

### Use a sub-agent

```
> @architect What improvements would you suggest for this project's structure?
```

Notice how the agent runs in its own context without cluttering your main conversation.

### Pull live docs with MCP

```
> Explain how to set up Spring Security with JWT. use context7
```

The `context7` MCP server fetches current, version-specific documentation instead of relying on training data.

### Check what's loaded

```
> What agents, skills, and slash commands are available in this project?
```

```
> /mcp
```

```
> /agents
```

That's the core workflow: **slash commands** to scaffold, **agents** for expertise, **MCP servers** for external tools, and **skills** that activate automatically in the background. The next section breaks down each component in detail.

### A note on permissions

Claude Code will ask for permission before accessing files or running commands. You'll see prompts like:

```
Do you want to proceed?
  1. Yes
❯ 2. Yes, allow reading from claude-code-onboarding/ from this project
  3. No
```

This can get annoying quickly since it triggers on nearly every action. Alternatively, to skip all permission prompts entirely for this Claude Code Session:

```bash
claude --dangerously-skip-permissions
```

> ⚠️ **Use with caution** — this disables all guardrails. Only use it in trusted environments or during local experimentation.


## 8. Understanding Claude Code Components

Knowing *when to use what* is the key to being productive with Claude Code. Here's a quick reference:

| Component | What It Does | Location | How It's Invoked |
|---|---|---|---|
| **CLAUDE.md** | Project context Claude reads at startup — tech stack, coding standards, architecture, workflows | `./CLAUDE.md`, `~/.claude/CLAUDE.md`, `.claude/rules/` | Auto-loaded at startup |
| **settings.json** | JSON configuration for permissions, hooks, and environment — allow/deny/ask permission rules, hooks config, env vars for Claude Code | `.claude/settings.json` (project), `~/.claude/settings.json` (user) | Auto-loaded at startup |
| **Skills** | Modular expertise Claude applies automatically based on context — lazy-loaded when needed, not user-invoked. Best for complex, recurring workflows (code review, API design patterns)  | `.claude/skills/<name>/SKILL.md` | Auto (Claude decides) |
| **Slash Commands** | `/command` shortcuts for repeatable prompts — quick actions you trigger manually | `.claude/commands/<name>.md` | You type `/command` |
| **Sub-agents** | Specialized AI with isolated context for complex tasks — parallel processing, focused expertise | `.claude/agents/<name>.md` | You type `@agent` or Auto (Claude decides|
| **Hooks** | Scripts that run at lifecycle events — auto-formatting, validation, notifications. Types: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `PreCompact`, `Notification`  | Defined in `settings.json` → `hooks` | Automatic on events |
| **MCP Servers** | Tool connections to external services — GitHub, Slack, databases, docs, APIs | `.mcp.json` (project root) | Claude uses as needed |

### How They Fit Together

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

### Decision Matrix - When to Use What

| Use | You Need To… | Example |
|---|---|---|
| **CLAUDE.md** | Set project conventions and context | Project Overview, Project Context, Tech Stack, Coding Standards, Rules |
| **settings.json** | Control what Claude can do | Allow `git` commands, deny `sudo` |
| **Skill** | Auto-apply patterns for a domain | Always use Riverpod when building Flutter |
| **Slash Command** | Run a repeatable prompt yourself(manual) | `/scaffold-spring-api weather-service` |
| **Sub-agent** | Get deep domain expertise in isolation, can be manual or auto | `@database-designer Design schema for…` |
| **Hook** | Enforce hard rules every time | Block commits without passing tests |
| **MCP Server** | Connect to external services | GitHub PRs, Context7 live docs, Firebase |
| **Claude-Mem plugin** | Remember things across sessions | Persistent memory of past decisions |

### CLAUDE.md

**What:** A Markdown file at the project root that gives Claude Code, context about your project — tech stack, conventions, common commands, and rules.

**When to use:** Every project should have one. It's the first thing Claude reads at startup.

**Where:** `./CLAUDE.md` (project root) or `~/.claude/CLAUDE.md` (global, all projects)

You can auto-generate one by running `/init` inside a Claude Code session. This repo already includes one, so you can skip this step.

```bash
# Auto-generate one from your codebase
claude
> /init
```

**Tips:**

- Keep it under 40KB — too much context overloads the LLM's 200K token window
- Put the most important rules at the top
- Use imports for large docs: `@docs/api-reference.md`

### Slash Commands — Reusable Prompt Shortcuts

**What:** Saved prompts you trigger with `/command-name`. Think of them as reusable prompt shortcuts.

**When to use:** When you have a repeatable workflow you run often — scaffolding, reviewing, deploying.

**Where:** `.claude/commands/my-command.md` (project) or `~/.claude/commands/` (global)

**Examples: Try running below commands inside Claude Code Session**
```
> /scaffold-spring-api weather-service
> /scaffold-flutter-app fitness-tracker
> /design-database fitness tracking with users, workouts, and goals
```

Use `$ARGUMENTS` in the command file (`.claude/commands/scaffold-spring-api.md`) to accept parameters.

### Agents (Subagents) — Specialist AI Personas

**What:** Specialized Claude instances with their own system prompt and tool restrictions. They run in a **separate context window**, so they don't pollute your main conversation.

**When to use:** When you need deep expertise in a specific domain — a dedicated backend developer, database architect, or codereviewer.

**Where:** `.claude/agents/my-agent.md` (project) or `~/.claude/agents/` (global)

**Examples: Try running below commands inside Claude Code Session**
```
> @java-spring-api Create a CRUD API for a Product entity with name, price, and category
> @flutter-mobile Build a login screen with Firebase Auth
> @database-designer Design the schema for an e-commerce platform
> @architect Design the system architecture for a real-time chat feature
```

### Skills — Auto-Activated Knowledge

**What:** Markdown files with domain knowledge, templates, and code patterns. Unlike commands, **Claude decides when to use them** based on the task context — you don't invoke them explicitly.

**When to use:** When you want Claude to **automatically** apply certain patterns whenever a matching task comes up (e.g., always use your team's DTO pattern when creating Spring entities).

**Where:** `.claude/skills/my-skill/SKILL.md`

The skills in this repo auto-activate based on context:

| When You Ask About… | Skill That Activates |
|---|---|
| Spring Boot | `java-spring-api` |
| Angular components | `angular-spa` |
| Flutter screens | `flutter-mobile` |
| Database schemas | `database-design` |
| System architecture | `architecture-design` |


### MCP Servers — External Tool Integrations

**What:** The Model Context Protocol connects Claude Code to external services (GitHub, databases, documentation servers, gmail, slack, APIs) so Claude can use them as tools.

**When to use:** When Claude needs to interact with services beyond the local filesystem — creating GitHub PRs, querying live databases, fetching up-to-date documentation, invoking APIs.

**Where:** `.mcp.json` (project root)

This repo comes pre-configured with:

| Server | What It Does |
|---|---|
| **Context7** | Live, version-specific documentation for any library — add `use context7` to prompts |
| **GitHub** | Create issues, PRs, browse repos, review code via GitHub Copilot MCP |
| **Angular CLI** | Angular schematics, builds, and project scaffolding directly from Claude |
| **Chrome DevTools** | Browser debugging and inspection |
| **Firebase** | Firestore and Auth operations |
| **Sequential Thinking** | Step-by-step reasoning for complex multi-step problems |
| **Dart** | Dart language server integration |
| **Filesystem** | Secure file search and manipulation with configurable directory permissions |
| **LangChain Docs** | Live LangChain documentation lookup |

### Hooks — Automated Guardrails

**What:** Shell scripts that run automatically at specific lifecycle events (before/after tool use, on session start/end). Think of them as **middleware for Claude Code** — deterministic, always execute the same way.

**When to use:** When you need hard rules enforced every time, like **run linter before commit** or **block commits without passing tests** or **block destructive commands** or **auto-format after every edit**.

| Hook Event | Fires When | Mental Model | Real-World Examples |
|---|---|---|---|
| **PreToolUse** | Before a tool executes | 🛑 *Stop something dangerous from happening* | Block `git push` to main/master, prevent `rm -rf /` or `DROP DATABASE`, protect `.env` files from edits |
| **PostToolUse** | After a tool completes | 🔧 *Fix/check what just happened to a single file* | Auto-format with Prettier/ruff after edits, run ESLint on the changed file, type-check with `tsc --noEmit` |
| **Stop** | When Claude finishes responding | ✅ *Validate the whole result before calling it done* | Run unit tests once at the end (not per-file), audit all changed files, scan for leaked secrets |
| **PermissionRequest** | When Claude shows a permission dialog | 🔐 *Auto-decide on permission prompts* | Auto-approve `git status`, deny `sudo` commands |
| **UserPromptSubmit** | When you send a message | 📥 *Intercept and enrich your input* | Auto-prepend "use context7" to all prompts, inject current git branch name, Inject project-specific context, validate prompt format|
| **SubagentStop** | When a sub-agent finishes | 🔍 *Quality-check delegated work* | Check generated code compiles, verify output format |
| **PreCompact** | Before context compaction | 💾 *Save state before memory shrinks* | Export TODO list, save working notes to a file |
| **SessionStart** | When a session starts or resumes | 🚀 *Set up the environment* | Source `.env` files, verify toolchain is installed |
| **SessionEnd** | When a session ends | 🧹 *Clean up after yourself* | Log session summary, clean up temp files |
| **Notification** | On permission prompts or idle | 📢 *Route alerts externally* | Send Slack alert on long-running tasks, desktop notifications |

**Where:** `.claude/settings.json` → `hooks` section, scripts in `.claude/hooks/`

This repo includes 4 hooks out of the box:

| Hook | Script | Event | What It Does |
|------|--------|-------|-------------|
| **Bash Guard** | `pre-bash-guard.sh` | `PreToolUse` → Bash | Blocks `rm -rf /`, `rm -rf .`, force-push to main, `DROP DATABASE` |
| **Protect Sensitive Files** | `pre-edit-protect-sensitive.sh` | `PreToolUse` → Write/Edit | Blocks edits to `.env`, credentials, private keys, lock files |
| **Auto-Format** | `post-edit-format.sh` | `PostToolUse` → Write/Edit | Runs Prettier (TS/JS/HTML/CSS), `dart format`, ruff/black (Python) |
| **Secret Scan** | `stop-secret-scan.sh` | `Stop` | Warns if changed files contain AWS/GCP/GitHub/OpenAI API keys |

> After cloning: `chmod +x .claude/hooks/*.sh`

> **Tip:** Install the `hookify` plugin to create hooks conversationally — run `/hookify` and describe what you want in plain English.

## 9. What Gets Sent to the LLM?

Every time you send a prompt in Claude Code, it assembles a **context window** — the complete package of information sent to the LLM for that turn. Understanding what goes into this window helps you manage it effectively.

### Context Window Anatomy

![Context Window](./img/what-sent-to-the-llm.png)

### What Each Layer Contains

| Layer | What's Loaded | When | Token Impact |
|---|---|---|---|
| **System Prompt** |Claude's core behavior rules, response formatting, ethical guidelines. Internal to Claude Code — not visible or editable by users. | Always — every turn | ~3K tokens (fixed) |
| **System Tools** | Built-in tool definitions (Read, Write, Edit, Bash, Grep, etc.). Internal to Claude Code — not visible or editable by users. | Always — every turn | ~12K tokens (fixed) |
| **CLAUDE.md** | Your project context — tech stack, conventions, rules | Startup — persists all session | Varies (keep under 300 lines or under 40KB) |
| **MCP Tools** | Tool schemas from connected MCP servers | Startup, or on-demand via Tool Search | Can be 5K–50K+ depending on server count |
| **Agent Definitions** | Descriptions of available sub-agents | Startup | Small (~100 tokens per agent) |
| **Hooks Config** | Hook definitions from settings.json | Startup | ~1K tokens |
| **Slash Commands** | Resolved command content (only the one you invoked) | When you run `/command` | Varies per command |
| **Skills** | Skill content (only skills Claude deems relevant) | On-demand — Claude decides | Varies per skill |
| **@ File References** | File contents pulled into the prompt | When you use `@file` in a prompt | Depends on file size |
| **Conversation History** | All prior messages, responses, and tool outputs | Accumulates every turn | Grows linearly |
| **Compression Buffer** | Reserved space for auto-compaction summaries | When context approaches ~75% full | ~22% of window |

### Key Takeaways

**Everything competes for the same 200K tokens.** A bloated CLAUDE.md, 20 MCP servers, and a long conversation history all eat from the same pool. When the window fills up, Claude's output quality degrades.

**MCP tools are the biggest variable cost.** Each connected server adds tool schemas to every turn. With 20+ servers, you can lose 50K+ tokens before typing anything. Claude Code now has **Tool Search** that loads MCP tools on-demand (auto-activates when tools exceed 10% of context), but keeping unused servers disabled is still best practice.

**Skills and commands load selectively.** Unlike CLAUDE.md (always loaded), skills only load when Claude determines they're relevant, and slash commands only load when you invoke them. This is why skills are preferred over stuffing everything into CLAUDE.md.

**Monitor your usage:**

```
> /context              # Visual breakdown of token usage
> /cost                 # Token and cost statistics
> /compact              # Manually compress conversation history
```

## 10. What's in This Repo

```
claude-code-onboarding/
├── CLAUDE.md                            # Project memory — tech stack, conventions, rules
├── .mcp.json                            # MCP servers: Context7, GitHub, Filesystem, Firebase
├── .gitignore
├── README.md                            # ← You are here
│
└── .claude/
    ├── settings.json                    # Permissions and hook configs
    ├── settings.local.json              # Personal overrides (gitignored)
    │
    ├── hooks/                            # Lifecycle hook scripts (chmod +x after cloning)
    │   ├── pre-bash-guard.sh             # Block destructive bash commands
    │   ├── pre-edit-protect-sensitive.sh # Block edits to .env, keys, lock files
    │   ├── post-edit-format.sh           # Auto-format TS/JS/Dart/Python after edits
    │   └── stop-secret-scan.sh           # Scan changed files for leaked secrets
    │
    ├── agents/                          # Specialist AI personas (invoke with @name)
    │   ├── java-spring-api.md           # Spring Boot WebFlux expert
    │   ├── nodejs-typescript.md         # Node.js / TypeScript expert
    │   ├── python-dev.md                # Python / FastAPI expert
    │   ├── angular-spa.md               # Angular frontend expert
    │   ├── flutter-mobile.md            # Flutter mobile expert
    │   ├── flutter-security-expert.md   # Security & privacy compliance
    │   ├── frontend-design.md           # Creative UI/UX design specialist
    │   ├── database-designer.md         # PostgreSQL + Firestore architect
    │   ├── architect.md                 # Solution architect
    │   ├── code-reviewer.md             # Code quality & review specialist
    │   ├── security-reviewer.md         # Security vulnerability reviewer
    │   ├── accessibility-auditor.md     # WCAG / a11y compliance auditor
    │   ├── postgresql-database-reviewer.md # PostgreSQL performance & schema reviewer
    │   ├── riverpod-reviewer.md         # Flutter Riverpod state management reviewer
    │   ├── dedup-code-agent.md          # Dead code & duplication detector
    │   └── ui-standards-expert.md       # UI consistency & design system enforcement
    │
    ├── commands/                         # Slash commands (triggered with /name)
    │   ├── scaffold-spring-api.md       # /scaffold-spring-api <name>
    │   ├── scaffold-node-api.md         # /scaffold-node-api <name>
    │   ├── scaffold-python-api.md       # /scaffold-python-api <name>
    │   ├── scaffold-angular-app.md      # /scaffold-angular-app <name>
    │   ├── scaffold-flutter-app.md      # /scaffold-flutter-app <name>
    │   ├── design-database.md           # /design-database <domain description>
    │   ├── design-architecture.md       # /design-architecture <system description>
    │   ├── add-feature.md               # /add-feature <feature description>
    │   ├── project-status.md            # /project-status
    │   └── changelog.md                 # /changelog [version] — generate release notes
    │
    └── skills/                           # Auto-activated domain knowledge
        ├── java-spring-api/SKILL.md     # Spring Boot patterns & templates
        ├── java-coding-standard/SKILL.md # Java coding standards & conventions
        ├── nodejs-typescript/SKILL.md   # Node.js / TypeScript patterns & templates
        ├── python-dev/SKILL.md          # Python / FastAPI patterns & templates
        ├── angular-spa/SKILL.md         # Angular patterns & templates
        ├── flutter-mobile/SKILL.md      # Flutter patterns & templates
        ├── architecture-design/SKILL.md # Architecture patterns & templates
        ├── domain-finder/SKILL.md       # Domain name brainstorming & availability
        ├── changelog-generator/SKILL.md # Git history → user-facing release notes
        ├── database-schema-designer/    # Database schema design (multi-file skill)
        │   ├── SKILL.md                 # Core schema design patterns
        │   ├── README.md                # Skill documentation
        │   ├── assets/templates/
        │   │   └── migration-template.sql
        │   └── references/
        │       └── schema-design-checklist.md
        ├── mcp-builder/                 # MCP server development (multi-file skill)
        │   ├── SKILL.md                 # Core MCP building patterns
        │   ├── reference/               # Best practices & platform guides
        │   │   ├── mcp_best_practices.md
        │   │   ├── node_mcp_server.md
        │   │   ├── python_mcp_server.md
        │   │   └── evaluation.md
        │   └── scripts/                 # Evaluation & connection utilities
        │       ├── connections.py
        │       ├── evaluation.py
        │       ├── example_evaluation.xml
        │       └── requirements.txt
        └── playwright-skill/            # E2E testing with Playwright (multi-file skill)
            ├── SKILL.md                 # Core Playwright patterns
            ├── API_REFERENCE.md         # Playwright API quick reference
            ├── package.json
            ├── run.js
            └── lib/
                └── helpers.js
```

## 11. Hands-On Exercises

Work through these exercises to get familiar with Claude Code. Each one uses different components from this kit.
These exercises follow a deliberate progression to help you understand **which component to use for and when**:

### Exercise 1: Scaffold a Flutter Fitness App

**Components used:** Slash Command → Skill (auto) → Sub-agent
> **How it works:** The slash command kicks off scaffolding. Based on task context, Claude automatically activates relevant skills and sub-agents as needed — you just keep prompting naturally.

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

**Components used:** Slash Command → Sub-agent → Skill (auto)

Scaffold first, then use the `@java-spring-api` agent for domain-specific implementation:

```
> /scaffold-spring-api weather-service
> @java-spring-api Add a WeatherController that accepts a city name and returns mock weather data with temperature, humidity, and condition
> Add integration tests for the weather endpoint
```

### Exercise 3: Build a Todo API (Node.js/TypeScript)

**Components used:** Slash Command → Sub-agent

```
> /scaffold-node-api todo-service
> @nodejs-typescript Add a Todo model with Zod, a CRUD router, and an in-memory store
> Add Vitest tests for create and list endpoints
> Add a PUT endpoint to mark todos as complete
```

### Exercise 4: Build an Analytics API (Python)

**Components used:** Slash Command → Sub-agent

```
> /scaffold-python-api analytics-service
> @python-dev Add an async endpoint that accepts event data and stores it with timestamps
> Create a Pydantic model for events with type, payload, and metadata
> Add pytest tests for the event endpoints
```

### Exercise 5: Design a Full-Stack E-Commerce System

**Components used:** Slash Command → Sub-agent → Skill (auto) → MCP Server

This exercise chains multiple components together — architecture design, database schema, API scaffolding, and implementation:

```
> /design-architecture An e-commerce platform with product catalog, shopping cart, checkout, and order tracking. Angular SPA for web, Flutter for mobile, Spring Boot backend.
> /design-database e-commerce platform with products, categories, users, orders, order items, payments, and shipping
> /scaffold-spring-api ecommerce-api
> @java-spring-api Create CRUD endpoints for Products with name, description, price, category, and image URL
```

### Exercise 6: Pull Live Docs with Context7 (MCP)

**Components used:** MCP Server (Context7)

Append `use context7` to any prompt to fetch up-to-date, version-specific documentation instead of relying on Claude's training data:

```
> Create a Spring Boot WebFlux endpoint that uses Spring Security with JWT. use context7
> Build an Angular component using the new Angular signals API. use context7
> Set up Firebase App Check in Flutter. use context7
> Create a FastAPI endpoint with async SQLAlchemy. use context7
> Build an Express middleware with Zod request validation. use context7
```

### Exercise 7: Design & Review Architecture

**Components used:** Sub-agents (`@architect`, `@database-designer`)

Use specialized agents for design and review tasks that benefit from isolated, focused context:

```
> @architect Review the current project structure and suggest improvements
> @architect Design a real-time notification system that works across Angular web and Flutter mobile using Firebase Cloud Messaging
> @database-designer Design the notification schema with PostgreSQL for persistence and Firestore for real-time delivery
```

### Exercise 8: Add a Feature End-to-End

**Components used:** Slash Command → all components in action

This is the real-world workflow — a single command that triggers scaffolding, skills, agents, and MCP servers working together:

```
> /add-feature User profile management — users can update their name, avatar, and preferences. Backend API + Angular settings page + Flutter profile screen
```

## 12. Claude Code Power Features

### Keyboard Shortcuts (Inside Claude Code)

| Shortcut | Action |
|----------|--------|
| `/help` | Show all available commands |
| `/clear` | Clear conversation context |
| `/compact` | Manually trigger context compaction |
| `/rewind` | Go back to a previous state |
| `/checkpoints` | File-level undo points |
| `/exit` | Exit Claude Code |
| `/agents` | List / create agents |
| `/mcp` | Check MCP server status |
| `!` | Quick bash command prefix |
| `@` | Search for files |
| `Tab` | Toggle thinking display |
| `Shift+Enter` | Multi-line input |
| `Ctrl+U` | Delete entire line (faster than backspace) |
| `Esc` | Cancel current generation |
| `Esc Esc` | Interrupt Claude / restore code |
| `/context` | View context usage as a colored grid |
| `/cost` | Show token usage statistics |
| `/stats` | Usage stats with date range (7/30/all-time) |
| `/usage` | View plan limits and usage |
| `/model` | Switch between models |
| `/plan` | Enter plan mode (Opus plans, Sonnet executes) |
| `/rename <name>` | Name the current session |
| `/resume <name>` | Resume a previous session by name or ID |
| `/review` | Request code review |
| `/doctor` | Run diagnostics |

### Essential CLI Flags

| Flag | What It Does | Example |
|---|---|---|
| `claude` | Start interactive session | `claude` |
| `claude --dangerously-skip-permissions` | Skip all permission prompts ⚠️ use with caution | For trusted CI environments only |
| `claude --continue` | Continue last session | `claude --continue` |
| `claude --resume` | Resume a specific session by ID or name | `claude --resume auth-refactor` |
| `claude --model <name>` | Use a specific model | `claude --model opus` |
| `claude --output-format json` | JSON output (useful for CI/CD pipelines) | `claude -p "run tests" --output-format json` |
| `claude --add-dir <path>` | Add extra working directories | `claude --add-dir ../frontend ../shared` |
| `claude --debug` | Enable debug logging | `claude --debug "api,mcp"` |

### Core Tools

These are the built-in tools Claude Code can use during a session:

| Tool | Purpose | Needs Permission |
|---|---|---|
| **Read** | Read files, images, PDFs | No |
| **Write** | Create new files | Yes |
| **Edit** | Modify existing files via exact string replacement | Yes |
| **Bash** | Execute shell commands | Yes |
| **Grep** | Search content with regex (ripgrep) | No |
| **Glob** | Find files by pattern | No |
| **Task** | Launch sub-agents | No |
| **TodoWrite** | Track multi-step task progress | No |
| **WebFetch** | Fetch and read web pages | Yes |
| **WebSearch** | Search the web | Yes |
| **LSP** | Go-to-definition, find references, hover docs | No |
| **NotebookRead** | Read Jupyter notebooks | No |
| **NotebookEdit** | Edit Jupyter notebooks | Yes |

### Permission Model

Claude Code uses an **allow / deny / ask** system. Common safe commands run without asking, sensitive files are blocked entirely, and everything else asks for confirmation.

Configure in `.claude/settings.json`:

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

This repo's `settings.json` comes pre-configured with sensible defaults.

## 13. Tips & Best Practices

### Prompting Best Practices

1. **Be specific** — The more context you give Claude, the better the output:

| ❌ Vague | ✅ Specific |
|---|---|
| "Add tests" | "Write Jest tests for `src/utils/date.ts` covering formatDate with valid dates, invalid inputs, and timezone handling" |
| "Fix the bug" | "Login fails when email contains `+`. Fix `src/auth/validate.ts:23` to handle plus signs in email addresses" |
| "Review this" | "Review `src/api/users.ts` for N+1 queries, missing error handling, and SQL injection risks" |
| "Make it faster" | "Profile the `/api/products` endpoint. Identify the slowest operation. Target: < 100ms response" |
| "Add auth" | "Add JWT auth to the Express API: login/register endpoints, middleware for protected routes, refresh tokens with 7-day expiry" |

2. **Use agents for focused work** — `@java-spring-api` gives you a specialized backend expert instead of a generalist

3. **Append `use context7`** to any prompt when you need current library docs — it fetches live documentation and prevents hallucinated APIs

4. **Resume sessions** — `claude -c` continues your last conversation, `claude --resume` lets you pick from recent sessions

5. **Chain commands in one prompt** — combine slash commands and natural language: `/scaffold-spring-api order-service then @java-spring-api add CRUD for Orders with items, totals, and status`

### @ File References

Reference files directly in prompts with `@`  — Claude reads them into context automatically, which is more token-efficient than reading entire directories:

```
> Review @src/auth/login.ts for security issues
> Compare @src/api/v1/users.ts and @src/api/v2/users.ts — what changed?
> Generate tests for @src/utils/validator.ts
> This bug is in @src/services/auth.ts, check @logs/error.log for clues
```

Works in both regular prompts and slash command arguments. Reduces token usage compared to reading entire directories.

### Context Window Management

Your 200K context window is your most precious resource. Mismanaging degrades performance and output quality.

| Problem | Impact | Fix |
|---------|--------|-----|
| Too many MCPs enabled | Each MCP's tool definitions eat context before you even start. 20+ MCPs can cut usable context from 200K to ~70K | Keep MCPs in config but disable unused ones — enable ≤ 10 servers / ≤ 80 tools at a time |
| Too many plugins active | Same issue — each plugin adds tool definitions | Install many, enable only 4–5 per project |
| Long sessions without compacting | Context fills up, Claude loses track of earlier work | Use `/compact` to manually trigger compaction, or let auto-compact handle it |
| Oversized CLAUDE.md | Goes into every prompt, crowding out actual task context | Keep < 300 lines or <40 KB , use progressive disclosure |

**Check your current state anytime:**

```
> /mcp                  # MCP status and tool count
> /plugins              # Enabled plugins
> /statusline           # Context remaining %
> /context              # Context usage as a colored grid
> /cost                 # Token usage statistics
```

### Parallel Workflows

Don't queue tasks — run them simultaneously:

| Technique | When to Use | How |
|---|---|---|
| **Sub-agents** | Independent subtasks within one session | Claude spawns multiple `@agents` that run in parallel with isolated context |
| **/fork** | Non-overlapping tasks in the same repo | Branches the conversation — each fork works independently |
| **Git worktrees** | Overlapping tasks that touch the same files | Each worktree is an independent checkout with its own Claude instance |
| **tmux** | Long-running commands (servers, test suites) | Claude runs in a tmux session you can detach and reattach |

**Note** sub-agents iscommonly used light-weight parallelism option — no git setup or terminal multiplexing needed, just spawn agents within the same session.

```bash
# Sub-agents — parallel specialists in one session
> @java-spring-api Build the auth endpoints
> @angular-spa Build the login page
> @database-designer Design the user schema
# Claude can run these concurrently without context collision
```

```bash
# /fork — branch the conversation
> /fork
# Fork 1: Add payment processing
# Fork 2: Add email notifications
# Each fork works independently in the same repo
```

```bash
# Git worktrees — parallel Claudes without conflicts
git worktree add ../feature-auth feature/auth
git worktree add ../feature-dashboard feature/dashboard
# Run separate `claude` instances in each directory
```

```bash
# tmux — monitor long-running tasks
tmux new -s dev
# Detach: Ctrl+B, D | Reattach: tmux attach -t dev
```

### Plugins Ecosystem

Beyond Claude-Mem, there's a growing plugin ecosystem. Plugins bundle tools, skills, agents, hooks, or MCP integrations for easy install.

```bash
# Install a plugin marketplace
> /plugin marketplace add <github-user/repo>

# Browse and install from /plugins menu
> /plugins
```

**Sample plugins:**

| Plugin | What It Does |
|--------|-------------|
| `typescript-lsp` | Real-time type checking + go-to-definition without an IDE |
| `hookify` | Create hooks by describing them in natural language |
| `context7` | Live documentation for any library |

> ⚠️ **Same context warning as MCPs** — each enabled plugin adds tool definitions. Install many, enable few.

### Writing a Good CLAUDE.md

Your `CLAUDE.md` is the **highest-leverage file** in the entire setup — it goes into every session and shapes every task. A bad line here gets into every plan, every implementation, every artifact Claude produces. Invest time crafting it carefully.

#### The Basics: WHAT → WHY → HOW

| Tell Claude... | Example |
|----------------|---------|
| **WHAT** — your project context, tech stack, rules, project structure | "Monorepo: `apps/api` (Spring Boot), `apps/web` (Angular), `packages/shared`" |
| **WHY** — the purpose of each part | "The `auth + gateway` service handles auth + rate-limiting for all downstream APIs" |
| **HOW** — how to work on the project | "Use `bun` not `npm`. Run tests with `./mvnw test`. Flyway migrations live in `db/migrations/`" |

#### Key Principles

| Principle | Why It Matters |
|-----------|---------------|
| **Less is more** | LLMs can reliably follow ~150–200 instructions. Claude Code's system prompt already uses ~50 of those. Every line you add competes for attention — keep only what's universally applicable. |
| **Claude may ignore irrelevant content** | Claude Code wraps your CLAUDE.md in a system reminder saying *"this may or may not be relevant."* If your file is full of niche instructions, Claude is more likely to skip all of them — not just the niche ones. |
| **Progressive disclosure** | Don't dump everything into CLAUDE.md. Keep domain-specific docs in separate files and reference them so Claude reads them only when needed (see example below). |
| **Don't use it as a linter** | Never send an LLM to do a linter's job. Use deterministic tools (ruff, Biome, ESLint) via Hooks instead. Style guidelines bloat your context and degrade instruction-following. |
| **Prefer pointers over copies** | Don't paste code snippets — they go stale. Point to `file:line` references so Claude reads the actual source of truth. |
| **Craft it by hand** | `/init` auto-generates a CLAUDE.md but includes too much irrelevant content. Use it as a starting point, then trim aggressively. |

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
- All code must pass `./mvnw verify` before committing
- Use conventional commits: feat|fix|docs|refactor(scope): message
- Never commit secrets or .env files
```

#### Quick Rules of Thumb

- **< 300 lines** or **<40 KB** is the general rule, shorter is better (some teams use < 60 lines)
- Most important rules go **at the top and bottom** — LLMs attend most to the start and end of context
- Use `CLAUDE.local.md` for personal preferences (auto-gitignored)
- Use `.claude/rules/` for conditional rules scoped to specific directories

## 14. Troubleshooting

### `command not found: claude`

Your shell can't find the Claude binary. Add it to your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### "Context too large" error

```
> /compact                          # Quick reset
> /compact "keep the auth work"     # Preserves specified context
```

**Prevention:** use `/compact` every ~50 operations in long sessions, or start a fresh session for new features.

### Edit tool fails with "string not found"
Claude's Edit tool requires an exact string match including whitespace and indentation. Fix:

```
> Read the file again to see exact content
```
If the string appears multiple times, provide more surrounding context for uniqueness.

### MCP server not connecting

Run `/mcp` to check status. 
```
> /mcp
```
Check the status output. Common fixes:
- Ensure `npx` is available (requires Node.js)
- For GitHub MCP, set your token: `export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token`
- Restart Claude Code after changing `.mcp.json`
- On Windows, MCP servers need a `cmd` wrapper: `"command": "cmd", "args": ["/c", "npx", "-y", "package-name"]`

### Claude isn't using skills or agents

- Verify the files exist: `ls .claude/agents/` and `ls .claude/skills/`
- Check that each file has valid YAML frontmatter (`---` delimiters)
- Try referencing explicitly: "Use the java-spring-api skill"

### Background task not responding
```
> /tasks          # or /bashes — check status
> /kill <id>      # Stop the stuck task
```

### Permission errors

Never use `sudo` with npm installs. Fix global permissions instead:

```bash
npm config set prefix ~/.npm-global
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Pre-configure allowed commands in `.claude/settings.json` to avoid repeated permission prompts.

### Run diagnostics

When something isn't working and you're not sure why:

```bash
claude doctor              # General health check
claude --debug             # Full debug logging
claude --debug "mcp"       # Debug a specific category
```

## 15. Resources

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