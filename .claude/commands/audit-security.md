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

6. **Report findings**:

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

$ARGUMENTS
