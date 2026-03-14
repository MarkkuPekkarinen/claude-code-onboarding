---
description: Run a security audit on the codebase. Checks for secrets, OWASP Top 10, dependency vulnerabilities, and configuration issues.
allowed-tools: Bash, Read, Glob, Grep, Task
disable-model-invocation: true
---

# Security Audit

Run a comprehensive security audit on the codebase.

## Process

1. **Determine scope** — audit `$ARGUMENTS` if provided, otherwise audit the full project
2. **Delegate to `security-reviewer` agent** with the following checks:
   - Hardcoded secrets, API keys, tokens, passwords
   - OWASP Top 10 vulnerabilities (injection, XSS, SSRF, broken auth, etc.)
   - Unsafe deserialization or eval usage
   - Missing input validation at system boundaries
   - Insecure cryptographic practices
   - Exposed debug endpoints or verbose error messages in production
3. **Check configuration files**:
   - `.env` files not in `.gitignore`
   - Secrets in `docker-compose.yml` or CI config
   - Overly permissive CORS or security headers
4. **Check dependencies** (if applicable):
   - Run `npm audit` for Node.js projects
   - Run `pip audit` for Python projects
   - Flag known CVEs in `pom.xml` dependencies
5. **Dependency vulnerability scan** (deep scan):

   Run the dependency scanner for a comprehensive CVE analysis with priority scoring:

   ```
   /security-dependencies $ARGUMENTS
   ```

   Include the top 5 highest-priority CVEs (by priority score) in the final report.
   Flag any CVSS 9+ findings as blocking -- do not approve the release until resolved.

6. **Agentic CI/CD audit** (if `.github/workflows/` directory exists):

   Load skill: `claude-actions-auditor`

   Glob `.github/workflows/*.yml` and `.github/workflows/*.yaml`. If any workflow file contains `anthropics/claude-code-action`, run the full 5-step audit from the `claude-actions-auditor` skill.

   Add findings to the final report under a new section:
   ```
   ### Agentic CI/CD
   - [workflow-file:line] [vector name] [description]
   ```

   If no workflows or no Claude Code Action steps found: note "No Claude Code Action workflows detected — agentic CI/CD audit skipped."

7. **Report findings**:

```
## Security Audit: [scope]

### Critical
- [file:line] [vulnerability type] [description]

### Warning
- [file:line] [vulnerability type] [description]

### Configuration
- [file] [issue]

### Dependencies
- [package@version] [CVE if known]

### Summary
- Critical: N | Warning: N | Info: N
- Status: ✅ PASS / ❌ FAIL
```

7. **Write Lock Document** (only when audit PASSES — 0 CRITICAL, 0 HIGH findings):

   Write the file `docs/approvals/security-YYYY-MM-DD-<short-commit>.md` where:
   - `YYYY-MM-DD` is today's date
   - `<short-commit>` is the output of `git rev-parse --short HEAD`

   File contents:
   ```markdown
   # Security Audit Approval

   **Date:** YYYY-MM-DD
   **Commit:** <full commit hash> — <commit message>
   **Scope:** <audited path or "full project">
   **Audited by:** security-reviewer agent + /audit-security command

   ## Findings Summary

   - CRITICAL: 0
   - HIGH: 0
   - WARNING: N (listed below)
   - INFO: N

   ## Warnings (not blocking)

   <!-- List each WARNING finding here with file:line and brief description -->
   <!-- If none: "None" -->

   ## Waivers

   <!-- If any finding was explicitly waived, document it here:
        - Finding: [description]
        - Reason: [why it was waived]
        - Approved by: [who waived it]
   -->
   <!-- If no waivers: "None" -->

   ## Status

   ✅ APPROVED FOR DEPLOY — No critical or high findings. Safe to proceed to production.
   ```

   If the audit FAILS (any CRITICAL or HIGH findings present):
   - Do NOT write the Lock Document
   - State clearly: "Lock Document not written — audit failed. Resolve all CRITICAL and HIGH findings, then re-run /audit-security."

$ARGUMENTS
