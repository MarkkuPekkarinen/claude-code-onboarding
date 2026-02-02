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

**Where:** `.claude/settings.json` → `hooks` section

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash(git commit:*)",
      "hooks": [{
        "type": "command",
        "command": "./scripts/pre-commit-check.sh"
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
| `/exit` | Exit Claude Code |
| `/memory` | Open CLAUDE.md in your editor |
| `/agents` | List / create agents |
| `/mcp` | Check MCP server status |
| `Tab` | Auto-complete commands |
| `Esc` | Cancel current generation |


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

## 9. Tips & Best Practices

### Getting the Best Results

1. **Be specific** — "Create a REST endpoint for user registration with email validation, password hashing using BCrypt, and a confirmation email trigger" beats "make a signup API"

2. **Use agents for focused work** — `@java-spring-api` gives you a specialized backend expert instead of a generalist

3. **Add `use context7`** to any prompt when you need current library documentation — it fetches live docs and prevents hallucinated APIs

4. **Use `/init`** to auto-generate a `CLAUDE.md` for existing projects

5. **Resume sessions** — `claude -c` continues your last conversation, `claude --resume` lets you pick from recent sessions

### CLAUDE.md Tips

- Keep it under 20KB — too much drowns the signal
- Put the most important rules at the top
- Use imports for large docs: `@docs/api-reference.md`
- Use `CLAUDE.local.md` for personal preferences (auto-gitignored)

---

## 10. Troubleshooting

### "command not found: claude"
```bash
# Add to your shell config
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### MCP server not connecting
```
> /mcp
```
Check the status output. Common fixes:
- Make sure `npx` is available (Node.js installed)
- For GitHub MCP, set your token: `export GITHUB_TOKEN=ghp_your_token_here`
- Restart Claude Code after changing `.mcp.json`

### Claude isn't using skills or agents
- Verify the files exist: `ls .claude/agents/` and `ls .claude/skills/`
- Check YAML frontmatter in each file (needs `---` delimiters)
- Try explicitly mentioning: "Use the java-spring-api skill"

### Permission errors
- Never use `sudo` with npm installs
- Fix npm permissions: `npm config set prefix ~/.npm-global` and add to PATH

### Run diagnostics
```bash
claude doctor
```

---

## 11. Resources

| Resource | Link |
|----------|------|
| Claude Code Official Docs | [code.claude.com/docs](https://code.claude.com/docs) |
| Claude Code GitHub | [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) |
| Claude Code Quickstart | [code.claude.com/docs/en/quickstart](https://code.claude.com/docs/en/quickstart) |
| Claude-Mem Plugin | [github.com/thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) |
| Context7 MCP | [github.com/upstash/context7](https://github.com/upstash/context7) |
| VS Code Download | [code.visualstudio.com/download](https://code.visualstudio.com/download) |
| Awesome Claude Code (Community) | [github.com/hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) |
| MCP Specification | [modelcontextprotocol.io](https://modelcontextprotocol.io) |
| Prompting Guide | [docs.claude.com/en/docs/build-with-claude/prompt-engineering/overview](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/overview) |

---

**Happy coding! 🎉** Start with Exercise 1, and within an hour you'll be building real features with Claude Code as your AI pair programmer.
