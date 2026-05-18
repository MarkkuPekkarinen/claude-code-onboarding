---
description: Audit the current repo against the MVP RAG checklist; produce a structured gaps report with severity
---

# /rag-review — Audit RAG Implementation

Audit the current repository against the production RAG MVP checklist (§45) and the hard rules from the playbook.

## Phase 1: Discover the implementation

Walk the repo and identify:
- Where is the RAG pipeline code? (typically `rag/`, `retrieval/`, `pipeline/`, or similar)
- What vector DB is used? (look for imports: pinecone, weaviate, qdrant, pgvector, chroma)
- What embedding model? (look for OpenAI, Cohere, BGE, Voyage, etc.)
- What reranker, if any?
- Where is the prompt template?
- Is there an audit log?
- Is there an eval directory? Golden set?

If the structure is unclear, ask the user once to point at the main pipeline entry point.

## Phase 2: Run the checklist

For each item, classify as ✅ Present, ⚠️ Partial, ❌ Missing, or ❓ Unknown (couldn't determine).

### Ingestion (must have)

- [ ] Parser appropriate to corpus (not raw `pdf.extract_text()` for complex PDFs)
- [ ] Document-aware chunking (not fixed-size only)
- [ ] Stable chunk IDs: `(document_id, document_version, chunk_index)`
- [ ] Content-hash diffing for updates
- [ ] Required metadata per chunk: `document_id`, `chunk_id`, `tenant_id`, `access_level`, `version`, `updated_at`, section, page
- [ ] Tested deletion path (including cache invalidation)

### Retrieval (must have)

- [ ] Hybrid retrieval (dense + BM25) — or measured justification for skipping sparse
- [ ] RRF fusion (not ad-hoc score blending)
- [ ] Hard filters at a SINGLE chokepoint, applied BEFORE retrieval
- [ ] **Pre-filtered ANN, not post-filter on top-k** (critical security check)
- [ ] Cross-encoder reranker on top 50–100 → keep top 5–10

### Generation (must have)

- [ ] Strict grounding prompt ("answer only from context")
- [ ] Citation format — every claim traceable to a chunk
- [ ] Calibrated abstention threshold
- [ ] Structured answer contract (or equivalent — citations + confidence + abstained fields)

### Security (must have)

- [ ] Access control enforced at retrieval, not in LLM
- [ ] Retrieved content treated as untrusted (delimiters, no instruction execution)
- [ ] Tenant filter single chokepoint
- [ ] Per-response audit log

### Evaluation (must have)

- [ ] Golden set (50+ queries minimum) — or planned with explicit date
- [ ] CI gate on golden set regressions
- [ ] Production logging of failures (no-answer rate, low-confidence rate)

### Operations (must have)

- [ ] p95 latency target defined and monitored
- [ ] Cost dashboard (vector DB, LLM, reranker, embedding)
- [ ] Query embedding cache
- [ ] Runbook for embedding model migration

## Phase 3: Output a structured report

Use this format:

```markdown
# RAG Implementation Audit

**Repo:** {{repo-name}}
**Date:** {{today}}
**Auditor:** Claude (via /rag-review)

## Summary

- ✅ Present: {{N}} of {{total}}
- ⚠️ Partial: {{N}}
- ❌ Missing: {{N}}
- ❓ Unknown: {{N}}

**Critical findings:** {{count of critical}}
**Recommended next 3 PRs:** {{list}}

## Critical (security or data integrity)

### {{Finding 1}}
**Status:** ❌ Missing
**Evidence:** `rag/retrieve.py:42` — `vector_db.search(query)` followed by `[c for c in results if c.tenant_id == user.tenant_id]`
**Issue:** Post-filtering after retrieval. ANN sees unauthorized documents; one filter bug = data leak.
**Fix:** Switch to pre-filtered ANN. Example:
```python
vector_db.search(query, filter={"tenant_id": user.tenant_id}, top_k=50)
```
**Playbook reference:** §20.2

## High (recall or production stability)

{{...}}

## Medium (quality and ops)

{{...}}

## Low (nice-to-have, hygiene)

{{...}}

## Recommended next 3 PRs (priority order)

1. **{{PR title}}** — fixes {{finding}}; effort {{S/M/L}}
2. ...
3. ...
```

## Phase 4: Offer follow-ups

After delivering the report, ask the user:
- Want me to draft the top-priority fix as a PR-ready change?
- Want me to create `/rag-debug` traces for any specific failing queries you've seen?
- Want me to scaffold the missing eval setup?

## Style notes

- Be specific — file:line citations, not generic advice.
- Severity matters: a missing audit log is medium; a post-filter on security is critical.
- If something is unclear from code alone, mark ❓ Unknown and ask ONE clarifying question rather than guessing.
- Don't pad the report — if there are 3 critical findings, list 3, don't manufacture 10.
