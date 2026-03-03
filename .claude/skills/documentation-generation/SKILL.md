---
name: documentation-generation
description: Documentation generation skill for README creation, docstring patterns,
  and CI/CD doc pipelines. Use when generating project documentation, writing docstrings,
  setting up doc automation, or creating README files. Triggers: doc-generate, README,
  docstring, documentation, doc pipeline, generate docs.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

## Iron Law: NO DOC GENERATION WITHOUT READING THE PROJECT-SPECIFIC TEMPLATES FIRST

Read the appropriate reference before writing any documentation.

## Process

1. **Detect stack** — Check for `pom.xml` (Java), `package.json` (NestJS/Angular), `pyproject.toml` (Python), `pubspec.yaml` (Flutter)
2. **Load template** — Read the matching section in `references/readme-templates.md`
3. **Apply docstring pattern** — Read `references/docstring-patterns.md` for the correct format per language
4. **Configure CI/CD** — Read `references/cicd-doc-pipeline.md` when setting up automated doc generation

## When to Use

- Creating or refreshing a project README
- Writing docstrings for public APIs (with `/doc-generate`)
- Setting up a CI/CD pipeline that auto-generates API docs on push
- Generating OpenAPI specs from code annotations (see `openapi-spec-generation` skill)
- Creating architecture diagrams (use `mermaid-expert` agent)

## References

| File | Content |
|------|---------|
| `references/readme-templates.md` | Stack-specific README templates for Java/Spring, NestJS, Python FastAPI, Flutter |
| `references/docstring-patterns.md` | Javadoc, JSDoc, Python Google-style, Dart `///` patterns with examples |
| `references/cicd-doc-pipeline.md` | GitHub Actions workflow for auto-doc generation + Redocly + GitHub Pages |

## Error Handling

If project type cannot be auto-detected, ask the user to specify the stack before loading templates.
If README exists and appears current, report that and do not overwrite without explicit approval.
