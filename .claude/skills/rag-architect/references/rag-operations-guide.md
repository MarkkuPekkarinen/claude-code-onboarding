# RAG Operations Guide

Reference for operating a production RAG system: caching, cost management, observability, and optimization (§36 of the production RAG playbook).

---

## 1. Caching Strategies (§36.3)

Six cache layers, applied independently. Choose based on hit rate vs staleness tolerance.

| Cache Layer | What Gets Cached | Key | TTL | Tenant-Scoped? | Risk if Wrong |
|---|---|---|---|---|---|
| **Chunk embedding** | Embeddings for stored chunks | `content_hash` | Until doc update | No (chunk is pre-filtered) | Low — stale embedding = retrieval miss |
| **Query embedding** | Embedding of the user query | `hash(query_text + model)` | 1–24h | No | Low |
| **Exact-match query** | Full pipeline result for identical queries | `hash(query + tenant_id + filters)` | 15–60 min | **YES — must include tenant_id** | **Critical** — cross-tenant data leak if key missing tenant |
| **Semantic query** | Result for similar (not identical) queries | `nearest_neighbor(query_emb, threshold=0.97)` | 15–30 min | **YES** | **High** — semantic similarity ≠ same answer for different tenants |
| **Retrieval result** | Top-k chunks for a query | `hash(query + filters + retriever_config)` | 5–15 min | YES | Medium — stale chunks returned |
| **LLM response** | Final generated answer | `hash(packed_context + prompt_version)` | 5–30 min | YES | Medium — stale answer surfaced |

### Critical Rule — Cache Key Must Include Tenant
```python
# ❌ WRONG — tenant data leaks across tenants
cache_key = hash(query_text)

# ✅ CORRECT — tenant-scoped key
cache_key = hash(f"{tenant_id}:{user_access_level}:{query_text}")
```
Forgetting tenant in cache key is a **Sev-1 security incident** — another tenant's cached answer returned to a different tenant.

### Cache Invalidation Triggers
- Document updated → invalidate all chunk embeddings for that document
- Policy version change → invalidate all retrieval + LLM response caches for that corpus
- Embedding model change → invalidate all query embedding and chunk embedding caches

---

## 2. Cost Hierarchy (§36.1)

Typical cost breakdown for a production RAG query (varies by scale and model choice):

| Component | % of Total Cost | Primary Driver |
|---|---|---|
| Vector DB (retrieval + indexing) | 30–50% | Query volume × index size |
| LLM (generation) | 25–40% | Context length × output tokens |
| Reranker (cross-encoder) | 10–20% | Candidate pool size × batch frequency |
| Embeddings (query + ingestion) | 5–15% | Query volume + ingestion frequency |
| Ingestion pipeline (parsing, chunking) | 5–10% | Document update frequency |

### Cost Optimization Techniques (§36.2)

| Technique | Reduces | Impact | Tradeoff |
|---|---|---|---|
| **Quantization (PQ/SQ)** | Vector DB storage 4–16× | High | Small recall loss (~1–3%) |
| **Matryoshka truncation** | Embedding cost + storage | Medium | Recall loss at small dims; test first |
| **Prompt caching** | LLM cost | High for repeated system prompts | API support required (Claude, GPT-4o) |
| **Context compression** | LLM input tokens | Medium | Compressor adds latency |
| **Selective reranking** | Reranker cost | High | Apply only when top-k from fusion diverges |
| **Embedding cache** | Embedding API calls | High for repeated queries | Staleness risk on model updates |
| **Content-hash diff ingestion** | Ingestion cost | High for stable corpora | Implementation overhead |
| **Over-retrieve then filter** | LLM cost | Medium | Retrieve 50–100; rerank to 5–10 instead of always sending 50 to LLM |

---

## 3. Observability — Five Dashboards (§36.4)

Build these before going to production. Each has a primary alert threshold.

### Dashboard 1: Health
| Metric | Alert Threshold |
|---|---|
| RAG pipeline p95 latency | > 2s |
| Retrieval step p95 latency | > 500ms |
| Reranker p95 latency | > 300ms |
| LLM generation p95 latency | > 1.5s |
| Error rate (all stages) | > 1% |
| Ingestion queue depth | > 1000 pending |

### Dashboard 2: Quality
| Metric | Alert Threshold |
|---|---|
| Recall@5 (from eval CI run) | < baseline − 0.05 |
| Faithfulness score (LLM judge) | < 0.85 |
| Abstention rate | > 20% (investigate why; > 5% sudden spike = alert) |
| Citation accuracy | < 0.90 |
| Zero-result rate (no chunks retrieved) | > 5% |

### Dashboard 3: Cost
| Metric | Alert Threshold |
|---|---|
| Cost per query (blended) | > $0.05 (tune to your target) |
| LLM token usage per query | > 3000 input + 500 output tokens (investigate packing) |
| Reranker calls per query | > 150 candidates (over-retrieving) |
| Cache hit rate | < 20% (investigate query diversity or TTL) |

### Dashboard 4: Ingestion
| Metric | Alert Threshold |
|---|---|
| Documents ingested per hour | Drops > 50% vs baseline |
| Failed ingestions | > 1% |
| Avg chunk quality score | < 0.6 |
| Low-quality chunks rejected | > 10% of total (investigate parser) |
| Embedding model mismatch detected | Any → Sev-1 |

### Dashboard 5: Security
| Metric | Alert Threshold |
|---|---|
| Cross-tenant filter bypass attempts | Any → **Sev-1 page** |
| ACL policy violation (post-filter access) | Any → **Sev-1 page** |
| Audit log gap (response without log entry) | Any → **Sev-1 page** |
| Prompt injection pattern detected | > 0/day → investigate |
| PII detected in LLM output | Any → **Sev-1 page** |

### Logging — Required Per-Request Fields
Every request must produce one log line with:
```json
{
  "response_id": "uuid",
  "timestamp": "ISO-8601",
  "user_id": "...",
  "tenant_id": "...",
  "query_hash": "sha256(query)",
  "filters_applied": {"tenant_id": "...", "access_level": "..."},
  "chunks_used": ["chunk_id_1", "chunk_id_2"],
  "retriever_scores": [0.92, 0.87],
  "reranker_scores": [0.95, 0.83],
  "model": "gemini-1.5-pro",
  "prompt_version": "v4",
  "latency_ms": {"retrieval": 120, "rerank": 45, "generation": 890},
  "abstained": false,
  "cost_usd": 0.018
}
```

---

## 4. Latency Budget (§36)

Target p95 latency per stage for a 2s end-to-end SLA:

| Stage | Target p95 |
|---|---|
| Query embedding | 50ms |
| ANN retrieval (vector DB) | 100–200ms |
| BM25 retrieval | 30–80ms |
| RRF fusion | < 5ms |
| Reranker (cross-encoder) | 100–250ms |
| Context packing | < 10ms |
| LLM generation (streaming) | 500ms to first token |
| **Total p95** | **< 2s** |

If you're over budget: add reranker caching, reduce candidate pool size, or move to a faster cross-encoder.

---

## 5. Environment-Aware Reranker Configuration (§2)

Use a lighter reranker locally (no Vertex AI auth overhead) and the full production reranker in staging/prod. Switching via environment variable avoids hardcoded model names in code.

### Reranker by Environment

| Environment | Provider | Model | Why |
|---|---|---|---|
| **Local / Docker** | Gemini-as-reranker | `gemini-2.5-flash` | Works with Google AI Studio key; no GCP project required |
| **Staging** | Vertex AI Ranking API | `semantic-ranker-default-004` | Closer to production quality; tests auth path |
| **Production** | Vertex AI Ranking API | `semantic-ranker-default-004` | Lowest latency, production-grade auth and monitoring |

### `.env.example`
```env
# Environment: local | staging | production
APP_ENV=local

# Reranker provider: gemini_llm | vertex_ai_ranking
# local → gemini_llm
# staging/production → vertex_ai_ranking
RERANKER_PROVIDER=gemini_llm

# Local Gemini reranker (Google AI Studio key)
GEMINI_API_KEY=your_google_ai_studio_api_key
RERANKER_MODEL=gemini-2.5-flash

# Staging / Production — Vertex AI Ranking API
VERTEX_PROJECT_ID=your-gcp-project-id
VERTEX_LOCATION=global
VERTEX_RANKING_MODEL=semantic-ranker-default-004
```

### Python Router Pattern
```python
import os

def get_reranker():
    provider = os.environ.get("RERANKER_PROVIDER", "gemini_llm")
    if provider == "vertex_ai_ranking":
        return VertexAIRankingReranker(
            project_id=os.environ["VERTEX_PROJECT_ID"],
            location=os.environ["VERTEX_LOCATION"],
            model=os.environ["VERTEX_RANKING_MODEL"],
        )
    # Default: Gemini-as-reranker (local dev)
    return GeminiReranker(
        api_key=os.environ["GEMINI_API_KEY"],
        model=os.environ.get("RERANKER_MODEL", "gemini-2.5-flash"),
    )

# Usage — same interface regardless of environment
reranker = get_reranker()
ranked = await reranker.rerank(query=query, documents=candidates, top_n=10)
```

### CI / CD Note
- Local: `.env.local` with `RERANKER_PROVIDER=gemini_llm`
- Staging: Secret Manager or CI env vars with `RERANKER_PROVIDER=vertex_ai_ranking`
- Production: Workload Identity Federation — no API key in env; `VERTEX_PROJECT_ID` only

---

## 6. Recommended Starting Defaults (§10)

Concrete numbers to start with before golden-set tuning. These are starting points — measure and adjust.

### Retrieval Pipeline Defaults

| Stage | Default | Notes |
|---|---|---|
| ANN candidate retrieval (`top_k`) | **80** | Dense + BM25 top-40 each → RRF → 80 deduplicated candidates |
| Post-dedup candidates into reranker | **40–60** | After MMR/dedup; reranking 80 without dedup wastes cost |
| Final context chunks (after reranking) | **5–10** | Send to generation; lower = cheaper + less distraction |

### Chunk Size Defaults by Document Density

| Document Type | Chunk Size | Why |
|---|---|---|
| General knowledge / prose | 500–800 tokens | Enough context; stays within embedding model limits |
| Structured / procedure docs (SOPs, guides) | 300–600 tokens | Denser information per sentence; smaller chunks = more precise retrieval |
| Tables | Full table or row-groups | See `table-chunking-strategy.md` — never split mid-row |
| Event-based records (tickets, logs) | One event per chunk | Natural unit; splitting a ticket across chunks loses context |

### Query Strategy Defaults

```
Always rewrite conversational follow-up queries (resolve pronouns, standalone query)
Apply domain synonym expansion when corpus has known vocabulary gaps
Split multi-part questions before retrieval
Use HyDE only as a fallback for low-confidence retrieval — never on exact facts or legal/contractual content
```

**Tuning discipline:** establish a golden set of ≥50 queries first, measure Recall@5 per query type, then adjust `top_k`, chunk size, and overlap based on where recall falls short — not before.
