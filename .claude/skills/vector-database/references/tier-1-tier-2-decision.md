# Tier 1 vs Tier 2 — Vector Store Selection (PropertyHarbor §8)

Load this file BEFORE specifying where any new vector data should live —
adding embeddings to a service, designing a schema with a `vector(N)`
column, creating a new Weaviate collection, or reviewing a PR that does
either. Picking the wrong tier is expensive to undo because schemas and
indexes are immutable in production.

## The split

```
┌────────────────────────────────────────┐  ┌────────────────────────────────────────┐
│  TIER 1 — pgvector (PostgreSQL)        │  │  TIER 2 — Weaviate Cloud               │
│                                        │  │                                        │
│  • Vendor profile embeddings           │  │  • Lease clause chunks                 │
│  • Landlord rule embeddings            │  │  • FAQ corpus                          │
│                                        │  │                                        │
│  • Hot path / low latency              │  │  • Cold path / batch RAG               │
│  • Joins with relational data          │  │  • Pure semantic search                │
│  • Strong consistency                  │  │  • Eventual consistency OK             │
│  • <50ms p99 query                     │  │  • <500ms p99 query                    │
└────────────────────────────────────────┘  └────────────────────────────────────────┘
        Vendor matching, rule lookup              lease_qa_agent, FAQ search
```

## The decision rule (binary, mandatory)

Answer this question before adding ANY vector data:

> **"Does the query need SQL JOIN, PostGIS, or relational filters alongside vector similarity?"**

| Answer | Tier | Rationale |
|---|---|---|
| **YES** | **Tier 1 — pgvector** | Vector lives next to the relational data so one SQL transaction does everything. Weaviate cannot JOIN with Postgres tables — denormalising to keep them in sync introduces eventual-consistency bugs. |
| **NO — pure semantic / hybrid text search** | **Tier 2 — Weaviate** | Weaviate's native `hybrid()`, physical multi-tenancy, and reranker plug-ins are purpose-built for this. pgvector's BM25 is weaker; pgvector multi-tenancy is filter-only. |
| **Both?** | **Two-stage retrieval** | Tier 1 returns candidates with relational filters → pass IDs to Tier 2 for semantic re-rank. See `rag-pipeline-patterns.md` "Two-Stage Retrieval" section. Rare in PropertyHarbor. |

## Decision criteria checklist

Tick what applies to your data. Mostly Tier 1 column? → pgvector. Mostly Tier 2 column? → Weaviate.

| Criterion | Tier 1 (pgvector) | Tier 2 (Weaviate) |
|---|---|---|
| Joined with relational data? | ✓ Yes — vendors / rules JOIN other tables | ✗ No — pure text content |
| Filtered by SQL aggregates / PostGIS / multi-table predicates? | ✓ Yes (`ST_Within`, multi-table joins) | ✗ Mostly tenant + maybe property |
| Strong consistency required? | ✓ Yes — vendor onboarded → MUST match instantly | ✗ No — chunk indexed → readable in seconds is fine |
| Hybrid search required? (BM25 + vector) | ✗ No — vector-only acceptable | ✓ Yes — exact phrases ("Section 5.3", "$2,400") matter |
| Reranking required? | ✗ Not at MVP scale | ✓ Yes — production lease/FAQ QA needs it |
| Scale per tenant | Thousands → low millions of rows | Millions → billions of chunks |
| User-blocking latency budget | <50ms (results page) | <500ms (chat response, can stream) |
| Schema flexibility | Stable — Alembic migration per change | Flexible — chunks vary per document |
| Multi-tenancy isolation strength | Logical (`WHERE tenant_id = ?`) | Physical (`with_tenant()` shards) |

If your data hits ≥4 left-column boxes → **Tier 1**. If it hits ≥4 right-column boxes → **Tier 2**. If it splits roughly 50/50, your data may be in the wrong shape — re-think before adding it.

## Why split at all (and not just one store)?

### "Why not put everything in Weaviate?"

- Weaviate doesn't `JOIN` with Postgres. Vendor matching needs `vendors JOIN vendor_coverage` + `ST_Within` (PostGIS). Putting it in Weaviate forces denormalisation and 2-database write consistency.
- Weaviate has no PostGIS. Geo filtering on coverage areas would happen client-side after pulling all vendors — terrible.
- Weaviate Cloud is more expensive per row than pgvector (which sits inside Cloud SQL we're already paying for).
- Real-time freshness — vendor onboarded at T must match at T+1ms, not T+5s.

### "Why not put everything in pgvector?"

- pgvector HNSW index is fine up to ~10M vectors per table; beyond that, latency degrades. Lease chunks easily hit billions across all tenants.
- pgvector hybrid search (combining `tsvector` BM25 with cosine) requires hand-rolled SQL and rank-fusion — Weaviate's `hybrid()` is one line with proper score fusion.
- pgvector multi-tenancy is filter-only (`WHERE tenant_id = ?`). Weaviate's native multi-tenancy gives **physical sharding per tenant** — required for the §38 compliance gate (Fair Housing, GDPR, lease privacy).
- Weaviate's reranker integration (Cohere, Voyage, BGE modules) is plug-and-play; in pgvector you build it yourself.

## PropertyHarbor canonical placements

| Vector data | Tier | Reason |
|---|---|---|
| **Vendor profile embeddings** | Tier 1 | JOIN with `vendors`, `vendor_coverage` (PostGIS), `vendor_ratings` |
| **Landlord vendor-selection rule embeddings** | Tier 1 | JOIN with `landlord_vendor_selection_rules`; FHA `legal_review_flag` filter required |
| **Landlord tenant-screening rule embeddings** | Tier 1 | Same as above for screening rules |
| **Property amenity embeddings** (if added) | Tier 1 | JOIN with properties + PostGIS coverage |
| **Lease clause chunks** | Tier 2 | `lease_ingestion_agent` ingest path; `lease_qa_agent` retrieval |
| **FAQ corpus chunks** | Tier 2 | Same retrieval profile as leases |
| **Vendor review chunks** (post-MVP) | Tier 2 | Pure unstructured text; `vendor_review_qa_agent` |
| **Triage agent few-shot examples** (if vectorised) | Neither — keep in code | Fewer than 100 examples; no scale need |

When you encounter a vector data type NOT in this list:

1. Run the decision rule above
2. State the placement + your reasoning in the schema PR description
3. Dispatch `pgvector-schema-reviewer` (Tier 1) or `weaviate-schema-reviewer` (Tier 2)
4. If reviewer flags a tier mismatch, swap to the other tier before merging

## Real-world example — one user request, both tiers

```
1. Tenant submits "kitchen sink leaking, getting worse over weeks"
   ↓
2. triage_agent classifies it (no vector store yet)
   ↓
3. matching_engine looks up vendors:
   ┌─────────────────────────────────────────────┐
   │ TIER 1 query (pgvector)                     │
   │ "find plumbers within 5mi of property,      │
   │  embedding similar to 'leak repair',        │
   │  active, rating ≥ 4.0, tenant=landlord_X"   │
   │ → 20 candidates in 30ms                     │
   └─────────────────────────────────────────────┘
   ↓
4. Reranker picks top 3
   ↓
5. tenant later asks "what does my lease say about appliance repairs?"
   ↓
6. lease_qa_agent retrieves clauses:
   ┌─────────────────────────────────────────────┐
   │ TIER 2 query (Weaviate)                     │
   │ "hybrid search 'appliance repair'           │
   │  in lease_X, tenant=landlord_X"             │
   │ → 5 chunks in 200ms                         │
   │ + reranker → top 3 → LLM answer             │
   └─────────────────────────────────────────────┘
```

## Hard rules (violation = STOP and revert)

- **NEVER** add vector data to pgvector if the answer to the JOIN/PostGIS/aggregate question is "no" AND the corpus is unstructured text — that data belongs in Tier 2.
- **NEVER** add vector data to Weaviate if it needs `JOIN`, PostGIS, or multi-table aggregate filters at query time — that data belongs in Tier 1. Denormalisation is not the fix; denormalisation creates 2-database consistency bugs that surface as silent retrieval misses.
- **NEVER** sync Postgres rows to Weaviate to "have both" — dual-writes drift in production. If you genuinely need both, use two-stage retrieval (Tier 1 candidate → Tier 2 rerank), not synchronisation.
- **NEVER** put a new vector column or collection in a service WITHOUT stating the tier decision in the PR description (dispatch `pgvector-schema-reviewer` or `weaviate-schema-reviewer` to enforce).

## TL;DR

| | **Tier 1 — pgvector** | **Tier 2 — Weaviate** |
|---|---|---|
| **Mental model** | "Vector as a column in your database" | "Database designed entirely around vector search" |
| **Job** | Vectors that live alongside relational data | Vectors for pure unstructured text RAG |
| **PropertyHarbor uses for** | Vendor profiles, landlord rule embeddings | Lease clause chunks, FAQ corpus |
| **Query style** | Mixed — SQL JOIN + WHERE + vector | Pure semantic + hybrid BM25 |
| **Optimal for** | Transactional matching | Long-document QA |
| **Latency** | <50ms (user-blocking) | <500ms (streamable) |
| **Scale** | Millions per tenant | Billions across tenants |
| **Consistency** | ACID with PostgreSQL | Eventual (writes → readable in seconds) |
| **Multi-tenancy** | Logical (`WHERE`) | Physical (`with_tenant()`) |
| **Hybrid search** | DIY | Native `hybrid()` |

**Pick by query characteristics, not by data size.** Most production RAG systems run both — that's expected, not a smell.

## Cross-references

- `.claude/rules/propertyharbor-constraints.md` §8 (vector embedding model + tier rule)
- `.claude/skills/vector-database/SKILL.md` (decision tree)
- `.claude/skills/vector-database/references/pgvector-migration-template.md` (Tier 1 schema design)
- `.claude/skills/vector-database/references/weaviate-collection-patterns.md` (Tier 2 schema design)
- `.claude/skills/vector-database/references/rag-pipeline-patterns.md` "Two-Stage Retrieval" (when both tiers are needed in one query)
- `.claude/agents/pgvector-schema-reviewer.md` (Tier 1 schema review)
- `.claude/agents/weaviate-schema-reviewer.md` (Tier 2 schema review + tier-mismatch flag)
