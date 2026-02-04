# Claude Code — Team Onboarding Kit

**Get your team from zero to productive with Claude Code in under 30 minutes.**

This repository is a pre-configured starter kit packed with agents, skills, slash commands, and MCP integrations — ready to go for the following tech stack:

| Layer | Technologies |
|---|---|
| **Backend** | Java 21, Spring Boot WebFlux v3.5.x, Node.js v24.13, NestJS v11.x, Python v3.13 |
| **Agentic AI** | Python 3.13, LangChain v1.2.8, LangGraph v1.0.7, FastAPI 0.128.x |
| **Frontend** | Angular 21.x, TypeScript 5.x |
| **Mobile** | Flutter 3.38, Dart 3.11 |
| **Data & Infra** | PostgreSQL, Firebase |
| **AI Tooling** | Claude Code, MCP servers |

Clone it, install Claude Code, and start building.

---

## Table of Contents

- [Claude Code — Team Onboarding Kit](#claude-code--team-onboarding-kit)
  - [Table of Contents](#table-of-contents)
  - [What is Claude Code?](#what-is-claude-code)
  - [1. Prerequisites](#1-prerequisites)
  - [2. Clone This Repo](#2-clone-this-repo)
  - [3. Set Up Your Editor (Install VS Code)](#3-set-up-your-editor-install-vs-code)
  - [4. Install Claude Code](#4-install-claude-code)
    - [Native Binary (Recommended)](#native-binary-recommended)
  - [5. First-time Using Claude Code](#5-first-time-using-claude-code)
  - [6. Install Claude-Mem (Persistent Memory) *(Optional)*](#6-install-claude-mem-persistent-memory-optional)
    - [What Claude-Mem Does](#what-claude-mem-does)
  - [7. Try It Out — Your First 5 Minutes](#7-try-it-out--your-first-5-minutes)
    - [Ask about the project](#ask-about-the-project)
    - [Scaffold something](#scaffold-something)
    - [Use a sub-agent](#use-a-sub-agent)
    - [Pull live docs with MCP](#pull-live-docs-with-mcp)
    - [Check what's loaded](#check-whats-loaded)
    - [A note on permissions](#a-note-on-permissions)
    - [Slash Commands — Reusable Prompt Shortcuts](#slash-commands--reusable-prompt-shortcuts)
    - [Agents (Subagents) — Specialist AI Personas](#agents-subagents--specialist-ai-personas)
    - [Skills — Auto-Activated Knowledge](#skills--auto-activated-knowledge)
    - [MCP Servers — External Tool Integrations](#mcp-servers--external-tool-integrations)
    - [settings.json Configuration](#settingsjson-configuration)
    - [Hooks — Automated Guardrails](#hooks--automated-guardrails)
    - [Model Selection \& Cost Awareness](#model-selection--cost-awareness)
  - [8. What Gets Sent to the LLM?](#8-what-gets-sent-to-the-llm)
    - [Context Window Anatomy](#context-window-anatomy)
    - [What Each Layer Contains](#what-each-layer-contains)
    - [Key Takeaways](#key-takeaways)
  - [9. What's in This Repo](#9-whats-in-this-repo)
    - [MCP Servers (`.mcp.json`)](#mcp-servers-mcpjson)
  - [10. Hands-On Exercises](#10-hands-on-exercises)
    - [Exercise 1: Scaffold a Flutter Fitness App](#exercise-1-scaffold-a-flutter-fitness-app)
    - [Exercise 2: Build a Weather REST API (Java)](#exercise-2-build-a-weather-rest-api-java)
    - [Exercise 3: Build a Todo API (NestJS)](#exercise-3-build-a-todo-api-nestjs)
    - [Exercise 4: Build an Analytics API (Python)](#exercise-4-build-an-analytics-api-python)
    - [Exercise 5: Design a Full-Stack E-Commerce System](#exercise-5-design-a-full-stack-e-commerce-system)
    - [Exercise 6: Pull Live Docs with Context7 (MCP)](#exercise-6-pull-live-docs-with-context7-mcp)
    - [Exercise 7: Design \& Review Architecture](#exercise-7-design--review-architecture)
    - [Exercise 8: Build an AI Agent Service (Agentic AI)](#exercise-8-build-an-ai-agent-service-agentic-ai)
    - [Exercise 9: Domain-Driven Design with DDD Architect](#exercise-9-domain-driven-design-with-ddd-architect)
    - [Exercise 10: Add a Feature End-to-End](#exercise-10-add-a-feature-end-to-end)
    - [What's Next?](#whats-next)
  - [11. Security Considerations](#11-security-considerations)
    - [What Goes to Anthropic's API](#what-goes-to-anthropics-api)
    - [MCP Server Credentials](#mcp-server-credentials)
    - [The `--dangerously-skip-permissions` Flag](#the---dangerously-skip-permissions-flag)
    - [Pre-configured Guardrails in This Kit](#pre-configured-guardrails-in-this-kit)
    - [Checklist Before Using Claude Code on a Real Project](#checklist-before-using-claude-code-on-a-real-project)
  - [12. Customizing the Kit](#12-customizing-the-kit)
    - [Adding a New Agent](#adding-a-new-agent)
    - [Adding a New Slash Command](#adding-a-new-slash-command)
    - [Adding a New Skill](#adding-a-new-skill)
    - [Adding a New Hook](#adding-a-new-hook)
    - [Removing Components You Don't Need](#removing-components-you-dont-need)
    - [Version Update Guide](#version-update-guide)
  - [13. Claude Code Power Features](#13-claude-code-power-features)
    - [Keyboard Shortcuts (Inside Claude Code)](#keyboard-shortcuts-inside-claude-code)
    - [Essential CLI Flags](#essential-cli-flags)
    - [Core Tools](#core-tools)
    - [Permission Model](#permission-model)
  - [14. Tips \& Best Practices](#14-tips--best-practices)
    - [Prompting Best Practices](#prompting-best-practices)
    - [Common Pitfalls — Avoid These](#common-pitfalls--avoid-these)
    - [@ File References](#-file-references)
    - [Context Window Management](#context-window-management)
    - [Parallel Workflows](#parallel-workflows)
    - [Team Collaboration Patterns](#team-collaboration-patterns)
    - [Plugins Ecosystem](#plugins-ecosystem)
    - [Skills — Best Practices](#skills--best-practices)
    - [Writing a Good CLAUDE.md](#writing-a-good-claudemd)
      - [The Basics: WHAT → WHY → HOW](#the-basics-what--why--how)
      - [Key Principles](#key-principles)
      - [Progressive Disclosure Example](#progressive-disclosure-example)
      - [Quick Rules of Thumb](#quick-rules-of-thumb)
    - [When Claude Ignores Its Rules](#when-claude-ignores-its-rules)
      - [Start-of-Task Prompt](#start-of-task-prompt)
      - [When Claude Guesses Instead of Verifying](#when-claude-guesses-instead-of-verifying)
      - [When Claude Flip-Flops](#when-claude-flip-flops)
      - [When Challenging Claude's Analysis](#when-challenging-claudes-analysis)
  - [15. Troubleshooting](#15-troubleshooting)
    - [`command not found: claude`](#command-not-found-claude)
    - ["Context too large" error](#context-too-large-error)
    - [Edit tool fails with "string not found"](#edit-tool-fails-with-string-not-found)
    - [MCP server not connecting](#mcp-server-not-connecting)
    - [Claude isn't using skills or agents](#claude-isnt-using-skills-or-agents)
    - [Background task not responding](#background-task-not-responding)
    - [Permission errors](#permission-errors)
    - [Windows-Specific Setup](#windows-specific-setup)
    - [Run diagnostics](#run-diagnostics)
  - [16. Quick Reference Card](#16-quick-reference-card)
    - [Commands You'll Use Every Day](#commands-youll-use-every-day)
    - [Scaffolding](#scaffolding)
    - [Design \& Review](#design--review)
    - [Agents (use @name)](#agents-use-name)
    - [Keyboard Shortcuts](#keyboard-shortcuts)
    - [MCP Tips](#mcp-tips)
  - [17. Resources](#17-resources)

---

## What is Claude Code?

**[Claude Code](https://code.claude.com/docs/en/overview)** is an **agentic AI coding assistant that lives in your terminal**. It understands your codebase, edits files, runs commands, and writes code — all through natural language.

Think of it as a senior developer pair-programming with you who knows your entire project, follows your team's conventions, and never gets tired.

## 1. Prerequisites

Before you begin, make sure you have:

- **A Claude subscription** — Claude Pro or Max at [claude.ai](https://claude.ai), or an Anthropic API key from the [Console](https://console.anthropic.com)

**Optional for Quick Start (required for MCP servers):**

- [Node.js v24+](https://nodejs.org/en/download)
- [Python v3.13+](https://www.python.org/downloads/)

## 2. Clone This Repo

This repo is your playground — use it to learn and practice Claude Code (Agentic AI coding assistant) and get familiar with its components (agents, skills, slash commands, hooks, MCP servers, memory) so you can automate your development workflow.

**Option A: Learn & Explore (recommended for first-timers)**

Clone the full repo and work through the exercises:
```bash
git clone https://github.com/kumaran-is/claude-code-onboarding.git
cd claude-code-onboarding
```

**Option B: Adopt into an Existing Project**

Already have a project? Copy just the Claude Code configuration into it:
```bash
# From the cloned repo, copy the config into your project
cp -r claude-code-onboarding/.claude/ your-project/.claude/
cp claude-code-onboarding/CLAUDE.md your-project/
cp claude-code-onboarding/.mcp.json your-project/

# Then customize for your project
cd your-project
```

After copying, you'll want to:
1. Edit `CLAUDE.md` — replace the tech stack and conventions with your project's
2. Edit `.claude/settings.json` — adjust `permissions.allow` for your build tools (e.g., remove `flutter` if you don't use it)
3. Edit `.mcp.json` — remove MCP servers you don't need, add project-specific ones
4. Remove agents/skills/commands for stacks you don't use
5. Run `chmod +x .claude/hooks/*.sh` to make hooks executable

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
This can feel repetitive at first. The kit ships with pre-configured `allow` rules in `.claude/settings.json` that auto-approve common operations (build tools, git, Docker) — so most prompts you'll see are for operations that genuinely deserve a second look.

> ⚠️ **For this learning playground only**, you can skip all permission prompts:
> ```bash
> claude --dangerously-skip-permissions
> ```
> **Do not use this in real projects.** It disables all guardrails including the hooks and deny rules this kit ships with. For real projects, add frequently-used commands to the `allow` list in `settings.json` instead — see the [Settings Configuration](#settingsjson-configuration) section for the full reference.
```

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
| **Skill** | Auto-apply patterns for a domain | Always use Riverpod State Management when building Flutter |
| **Slash Command** | Run a repeatable prompt yourself(manual) | `/scaffold-spring-api weather-service` |
| **Sub-agent** | Get deep domain expertise in isolation, can be manual or auto | `@database-designer Design schema for…` |
| **Hook** | Enforce hard rules every time | Block commits without passing tests |
| **MCP Server** | Connect to external services | GitHub PRs, Context7 live docs, Firebase |
| **Claude-Mem plugin** | Remember things across sessions | Persistent memory of past decisions |

### CLAUDE.md (Project Context)

**What:** A Markdown file at the project root that gives Claude Code, context about your project — tech stack, conventions, common commands, architecture, and rules.

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

**File Locations & Priority**

| Type | Location | Scope | Git |
|------|----------|-------|-----|
| Enterprise | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) | All users in org | N/A |
| User Global | `~/.claude/CLAUDE.md` | All your projects | No |
| Project | `./CLAUDE.md` | Team-shared | Yes |
| Project Local | `./CLAUDE.local.md` | Personal (your machine) | No (auto-ignored) |
| Directory-specific | `./src/api/CLAUDE.md` | Subdirectory scope | Yes |
| Rules Directory | `.claude/rules/*.md` | Conditional rules | Yes |


### Slash Commands — Reusable Prompt Shortcuts

**What:** Prompts you trigger with `/command-name`. Think of them as reusable prompt shortcuts.

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

**What:** Specialized AI with isolated context for complex tasks with their own system prompt and tool restrictions. They run in a **separate context window**, so they don't pollute your main conversation.

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

**What:** Markdown files with domain knowledge, templates, and code patterns. Unlike commands, Skills are *lazy-loaded* and only brought into context when needed. **Claude decides when to use them** based on the task context — you don't invoke them explicitly.

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

### settings.json Configuration

**Purpose**: Permissions, environment variables, hooks, and tool behavior.

**File Locations & Priority**

| Type | Location | Scope |
|------|----------|-------|
| User | `~/.claude/settings.json` | All projects |
| Project (shared) | `.claude/settings.json` | Team-shared |
| Project (local) | `.claude/settings.local.json` | Personal |
| Enterprise | OS-specific managed location | Organization |

**Permission Rule Syntax**

| Pattern | Example | Description |
|---------|---------|-------------|
| Exact match | `Bash(npm run test)` | Only this exact command |
| Wildcard suffix | `Bash(npm run:*)` | npm run followed by anything |
| Glob patterns | `Read(./src/**/*.ts)` | All .ts files recursively |
| Tool types | `Read`, `Write`, `Edit`, `Bash`, `WebFetch`, `WebSearch` | Tool categories |

**Key design decisions:**
This kit ships with a pre-configured `settings.json` that balances safety with productivity.

| Category | What's Configured | Why |
|----------|-------------------|-----|
| **Allow** | Build tools (`npm`, `mvn`, `flutter`, `ng`), git read/write, Docker, Python tooling | These run frequently — prompting every time kills productivity |
| **Ask** | Destructive file ops (`rm`, `mv`, `cp`), `curl`/`wget`, git reset | One-time confirmation prevents accidents without blocking workflow |
| **Deny** | Force-push, `sudo`, `eval`, reading `.env`/secrets/keys | Never allowed — these are hard guardrails |
| **Env** | `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | Keeps Claude in the project root instead of drifting to `/home/user` |

> **Note:** This uses the **array-style permission syntax** (e.g., `"Bash(npm *)"`) which is the current format. If you see older examples with object-style syntax (`"Bash": ["npm *"]`), those are outdated.

To add your own project-specific permissions, modify `.claude/settings.json` or create a personal `.claude/settings.local.json` for overrides that aren't committed to git.

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

> **Note:** `SessionStart`, `SessionEnd`, `SubagentStop`, `PreCompact`, and `PermissionRequest` hooks were added in recent Claude Code releases. If a hook event doesn't fire, verify your Claude Code version with `claude --version` and update if needed. The core events (`PreToolUse`, `PostToolUse`, `Stop`) are available in all versions.

This repo includes 4 hooks out of the box:

| Hook | Script | Event | What It Does |
|------|--------|-------|-------------|
| **Bash Guard** | `pre-bash-guard.sh` | `PreToolUse` → Bash | Blocks `rm -rf /`, `rm -rf .`, force-push to main, `DROP DATABASE` |
| **Protect Sensitive Files** | `pre-edit-protect-sensitive.sh` | `PreToolUse` → Write/Edit | Blocks edits to `.env`, credentials, private keys, lock files |
| **Auto-Format** | `post-edit-format.sh` | `PostToolUse` → Write/Edit | Runs Prettier (TS/JS/HTML/CSS), `dart format`, ruff/black (Python) |
| **Secret Scan** | `stop-secret-scan.sh` | `Stop` | Warns if changed files contain AWS/GCP/GitHub/OpenAI API keys |

> After cloning: `chmod +x .claude/hooks/*.sh`

> **Tip:** Install the `hookify` plugin to create hooks conversationally — run `/hookify` and describe what you want in plain English.

### Model Selection & Cost Awareness

This kit uses two model tiers strategically:

| Model | Used By | When | Why |
|-------|---------|------|-----|
| **Sonnet** | Dev agents (`java-spring-api`, `angular-spa`, `flutter-mobile`, etc.) | Writing code, scaffolding, implementing features | Fast, cost-effective, excellent for code generation |
| **Opus** | Review agents (`spring-reactive-reviewer`, `nestjs-reviewer`, `security-reviewer`, etc.) | Code review, security audits, architecture review | Deeper reasoning, catches subtle bugs, better at nuanced analysis |

**Switching models mid-session:**

```
> /model                    # See current model and switch
> /model sonnet             # Switch to Sonnet for implementation work
> /model opus               # Switch to Opus for complex debugging
```

**Cost monitoring:**

```
> /cost                     # Token usage and estimated cost for this session
> /stats                    # Usage stats over 7/30 days or all-time
> /usage                    # Plan limits and remaining usage
```

**Cost-saving tips:**
- Use `/compact` regularly in long sessions — stale context wastes tokens
- Use `@file` references instead of pasting file contents — it's more token-efficient
- Disable MCP servers you're not actively using (`/mcp` to check)
- For simple tasks, Sonnet is sufficient — save Opus for reviews and complex reasoning

## 8. What Gets Sent to the LLM?

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

## 9. What's in This Repo

**76 components** — 20 skills, 13 commands, 20 agents, 4 rules, 4 hooks, 12 MCP servers, 2 settings files, 1 CLAUDE.md.

```
claude-code-onboarding/
├── CLAUDE.md                            # Project instructions — tech stack, conventions, rules
├── .mcp.json                            # 12 MCP servers (see table below)
├── .gitignore
├── README.md                            # ← You are here
│
└── .claude/
    ├── settings.json                    # Permissions (allow/ask/deny) and hook configs
    ├── settings.local.json              # Personal overrides (gitignored)
    │
    ├── rules/                            # Always-loaded behavioral guidelines
    │   ├── code-standards.md             # Error handling, DRY, logging, output quality
    │   ├── core-behaviors.md             # Assumptions, confusion management, simplicity
    │   ├── leverage-patterns.md          # Task protocol, test-first, naive-then-optimize
    │   └── verification-and-reporting.md # Verify before claiming, honest status reporting
    │
    ├── hooks/                            # Lifecycle hook scripts (chmod +x after cloning)
    │   ├── pre-bash-guard.sh             # Block destructive bash commands (rm -rf, DROP, etc.)
    │   ├── pre-edit-protect-sensitive.sh  # Block edits to .env, keys, lock files
    │   ├── post-edit-format.sh           # Auto-format TS/JS/Dart/Python after edits
    │   └── stop-secret-scan.sh           # Scan changed files for leaked secrets on stop
    │
    ├── agents/                           # 20 specialist AI personas (invoke with @name)
    │   │
    │   │  # — Development agents (model: sonnet) —
    │   ├── java-spring-api.md            # Spring Boot WebFlux expert
    │   ├── nestjs-api.md                 # NestJS / Fastify / Prisma expert
    │   ├── python-dev.md                 # Python / FastAPI expert
    │   ├── agentic-ai-dev.md             # LangChain / LangGraph AI agent builder
    │   ├── angular-spa.md                # Angular frontend expert
    │   ├── flutter-mobile.md             # Flutter mobile expert
    │   ├── frontend-design.md            # Creative UI/UX design specialist
    │   ├── database-designer.md          # PostgreSQL + Firestore architect
    │   ├── architect.md                  # Solution architect
    │   ├── flutter-security-expert.md    # Mobile security & privacy compliance
    │   │
    │   │  # — Review agents (model: opus) —
    │   ├── code-reviewer.md              # General code quality & review
    │   ├── nestjs-reviewer.md            # NestJS code review specialist
    │   ├── spring-reactive-reviewer.md   # Spring WebFlux review specialist
    │   ├── agentic-ai-reviewer.md        # Agentic AI code review specialist
    │   ├── security-reviewer.md          # Security vulnerability reviewer
    │   ├── postgresql-database-reviewer.md # PostgreSQL performance & schema reviewer
    │   │
    │   │  # — Specialist agents —
    │   ├── accessibility-auditor.md      # WCAG / a11y compliance auditor
    │   ├── riverpod-reviewer.md          # Flutter Riverpod state management reviewer
    │   ├── dedup-code-agent.md           # Dead code & duplication detector
    │   └── ui-standards-expert.md        # UI consistency & design system enforcement
    │
    ├── commands/                          # 13 slash commands (triggered with /name)
    │   │
    │   │  # — Scaffolding —
    │   ├── scaffold-spring-api.md        # /scaffold-spring-api <name>
    │   ├── scaffold-nestjs-api.md        # /scaffold-nestjs-api <name>
    │   ├── scaffold-python-api.md        # /scaffold-python-api <name>
    │   ├── scaffold-agentic-ai.md        # /scaffold-agentic-ai <name>
    │   ├── scaffold-angular-app.md       # /scaffold-angular-app <name>
    │   ├── scaffold-flutter-app.md       # /scaffold-flutter-app <name>
    │   │
    │   │  # — Design —
    │   ├── design-database.md            # /design-database <domain description>
    │   ├── design-architecture.md        # /design-architecture <system description>
    │   │
    │   │  # — Workflow —
    │   ├── add-feature.md                # /add-feature <feature description>
    │   ├── review-code.md                # /review-code [focus area]
    │   ├── audit-security.md             # /audit-security [scope]
    │   ├── status-check.md               # /status-check — binary works/broken report
    │   └── project-status.md             # /project-status — codebase summary
    │
    └── skills/                            # 20 auto-activated domain knowledge skills
        │
        │  # — Backend skills —
        ├── java-spring-api/              # Spring Boot 3.5.x: entity patterns, resilience (Resilience4j),
        │                                 # testing (WebTestClient, Testcontainers), security hardening,
        │                                 # reactive debugging, Redis/SSE patterns (9 reference files)
        ├── java-coding-standard/         # Java naming, immutability, records, sealed types (1 reference file)
        ├── nestjs-api/                   # NestJS 11.x: module structure, Prisma 7.x, config management,
        │                                 # circuit breakers, feature flags, messaging (BullMQ/RabbitMQ/Kafka),
        │                                 # REST controllers, security, debugging, testing (23 reference files)
        ├── nestjs-coding-standard/       # NestJS naming, module patterns, DTO conventions (1 reference file)
        ├── python-dev/                   # Python 3.13: FastAPI patterns, Pydantic v2, async SQLAlchemy,
        │                                 # pytest fixtures, ruff/mypy config (1 reference file)
        │
        │  # — Agentic AI skills —
        ├── agentic-ai-dev/               # LangChain/LangGraph: ReAct agents, RAG (standard/agentic/self-RAG),
        │                                 # tool definitions, multi-provider LLM routing, guardrails,
        │                                 # prompt injection detection, PII redaction (17 reference files)
        ├── agentic-ai-coding-standard/   # Agentic AI naming, TypedDict state, async patterns (1 reference file)
        │
        │  # — Frontend & mobile skills —
        ├── angular-spa/                  # Angular 21.x: standalone components, signals, control flow,
        │                                 # TailwindCSS 4.x + daisyUI 5.x setup, zoneless testing,
        │                                 # accessibility checklist, troubleshooting (12 reference files)
        ├── flutter-mobile/               # Flutter 3.38: clean architecture layers, Riverpod 3.x,
        │                                 # Freezed models, GoRouter, Firebase integration (2 reference files)
        ├── riverpod-patterns/            # Riverpod: AsyncNotifier, AsyncValue.when, ref.watch vs ref.read,
        │                                 # family providers, lifecycle management (1 reference file)
        ├── ui-standards-tokens/          # Design tokens: spacing scale, color system, typography,
        │                                 # elevation, touch targets, responsive breakpoints (2 reference files)
        │
        │  # — Architecture & design skills —
        ├── architecture-design/          # C4 diagrams, API contracts, sequence diagrams,
        │                                 # deployment topology, ADR templates (1 reference file)
        ├── architecture-decision-records/ # ADR lifecycle, templates, status tracking (3 reference files)
        ├── database-schema-designer/     # PostgreSQL schema: normalization, Flyway migrations,
        │                                 # Firestore collections, indexing strategy, ERDs (7 reference files)
        ├── ddd-architect/                # Domain-Driven Design: bounded contexts, aggregates,
        │                                 # context mapping, event storming, strategic/tactical design (4 reference files)
        ├── openapi-spec-generation/      # OpenAPI 3.1: schema generation, path definitions,
        │                                 # security schemes, examples, validation (5 reference files)
        │
        │  # — Tooling skills —
        ├── mcp-builder/                  # MCP server development: Python (FastMCP) and Node.js (MCP SDK),
        │                                 # tool definitions, transport config (18 reference files + scripts)
        ├── playwright-skill/             # E2E testing: page objects, test fixtures, assertions,
        │                                 # CI configuration (3 reference files + runtime)
        ├── domain-finder/                # Domain name availability checking via WHOIS (1 reference file)
        └── changelog-generator/          # Git history parsing, semantic versioning,
                                          # release notes generation (1 reference file)
```

### MCP Servers (`.mcp.json`)

| Server | Transport | Purpose |
|--------|-----------|---------|
| `github` | HTTP | GitHub API — issues, PRs, code search |
| `langchain-docs` | HTTP | LangChain documentation search |
| `angular-cli` | stdio | Angular CLI operations |
| `chrome-devtools` | stdio | Browser automation & DevTools |
| `context7` | stdio | Live documentation for any library |
| `dart-mcp-server` | stdio | Dart/Flutter tooling daemon |
| `firebase` | stdio | Firebase CLI operations |
| `postgres` | stdio | PostgreSQL query & schema tools |
| `playwright` | stdio | Browser testing automation |
| `docker` | stdio | Docker container management |
| `ios-simulator` | stdio | iOS simulator control |
| `maestro` | stdio | Mobile UI testing framework |

## 10. Hands-On Exercises

Work through these exercises to get familiar with Claude Code. Each one uses different components from this kit.
These exercises follow a deliberate progression to help you understand **which component to use for and when**:

| Exercises | Focus | Components Introduced |
|-----------|-------|----------------------|
| **1–4** | Single-stack scaffolding | Slash Commands, Skills (auto), Agents |
| **5** | Multi-stack integration | Chaining commands + agents across layers |
| **6** | External tooling | MCP Servers (Context7) |
| **7** | Design & review | Review agents, architecture patterns |
| **8** | AI agent development | Agentic AI stack, advanced agent patterns |
| **9** | Domain modeling | DDD skill, cross-cutting analysis |
| **10** | Full workflow | All components working together |

**Exercises 1–4 are independent** — do them in any order based on your stack. **Exercises 5+** build on concepts from earlier exercises, so work through them sequentially.

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

### Exercise 3: Build a Todo API (NestJS)

**Components used:** Slash Command → Sub-agent

```
> /scaffold-nestjs-api todo-service
> @nestjs-api Add a Todo feature module with CRUD endpoints, Prisma model, DTO validation, and service
> Add Vitest integration tests for create and list endpoints
> Add a PATCH endpoint to mark todos as complete
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
> Create a NestJS guard with JWT validation using @nestjs/passport. use context7
```

### Exercise 7: Design & Review Architecture

**Components used:** Sub-agents (`@architect`, `@database-designer`)

Use specialized agents for design and review tasks that benefit from isolated, focused context:

```
> @architect Review the current project structure and suggest improvements
> @architect Design a real-time notification system that works across Angular web and Flutter mobile using Firebase Cloud Messaging
> @database-designer Design the notification schema with PostgreSQL for persistence and Firestore for real-time delivery
```

### Exercise 8: Build an AI Agent Service (Agentic AI)

**Components used:** Slash Command → Sub-agent → Skill (auto) → MCP Server

Scaffold a production AI agent service, then build out a ReAct agent with RAG and tools:

```
> /scaffold-agentic-ai research-agent
> @agentic-ai-dev Add a web search tool and a database query tool with Pydantic input validation
> @agentic-ai-dev Build an Agentic RAG system with query routing, document grading, and web search fallback
> @agentic-ai-dev Add guardrails — prompt injection detection, PII redaction, and output validation
> @agentic-ai-dev Write tests for the ReAct agent: basic invoke, tool usage, iteration limit, and error recovery
```

Then review your work:

```
> @agentic-ai-reviewer Review the agent service for graph correctness, safety, cost, and production readiness
```

### Exercise 9: Domain-Driven Design with DDD Architect

**Components used:** Skill (ddd-architect) → Sub-agents (`@architect`, `@database-designer`)

Use the DDD Architect skill to decompose a complex domain into bounded contexts, aggregates, and integration patterns — then hand off to implementation agents:

```
> Perform a full DDD analysis for an online food delivery platform. The system handles restaurant menus, customer ordering, real-time delivery tracking, payments, ratings and reviews, and a loyalty program. Tech stack: Spring Boot microservices, Angular web, Flutter mobile, PostgreSQL, Firebase for real-time.
```

Claude activates the `ddd-architect` skill automatically and walks through strategic → tactical → technical phases. Follow up to drill deeper:

```
> Show me the context map with all integration patterns between Order, Delivery, and Payment contexts
> Design the Order aggregate with invariants — what rules must hold when placing, modifying, or cancelling an order?
> Which contexts should communicate via domain events vs. synchronous API calls? Justify each.
> Generate the implementation roadmap — which bounded contexts should we build first and why?
```

Then use the outputs to drive implementation:

```
> @database-designer Design the PostgreSQL schema for the Order bounded context based on the DDD tactical design
> @architect Design the event-driven integration between Order, Payment, and Delivery contexts using the context map
```

### Exercise 10: Add a Feature End-to-End

**Components used:** Slash Command → all components in action

This is the real-world workflow — a single command that triggers scaffolding, skills, agents, and MCP servers working together:

```
> /add-feature User profile management — users can update their name, avatar, and preferences. Backend API + Angular settings page + Flutter profile screen
```

### What's Next?

You've used every component in the kit — agents, skills, commands, hooks, and MCP servers. Now apply it to your own project:

1. **Copy the config** into your project (Option B from [Section 2](#2-clone-this-repo)):
   ```bash
   cp -r .claude/ your-project/.claude/
   cp CLAUDE.md your-project/
   cp .mcp.json your-project/
   ```
2. **Trim what you don't need** — remove agents, skills, and commands for stacks you don't use. See [Removing Components You Don't Need](#removing-components-you-dont-need) in the Customization section
3. **Write your own CLAUDE.md** — replace the tech stack, conventions, and rules with your project's. See [Writing a Good CLAUDE.md](#writing-a-good-claudemd) for principles
4. **Set up credentials** — copy `.env.example` to `.env`, configure MCP server tokens as environment variables
5. **Verify** — run Claude Code and check that everything loads:
   ```
   > /project-status
   > /mcp
   > What agents and skills are available?
   ```
6. **Iterate** — your CLAUDE.md and skills will evolve as you discover what works for your team. Treat them like living documentation — PR-reviewed and version-controlled
   
## 11. Security Considerations

Before using Claude Code with real projects, understand the security boundaries.

### What Goes to Anthropic's API

Every prompt, file content pulled via `@file` references, and tool outputs are sent to Anthropic's API for processing. This means:

- **Never paste real API keys, passwords, or tokens into prompts** — they'll be transmitted to Anthropic's servers
- **Be cautious with `@file` references to sensitive files** — the file contents are sent as part of the prompt
- **Tool outputs (Bash, Read, etc.) are included in context** — if a command outputs secrets, they're sent too

### MCP Server Credentials

MCP servers like `postgres` and `github` require connection strings or tokens. Handle these safely:

```bash
# ✅ GOOD — credentials from environment variables
# .mcp.json
"args": ["${POSTGRES_CONNECTION_STRING}"]

# ❌ BAD — credentials hardcoded in .mcp.json
"args": ["postgresql://admin:password123@localhost:5432/mydb"]
```

Always use environment variable references (`${VAR_NAME}`) in `.mcp.json` — never hardcode credentials.

### The `--dangerously-skip-permissions` Flag

This flag disables all permission prompts. Rules for safe usage:

| Environment | Safe to Use? | Why |
|-------------|-------------|-----|
| Local dev, throwaway project | ✅ Yes | Low risk, easy to reset |
| Local dev, real project | ⚠️ Caution | Claude can modify/delete files without asking |
| CI/CD pipeline | ❌ No | Automated environment with real credentials and deployment access |
| Shared/team machine | ❌ No | Other users' files and credentials may be accessible |

### Pre-configured Guardrails in This Kit

This repo includes 4 hooks that enforce security automatically:

| Hook | What It Prevents |
|------|-----------------|
| `pre-bash-guard.sh` | `rm -rf /`, force-push to main, `DROP DATABASE`, piping curl to shell |
| `pre-edit-protect-sensitive.sh` | Direct edits to `.env`, private keys, credentials, lock files |
| `stop-secret-scan.sh` | Warns if changed files contain AWS/GCP/GitHub/Stripe/Anthropic API key patterns |
| `post-edit-format.sh` | Not security-related, but auto-formats to prevent malformed code commits |

These hooks are **defense-in-depth** — they catch mistakes but aren't a substitute for proper secret management. Always use a secrets manager (AWS Secrets Manager, HashiCorp Vault, 1Password CLI) for production credentials.

### Checklist Before Using Claude Code on a Real Project

- [ ] No real secrets in `.mcp.json` — all use `${ENV_VAR}` references
- [ ] `.env` files are in `.gitignore`
- [ ] `settings.json` denies access to credential files (pre-configured in this kit)
- [ ] Team members understand what gets sent to Anthropic's API
- [ ] CI/CD pipelines do NOT use `--dangerously-skip-permissions`
- [ ] Hook scripts are executable (`chmod +x .claude/hooks/*.sh`)

## 12. Customizing the Kit

This kit is a starting point — customize it for your team's stack and workflows.

### Adding a New Agent

Create a file in `.claude/agents/` with YAML frontmatter:

```markdown
---
name: my-agent
description: One-line description of when to use this agent. Claude reads this to decide when to activate it.
model: sonnet
tools: Bash, Read, Write, Edit, Glob, Grep
skills:
  - my-related-skill
---

# My Agent Name

You are a [role] specializing in [domain].

## Your Responsibilities
1. First responsibility
2. Second responsibility

## How to Work
1. Read the `my-related-skill` skill before writing code
2. Follow [specific conventions]

## Key Rules
- Rule 1
- Rule 2
```

**Usage:** `@my-agent Do something specific`

### Adding a New Slash Command

Create a file in `.claude/commands/` with YAML frontmatter:

```markdown
---
description: What this command does (shown in /help)
argument-hint: "[parameter description]"
allowed-tools: Bash, Read, Write, Edit
---

# Command Title

**Input:** $ARGUMENTS

## Steps
1. First step — explain what to do
2. Second step — reference skills or agents if needed
3. Final step — verify and report

Use the `my-skill` skill for patterns and templates.
```

**Usage:** `/my-command some argument here`

**Key notes:**
- `$ARGUMENTS` is replaced with whatever the user types after the command name
- `argument-hint` shows up in autocomplete to guide the user
- `allowed-tools` restricts which tools the command can use
- Add `disable-model-invocation: true` to prevent the command from using sub-agents

### Adding a New Skill

Create a directory in `.claude/skills/` with a `SKILL.md` file:

```
.claude/skills/my-skill/
├── SKILL.md                    # Entry point (keep under 5KB)
└── reference/                  # Detailed docs loaded on-demand
    ├── templates.md            # Code templates
    ├── patterns.md             # Design patterns
    └── troubleshooting.md      # Common issues and fixes
```

**SKILL.md structure:**

```markdown
---
name: my-skill
description: |
  Use this skill when the user asks about [domain].
  Triggers: [list of keywords or contexts that activate this skill].
---

# My Skill

## Overview
What this skill covers and when it applies.

## Quick Reference
| Task | Pattern |
|------|---------|
| Common task 1 | Brief pattern |
| Common task 2 | Brief pattern |

## Detailed References
When working on [specific task]:
→ Read `reference/templates.md` for code templates

When troubleshooting:
→ Read `reference/troubleshooting.md`
```

**Key notes:**
- Keep `SKILL.md` under 5KB — it loads into context when activated
- Put detailed content in `reference/` files — they load on-demand, saving tokens
- The `description` field is critical — Claude uses it to decide when to activate the skill
- Skills activate automatically based on context. Users don't invoke them directly

### Adding a New Hook

1. Create the script in `.claude/hooks/`:

```bash
#!/usr/bin/env bash
# Brief description of what this hook does
set -uo pipefail

# Read tool input from stdin
input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null) || file=""

# Your logic here
# Exit 0 = allow/pass, Exit 2 = block (message via stderr)

exit 0
```

2. Make it executable:

```bash
chmod +x .claude/hooks/my-hook.sh
```

3. Register it in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/my-hook.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**Hook events and matchers:**

| Event | Matcher | Use Case |
|-------|---------|----------|
| `PreToolUse` | `Bash`, `Write`, `Edit`, `WebFetch` | Block dangerous operations before they happen |
| `PostToolUse` | `Write`, `Edit` | Auto-format, lint, or validate after changes |
| `Stop` | *(no matcher)* | Run tests, scan for secrets when Claude finishes |
| `UserPromptSubmit` | *(no matcher)* | Enrich or validate user prompts before processing |

### Removing Components You Don't Need

If your team doesn't use a particular stack, remove the corresponding files to reduce noise:

```bash
# Example: Remove Flutter-related components if you don't use Flutter
rm .claude/agents/flutter-mobile.md
rm .claude/agents/flutter-security-expert.md
rm .claude/agents/riverpod-reviewer.md
rm .claude/agents/accessibility-auditor.md
rm .claude/agents/ui-standards-expert.md
rm -rf .claude/skills/flutter-mobile/
rm -rf .claude/skills/riverpod-patterns/
rm -rf .claude/skills/ui-standards-tokens/
rm .claude/commands/scaffold-flutter-app.md

# Update CLAUDE.md to remove Flutter references from the tech stack table
```

Also disable unused MCP servers in `.mcp.json` by setting `"disabled": true`.

### Version Update Guide

When a framework releases a new major version, update these files:

| To Update... | Edit These Files |
|---|---|
| Angular version | `CLAUDE.md` (tech stack), `.claude/skills/angular-spa/SKILL.md`, `.claude/agents/angular-spa.md` |
| Spring Boot version | `CLAUDE.md`, `.claude/skills/java-spring-api/SKILL.md`, `.claude/agents/java-spring-api.md` |
| NestJS version | `CLAUDE.md`, `.claude/skills/nestjs-api/SKILL.md`, `.claude/agents/nestjs-api.md` |
| Flutter/Dart version | `CLAUDE.md`, `.claude/skills/flutter-mobile/SKILL.md`, `.claude/agents/flutter-mobile.md` |
| Python version | `CLAUDE.md`, `.claude/skills/python-dev/SKILL.md`, `.claude/agents/python-dev.md` |
| LangChain/LangGraph | `CLAUDE.md`, `.claude/skills/agentic-ai-dev/SKILL.md`, `.claude/agents/agentic-ai-dev.md` |

**Process:**
1. Update version numbers in the files above
2. Update any changed API patterns in skill `reference/` files
3. Test with a scaffold command to verify the generated code compiles
4. Commit as `docs: update [framework] to vX.Y`

---

## 13. Claude Code Power Features

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
    "allow": [
      "Bash(npm *)",
      "Bash(git status *)",
      "Bash(git diff *)"
    ],
    "ask": [
      "Bash(rm *)",
      "Bash(curl *)"
    ],
    "deny": [
      "Bash(sudo *)",
      "Bash(rm -rf /)",
      "Read(./.env)",
      "Read(./**/*.key)"
    ]
  }
}
```

**Permission rule patterns:**

| Pattern | Example | Description |
|---------|---------|-------------|
| Exact match | `Bash(npm run test)` | Only this exact command |
| Wildcard suffix | `Bash(npm *)` | npm followed by anything |
| Glob patterns | `Read(./src/**/*.ts)` | All .ts files recursively |
| Tool-only | `Read`, `Write`, `Edit`, `Bash`, `WebFetch`, `WebSearch` | Entire tool category |

This repo's `settings.json` comes pre-configured with sensible defaults — see [Settings Configuration](#settingsjson-configuration) in Section 10 for the full breakdown.

## 14. Tips & Best Practices

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

### Common Pitfalls — Avoid These

These mistakes are common among new Claude Code users and waste significant time:

| ❌ Pitfall | Why It's Bad | ✅ Instead |
|-----------|-------------|-----------|
| Enable all 12 MCP servers at once | Each server's tool schemas consume context tokens. 12 servers can eat 50K+ tokens before you type anything | Enable only the 3–4 servers relevant to your current task. Disable unused ones in `.mcp.json` using `"disabled": true` |
| Paste entire files into the prompt | Files are transmitted as prompt tokens — a 500-line file wastes context | Use `@src/path/to/file.ts` references instead |
| Skip `/compact` in long sessions | Context fills up silently. Claude's output quality degrades before you notice | Run `/compact` every ~30–50 tool operations, or when you switch tasks |
| Ask Claude to "review everything" | Unbounded scope → shallow, generic feedback | Be specific: "Review `src/auth/` for SQL injection and missing input validation" |
| Trust the first scaffold output blindly | Generated code may use outdated APIs or miss project-specific conventions | Always run the build command (`ng build`, `mvn verify`, `npm run build`) after scaffolding |
| Use the same Claude session for unrelated tasks | Context from task A pollutes task B, causing confusion | Start a fresh session (`/exit` → `claude`) for unrelated work, or use `/clear` |
| Ignore the "Context remaining" warnings | Once context is exhausted, Claude can't process new information effectively | Watch `/context` and compact or start fresh before hitting limits |

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

### Team Collaboration Patterns

When multiple developers use Claude Code on the same codebase:

**Shared vs Personal Configuration**

| File | Git Tracked? | Shared With Team? | Purpose |
|------|-------------|-------------------|---------|
| `CLAUDE.md` | ✅ Yes | ✅ Yes | Project conventions everyone follows |
| `CLAUDE.local.md` | ❌ No (auto-gitignored) | ❌ No | Personal preferences (model, verbosity, shortcuts) |
| `.claude/settings.json` | ✅ Yes | ✅ Yes | Shared permissions, hooks |
| `.claude/settings.local.json` | ❌ No | ❌ No | Personal permission overrides |
| `.mcp.json` | ✅ Yes | ✅ Yes | MCP server configurations |
| `.env` | ❌ No (gitignored) | ❌ No | Personal API keys and credentials |

**Branch Collision Prevention**

When two developers use Claude Code simultaneously on the same repo:

```bash
# Each developer works on their own feature branch
git checkout -b feature/alice-auth
git checkout -b feature/bob-dashboard

# For tasks that touch the same files, use git worktrees
git worktree add ../project-auth feature/alice-auth
git worktree add ../project-dashboard feature/bob-dashboard
# Run separate Claude Code instances in each worktree
```

**Standardizing Team CLAUDE.md**

To keep the team aligned:

1. **Project-level `CLAUDE.md`** — committed to git, contains stack info, conventions, commands. PR-reviewed like any other code change
2. **Personal `CLAUDE.local.md`** — each developer's preferences (model choice, verbosity, personal shortcuts). Never committed
3. **Rules directory `.claude/rules/`** — committed to git. Breaking rules into files allows teams to own different areas (frontend team owns `angular-rules.md`, backend team owns `spring-rules.md`)

**Onboarding a New Team Member**

```bash
# 1. Clone the repo (CLAUDE.md, agents, skills, commands come with it)
git clone <repo-url> && cd <repo>

# 2. Copy the .env template and fill in personal credentials
cp .env.example .env
# Edit .env with your API keys

# 3. Make hooks executable
chmod +x .claude/hooks/*.sh

# 4. Start Claude Code and run the status check
claude
> /project-status

# 5. Try a scaffold exercise to verify everything works
> /scaffold-spring-api hello-world
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

### Skills — Best Practices

**Keep skills lean:**
- Target 3–5KB for the SKILL.md file
- If your skill exceeds 10KB, you're probably embedding too much documentation

**Use lazy loading for large skills:**
Instead of embedding all documentation in SKILL.md, put detailed references in separate files and load them on-demand:
```
.claude/skills/my-skill/
├── SKILL.md                    # 3KB — routing logic only
└── reference/
    ├── use_case_1.md           # Loaded when needed
    ├── use_case_2.md           # Loaded when needed
    └── use_case_3.md           # Loaded when needed
```

In your SKILL.md, instruct Claude to load the right reference:
```markdown
**When user asks about use case 1:**
  → Read reference/use_case_1.md, then proceed
```

This can reduce token usage by 80–95% for complex skills.

**SKILL.md frontmatter:**
```yaml
---
name: my-skill                    # Required: hyphen-case, max 64 chars
description: |                    # Required: when to activate (max 1024 chars)
  This skill should be used when the user asks to...
allowed-tools: Read, Bash(npm:*)  # Optional: restrict available tools
---
```

### Writing a Good CLAUDE.md

Your `CLAUDE.md` is the **highest-leverage file** in the entire setup — it goes into every session and shapes every task. A bad line here gets into every plan, every implementation, every artifact Claude produces. Invest time crafting it carefully.

#### The Basics: WHAT → WHY → HOW

| Tell Claude... | Example |
|----------------|---------|
| **WHAT** — your project context, tech stack, rules, project structure | "Monorepo: `apps/api` (Spring Boot), `apps/web` (Angular), `packages/shared`" |
| **WHY** — the purpose of each part | "The `auth + gateway` service handles auth + rate-limiting for all downstream APIs" |
| **HOW** — how to work on the project | "Use `bun` not `npm`. Run tests with `mvn test`. Flyway migrations live in `db/migrations/`" |

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
- All code must pass `mvn verify` before committing
- Use conventional commits: feat|fix|docs|refactor(scope): message
- Never commit secrets or .env files
```

#### Quick Rules of Thumb

- **< 300 lines** or **<40 KB** is the general rule, shorter is better (some teams use < 60 lines)
- Most important rules go **at the top and bottom** — LLMs attend most to the start and end of context
- Use `CLAUDE.local.md` for personal preferences (auto-gitignored)
- Use `.claude/rules/` for conditional rules scoped to specific directories

### When Claude Ignores Its Rules

**The Hard Truth: Why CLAUDE.md Isn't Enough**
`CLAUDE.md` and `.claude/rules/` tell Claude how to behave — but they're guidance, not enforcement. Three deeply baked in biases from training cause Claude to break its own rules:

| Bias | What Happens | Example |
|------|-------------|---------|
| **Path of least resistance** | Creates new files is simpler instead of understanding existing code | Adds `utils-v2.ts` instead of modifying `utils.ts` |
| **Safety instinct** |  Return something rather than fail. So it returns empty/mock data instead of failing visibly | `catch (e) { return []; }` instead of rethrowing |
| **Optimism bias** | LLMs want to seem helpful/complete | Says "done" when 2 of 5 items are implemented |

**The fix:** `CLAUDE.md` is prevention. The prompts below are treatment — copy-paste them when Claude misbehaves.

#### Start-of-Task Prompt

Paste this at the beginning of any non-trivial task to set expectations:

```
Before you start, confirm you understand:
1. VERIFY before claiming — read actual code, show file:line evidence
2. No flip-flopping — if you say "missing", verify first, don't change when I push back
3. Implement 100% of the plan — no skipping items
4. Modify existing files — don't create new ones without approval
5. No mock data, no silent errors — failures must be visible
6. Binary status: works or broken — no "95% done"

Say "understood" then proceed.
```

#### When Claude Guesses Instead of Verifying

**Problem**

```
You ask: "What's implemented so far?"
Claude says: "Auth service is done, payment module is missing"
You check: Auth service has no validations and no tests, payment module exists at src/payments/

WHY? Claude saw auth-service.ts and assumed it was complete.
It didn't see payments/ because it never opened the directory — it guessed from memory.
```

**Solution:** Paste below prompt

```
Before you tell me what's missing or implemented:
1. Actually READ the code files
2. For each claim, show file:line as evidence
3. Don't guess based on file names

If you can't point to specific code, say "I haven't verified this yet."
```

#### When Claude Flip-Flops

**Problem**

```
Claude says: "Feature X is missing"
You ask: "Are you sure?"  
Claude says: "Actually it IS implemented!"

WHY? Claude didn't actually check. It guessed, then agreed with you to avoid conflict.
```

**Solution:** Paste below prompt

```
STOP. You just flip-flopped.
First you said [X] was missing. Now you say it's implemented.
Which is it? Show me:
1. The exact file and line number
2. The actual code snippet

Don't guess. Don't agree with me to avoid conflict. VERIFY and show evidence.
```

#### When Challenging Claude's Analysis

**Problem**

```
Claude says: "The validation logic is missing"
You say: "I'm pretty sure it's there"
Claude says: "You're right, it is there!"

WHY? Claude wants to avoid conflict. Instead of re-reading the code,
it just agrees with whatever you say — even if its original claim was correct.
```

**Solution:** Paste below prompt

```
You said [X] is missing. Are you sure?
Don't just agree with me — RE-VERIFY by reading the actual code.
Show me the file you checked and what you found or didn't find.
```

## 15. Troubleshooting

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

### Windows-Specific Setup

**Hooks require a Bash shell.** The `.claude/hooks/*.sh` scripts won't run natively on Windows. Options:

| Approach | How | Trade-off |
|----------|-----|-----------|
| **WSL 2 (recommended)** | Install WSL 2, run Claude Code from a WSL terminal | Full Linux compatibility, hooks work natively |
| **Git Bash** | Install Git for Windows, use Git Bash as your terminal | Most hooks work, occasional path issues |
| **Rewrite as .ps1** | Convert bash hooks to PowerShell scripts | Native Windows, but requires rewriting and testing each hook |

If using WSL 2:
```bash
# Install WSL 2 (from PowerShell as admin)
wsl --install

# Clone the repo inside WSL, not on /mnt/c/
cd ~ && git clone <repo-url>

# Run Claude Code from WSL
claude
```

**MCP servers on Windows** may need a `cmd` wrapper in `.mcp.json`:
```json
"command": "cmd",
"args": ["/c", "npx", "-y", "package-name"]
```

### Run diagnostics

When something isn't working and you're not sure why:

```bash
claude doctor              # General health check
claude --debug             # Full debug logging
claude --debug "mcp"       # Debug a specific category
```

## 16. Quick Reference Card

Print or bookmark this — it covers 90% of daily Claude Code usage.

### Commands You'll Use Every Day

```
claude                              # Start session
claude --continue                   # Resume last session
claude --resume <name>              # Resume named session
/compact                            # Compress context (do this often)
/context                            # Check context usage
/cost                               # Token usage this session
/exit                               # End session
```

### Scaffolding

```
/scaffold-spring-api <name>         # Java Spring Boot API
/scaffold-nestjs-api <name>         # NestJS API
/scaffold-python-api <name>         # Python FastAPI
/scaffold-angular-app <name>        # Angular SPA
/scaffold-flutter-app <name>        # Flutter mobile app
/scaffold-agentic-ai <name>         # AI Agent service
```

### Design & Review

```
/design-architecture <description>  # System architecture with diagrams
/design-database <domain>           # Database schema with ERD + migrations
/review-code [scope]                # Code review (auto-detects stack)
/audit-security [scope]             # Security vulnerability scan
/project-status                     # Codebase summary
/status-check                       # Binary works/broken report
```

### Agents (use @name)

```
@java-spring-api                    # Spring Boot backend expert
@nestjs-api                         # NestJS backend expert
@python-dev                         # Python / FastAPI expert
@angular-spa                        # Angular frontend expert
@flutter-mobile                     # Flutter mobile expert
@agentic-ai-dev                     # AI agent builder
@architect                          # Solution architecture
@database-designer                  # PostgreSQL + Firestore
@security-reviewer                  # Security audit
@code-reviewer                      # General code review
```

### Keyboard Shortcuts

```
@filename                           # Reference a file in prompt
Tab                                 # Toggle thinking display
Shift+Enter                         # Multi-line input
Esc                                 # Cancel generation
Ctrl+U                              # Delete entire line
/clear                              # Clear conversation
/model                              # Switch model
```

### MCP Tips

```
use context7                        # Append to any prompt for live docs
/mcp                                # Check MCP server status
```

## 17. Resources

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