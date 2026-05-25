# Query Transformation Guide

Reference for query rewriting, expansion, HyDE, and splitting strategies. Apply when the default single-query retrieval is insufficient (§3 of the production RAG pipeline).

These techniques are **v2 features** — ship the default stack first, measure your top failure modes, then apply only what fixes a measured problem.

---

## 1. When to Apply Query Transformation

| Symptom | Transformation to Apply |
|---|---|
| Follow-up questions ("tell me more about that") retrieve wrong chunks | Query rewriting |
| Domain terminology mismatch (abbreviations, synonyms) | Query expansion |
| Complex multi-part questions get incomplete answers | Query splitting |
| Semantically rich questions miss conceptually related chunks | Multi-query retrieval |
| Dense prose corpus, semantic similarity retrieval underperforms | HyDE |
| Exact facts, numbers, names, legal/contractual content | **No transformation — raw query only** |

---

## 2. Query Rewriting (§3.1)

Reformulates conversational follow-ups into standalone queries using conversation history.

### When to Apply
- Multi-turn chat interfaces where user asks "tell me more" or uses pronouns ("it", "that", "those")
- Queries that refer to entities established in prior turns

### Rewrite Prompt Template
```
You are a query reformulator. Given the conversation history and the latest user message,
rewrite the user message as a standalone, self-contained search query.

Rules:
- Resolve pronouns and references using conversation history
- Keep the query concise (one sentence)
- Do not add information not implied by the conversation
- If the query is already standalone, return it unchanged

Conversation history:
{conversation_history}

Latest user message: {user_message}

Standalone query:
```

### Decision Logic
```python
def should_rewrite(query: str, conversation_history: list) -> bool:
    if not conversation_history:
        return False  # first turn — no context to resolve
    pronouns = {"it", "this", "that", "these", "those", "they", "them", "its"}
    tokens = set(query.lower().split())
    return bool(tokens & pronouns) or len(query.split()) < 5
```

---

## 3. Query Expansion (§3.2)

Adds synonyms and alternate phrasings to catch vocabulary mismatches between user language and document language.

### When to Apply
- Corpus has domain-specific vocabulary, abbreviations, or jargon
- Users often use informal terms; documents use formal or technical terms
- Measured recall gap between dense and BM25 retrieval (BM25 missing exact terms)

### Domain Synonym Table Pattern
Maintain a lookup table per corpus — do not hardcode in prompts:
```python
DOMAIN_SYNONYMS: dict[str, list[str]] = {
    "HVAC": ["air conditioning", "AC", "heating", "ventilation", "climate control"],
    "plumbing": ["water leak", "pipe", "drain", "sewage", "faucet", "toilet"],
    "electrical": ["power outage", "circuit", "breaker", "wiring", "outlet"],
    # Add domain terms as measured recall gaps reveal them
}

def expand_query(query: str, synonyms: dict) -> list[str]:
    expanded = [query]
    for canonical, variants in synonyms.items():
        for variant in variants:
            if variant.lower() in query.lower():
                expanded.append(query.replace(variant, canonical, 1))
    return list(set(expanded))
```

### Application Pattern
```python
# Run all expanded variants; merge results with RRF
all_results = []
for variant in expand_query(query, DOMAIN_SYNONYMS):
    results = retrieve(variant, top_k=20)
    all_results.append(results)
final = rrf_merge(all_results, k=60)
```

### Cost Note
Each expanded variant is an additional embedding + retrieval call. Apply only when domain vocabulary mismatch is measured, not assumed.

---

## 4. Multi-Query Retrieval (§3.3)

Generates N diverse phrasings of the same question; retrieves independently; merges with RRF.

### When to Apply
- Query is ambiguous — could be interpreted multiple ways
- Dense retrieval consistently misses semantically equivalent chunks
- Corpus is large with diverse terminology

### Implementation
```python
MULTI_QUERY_PROMPT = """
Generate {n} different ways to ask the following question. 
Each variant should use different vocabulary but seek the same information.
Return one variant per line, no numbering.

Question: {query}
"""

async def multi_query_retrieve(query: str, n: int = 3, top_k: int = 20) -> list:
    variants = await llm.generate(MULTI_QUERY_PROMPT.format(n=n, query=query))
    all_results = []
    for variant in [query] + variants.strip().split("\n"):
        results = await retrieve(variant.strip(), top_k=top_k)
        all_results.append(results)
    return rrf_merge(all_results, k=60)
```

### Cost Tradeoff
- N=3 variants → 4 embedding calls + 4 retrieval calls (including original)
- Latency: adds ~100–300ms depending on LLM speed
- Only justified when single-query recall is measured to be insufficient

---

## 5. Query Splitting / Decomposition (§3.4)

Detects multi-topic questions and answers each part independently.

### When to Apply
- User asks compound questions: "What is X and how does Y compare to Z?"
- Single retrieval consistently only answers part of the question
- Generation model notes it can only partially answer

### Detection + Split Pattern
```python
SPLIT_PROMPT = """
Does this question contain multiple distinct sub-questions that require separate lookups?
If yes, list each sub-question on its own line.
If no, return the original question unchanged.

Question: {query}
"""

async def split_and_retrieve(query: str) -> str:
    response = await llm.generate(SPLIT_PROMPT.format(query=query))
    sub_queries = [q.strip() for q in response.strip().split("\n") if q.strip()]
    
    if len(sub_queries) <= 1:
        return await retrieve(query)  # no split needed
    
    # Retrieve for each sub-query; merge context
    contexts = []
    for sub_q in sub_queries:
        chunks = await retrieve(sub_q, top_k=10)
        contexts.extend(chunks)
    
    # Deduplicate by chunk_id before packing
    seen = set()
    unique_chunks = [c for c in contexts if c.id not in seen and not seen.add(c.id)]
    return pack_context(unique_chunks[:20])  # token budget
```

### Limit Decomposition Depth
- Maximum 3 sub-queries per question — deeper splits fragment context and hurt synthesis
- If split produces > 3 sub-queries, treat as a summarization request instead

---

## 6. HyDE — Hypothetical Document Embeddings (§3.5)

Generates a hypothetical document that would answer the query; uses its embedding for retrieval instead of the query embedding.

### When HyDE Helps
- Dense prose corpora where query-document semantic gap is large
- Questions are short but target long explanatory passages
- Users ask in different vocabulary than documents use
- Domain: knowledge bases, technical documentation, policy explanations

### When HyDE Hurts (Critical Rule)
**Never apply HyDE when exact accuracy is required:**
- Factual lookups (specific dates, amounts, names, identifiers)
- Legal or contractual content (exact clause wording matters)
- High-stakes answers where hallucination in the hypothetical = wrong retrieval
- Structured data queries (fees, calculations, thresholds)

The hypothetical document is LLM-generated fiction — any hallucination in it biases retrieval toward wrong chunks.

### HyDE Decision Tree
```
Is the query seeking exact facts, numbers, names, or legal text?
  YES → Skip HyDE. Use raw query embedding.

Is the corpus dense prose with semantic vocabulary richness?
  NO  → Skip HyDE. Gain is minimal on keyword-rich corpora.

Does the query describe a concept rather than name a thing?
  YES → HyDE may help. Apply and measure against golden set.
  NO  → Skip HyDE.

Does the answer require precision more than recall?
  YES → Skip HyDE. Prioritize exact retrieval.
  NO  → Apply HyDE.
```

### Implementation
```python
HYDE_PROMPT = """
Write a short passage (2–3 sentences) that directly answers this question.
Write as if you are an expert summarizing relevant information.
Do not add caveats or disclaimers.

Question: {query}
"""

async def hyde_retrieve(query: str, top_k: int = 50) -> list:
    hypothetical_doc = await llm.generate(HYDE_PROMPT.format(query=query))
    # Embed the hypothetical document, not the query
    hypo_embedding = await embed(hypothetical_doc, task_type="RETRIEVAL_DOCUMENT")
    return await vector_search(hypo_embedding, top_k=top_k)
```

---

## 7. Query Transformation Decision Table

| Query Type | Rewrite | Expand | Multi-Query | Splitting | HyDE |
|---|---|---|---|---|---|
| Factual lookup (exact value) | If follow-up | No | No | No | **No** |
| Policy / procedure question | If follow-up | If domain vocab | Optional | If compound | Optional |
| Comparison | No | No | Yes (one per entity) | Yes | No |
| Summarization | No | No | No | No | Yes |
| Multi-hop | No | No | Yes | Yes | No |
| Troubleshooting | If follow-up | Yes (symptom synonyms) | Yes | If multi-symptom | No |
| Personalized | No | No | No | No | No |
| Structured record lookup | No | No | No | No | **No** |

### Rule of Thumb
- Start with no transformation (default stack)
- Measure recall@5 on golden set by query type
- Apply transformation only for query types where measured recall < target
- Re-measure after applying; roll back if no improvement
