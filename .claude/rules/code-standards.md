# Code Standards

## Documentation Before Code

Consult official docs via MCP before writing ANY code. This rule is enforced here (always-loaded) because CLAUDE.md is not visible to sub-agents.

```
About to write code?
    |
    +-- Does a dedicated MCP server exist for this library/framework?
    |   YES -> Query it first. Use the response to inform your implementation.
    |   NO  -> Use Context7 MCP as fallback.
    |
    +-- Does the code use an API you haven't verified this session?
        YES -> Check signature, params, return type against MCP/docs before using.
        NO  -> Proceed.
```

**Non-negotiable:**
- NEVER generate code from memory when an MCP server can confirm the current API
- NEVER use deprecated methods — MCP results will show current alternatives
- If MCP returns something different from what you expected, trust the MCP result

**Dependency version selection:**
- When selecting a dependency, explicitly use the latest stable version. Pin to a specific version in `package.json` / `pubspec.yaml` / `pom.xml` / `pyproject.toml` — never use `*`, `latest`, or unpinned ranges in production.
- Verify the package exists and is legitimate before installing (see `security-review-checklist.md` §6 Dependencies).

**MCP lookup order:**
1. Dedicated MCP server listed in the skill's SKILL.md (e.g., Angular CLI MCP, Firebase MCP, Dart MCP)
2. `Context7` MCP — resolve library ID first, then query docs
3. `WebSearch` / `WebFetch` — last resort for very new or niche libraries

## Modify Existing Files First

```
Need to add code?
    ↓
Does relevant file exist?
    ├─ YES → Modify existing file (DEFAULT)
    └─ NO → Is this >150–200 lines of cohesive new logic?
              ├─ YES → Consider new file (ask human first)
              └─ NO → Find closest existing file and add there
```

When creating new files: remove/update old files, update all imports, delete orphans. NEVER leave old + new both existing.

## Error Handling

### No Silent Failures, No Mock Data, No Fallbacks

```
// ❌ FORBIDDEN (applies to ALL languages)
catch (e) { return []; }           // Silent empty return
catch (e) { return MockData.x; }   // Fake data
catch (e) { /* nothing */ }        // Swallowed exception

// ✅ REQUIRED
catch (e) {
  logger.error('fetchData failed', error: e);
  rethrow; // OR return error state (Result.failure, HttpException, HTTPException, etc.)
}
```

- Every catch block MUST log the error
- Every catch block MUST either rethrow OR return an error state
- User MUST see when something fails (snackbar, error widget, toast, etc.)
- NEVER return empty list/null/default on error
- NEVER create mock data unless explicitly requested
- Language-specific patterns: see each technology's skill (e.g., `java-spring-api`, `nestjs-api`, `python-dev`, `flutter-mobile`)

## DRY Enforcement

Before writing ANY code:

1. CHECK: Does this logic exist in shared/common utilities? → YES: import it
2. ASK: Will another module need this? → YES: create in shared utilities first

**Forbidden:** inline utility logic when shared version exists; duplicating logic across files.

| Metric | Target | Action |
| ------ | ------ | ------ |
| File size | ~400–500 lines | Extract when hard to navigate |
| Duplicate code blocks | 0 | Extract to shared |
| Inline utilities | 0 | Move to shared |

## Logging Standards

- **Structured:** All logs include context (user type, action, timestamp)
- **Centralized:** Single logging utility used everywhere
- **Leveled:** Appropriate levels (debug, info, warn, error)
- Log all error conditions with full context
- Log sync operations (start, success, failure)
- NEVER log sensitive data (passwords, tokens, PII)
- NEVER use `print()` — use centralized logger
- NEVER use `console.log()` / `console.warn()` / `console.error()` directly — use centralized logger (e.g., NestJS `Logger`, Angular `ErrorHandler`). Raw console statements leak internal logic to anyone with devtools open. Sweep before every deploy.

## Output Quality

- No bloated abstractions or premature generalization
- No clever tricks without comments explaining why
- Match the project's idioms — don't introduce a different paradigm mid-file
- Meaningful variable names (no `temp`, `data`, `result` without context)
- Zero: deprecated APIs, stub implementations, TODO comments, duplicate implementations, backward compatibility wrappers

## Change Descriptions

After any modification:

```
CHANGES MADE:
- [file]: [what changed and why]

THINGS I DIDN'T TOUCH:
- [file]: [intentionally left alone because...]

POTENTIAL CONCERNS:
- [any risks or things to verify]
```

## Content Validation Before Writing

Before creating or writing ANY file containing diagrams or structured content:

### Mermaid Diagrams
- Validate syntax mentally before writing — broken Mermaid renders as raw text
- Escape special characters: parentheses `()`, brackets `[]`, quotes in node labels
- Test: Can every node label be parsed without ambiguity?
- Always provide a text description as fallback below the diagram block

### ASCII Diagrams
- Use ONLY these characters: `+` `-` `|` `^` `v` `<` `>` and spaces
- NEVER use Unicode box-drawing characters: `┌ ─ │ └ ┐ ┘ ├ ┤ ┬ ┴ ┼ ▼ ▲ ► ◄`
  (they render inconsistently across terminals and fonts)
- Every line inside a box MUST have the same character count
- Verify alignment in monospace before writing

### General
- No raw HTML in markdown files unless the render target is confirmed to support it
- No emoji in code comments or rule files unless the project explicitly uses them
- Special characters in file paths must be escaped per the target shell

## Pre-Submit Checklist

- [ ] MCP server was consulted for relevant technology
- [ ] No deprecated features or syntax
- [ ] No unused imports, variables, or functions
- [ ] No duplicate logic
- [ ] Old code paths removed if replaced
- [ ] Error handling follows centralized pattern
- [ ] Code matches official documentation examples
