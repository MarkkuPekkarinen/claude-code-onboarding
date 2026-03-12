# RAG Pipeline Patterns

## Table of Contents
1. [Chunking Strategies](#chunking-strategies)
2. [Embedding Pipeline](#embedding-pipeline)
3. [pgvector Retrieval](#pgvector-retrieval)
4. [Weaviate Retrieval](#weaviate-retrieval)
5. [Reranking](#reranking)
6. [LangChain Integration](#langchain-integration)
7. [Two-Stage Retrieval](#two-stage-retrieval)

---

## Chunking Strategies

Choose chunking before writing any pipeline code.

| Strategy | Chunk Size | Overlap | Use When |
|----------|-----------|---------|---------|
| Fixed token | 512 tokens | 50 | General text, uniform docs |
| Sentence | 3-5 sentences | 1 sentence | Conversational text, Q&A |
| Paragraph | 1 paragraph | 0 | Structured docs, reports |
| Semantic | Variable | N/A | When chunk coherence matters most |
| Recursive | 1000 chars → split at `\n\n` → `\n` → ` ` | 200 | Unstructured text (default for most RAG) |

```python
from langchain.text_splitter import RecursiveCharacterTextSplitter

# Production default — handles most document types
splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    length_function=len,
    separators=["\n\n", "\n", ". ", " ", ""],
)

chunks = splitter.split_text(document_text)
```

---

## Embedding Pipeline

```python
import asyncio
from openai import AsyncOpenAI
from typing import List

client = AsyncOpenAI()

# Batch embedding with rate limiting
async def embed_texts(
    texts: List[str],
    model: str = "text-embedding-3-small",
    batch_size: int = 100,
) -> List[List[float]]:
    """Embed texts in batches. model dimension must match schema."""
    all_embeddings = []

    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        response = await client.embeddings.create(
            input=batch,
            model=model,
        )
        embeddings = [item.embedding for item in response.data]
        all_embeddings.extend(embeddings)

    return all_embeddings


# Pinned model wrapper — prevents accidental model drift
class EmbeddingService:
    MODEL = "text-embedding-3-small"  # pin here, not at call site
    DIMS = 1536

    def __init__(self):
        self._client = AsyncOpenAI()

    async def embed(self, text: str) -> List[float]:
        response = await self._client.embeddings.create(
            input=text,
            model=self.MODEL,
        )
        return response.data[0].embedding

    async def embed_batch(self, texts: List[str]) -> List[List[float]]:
        return await embed_texts(texts, model=self.MODEL)
```

---

## pgvector Retrieval

```python
import asyncpg
from typing import List, Tuple

async def search_vendors(
    pool: asyncpg.Pool,
    query_embedding: List[float],
    city: str,
    category: str,
    limit: int = 10,
) -> List[dict]:
    """Semantic vendor search with structured filters."""
    rows = await pool.fetch(
        """
        SELECT
            id,
            name,
            city,
            category,
            rating,
            1 - (embedding <=> $1::vector) AS similarity
        FROM vendors
        WHERE city = $2
          AND category = $3
          AND embedding IS NOT NULL
        ORDER BY embedding <=> $1::vector
        LIMIT $4
        """,
        query_embedding,
        city,
        category,
        limit,
    )
    return [dict(r) for r in rows]


# With dynamic filters
async def search_with_filters(
    pool: asyncpg.Pool,
    query_embedding: List[float],
    filters: dict,
    limit: int = 10,
) -> List[dict]:
    """Build filter clause dynamically."""
    where_clauses = ["embedding IS NOT NULL"]
    params = [query_embedding]
    idx = 2

    if city := filters.get("city"):
        where_clauses.append(f"city = ${idx}")
        params.append(city)
        idx += 1

    if min_rating := filters.get("min_rating"):
        where_clauses.append(f"rating >= ${idx}")
        params.append(min_rating)
        idx += 1

    params.append(limit)

    sql = f"""
        SELECT id, name, 1 - (embedding <=> $1::vector) AS similarity
        FROM vendors
        WHERE {" AND ".join(where_clauses)}
        ORDER BY embedding <=> $1::vector
        LIMIT ${idx}
    """

    rows = await pool.fetch(sql, *params)
    return [dict(r) for r in rows]
```

---

## Weaviate Retrieval

```python
import weaviate
import weaviate.classes as wvc

def retrieve_vendor_reviews(
    client: weaviate.WeaviateClient,
    query: str,
    vendor_id: str | None = None,
    alpha: float = 0.75,
    limit: int = 10,
) -> list[dict]:
    """Hybrid search on Weaviate with optional vendor filter."""
    collection = client.collections.get("VendorReview")

    filters = None
    if vendor_id:
        filters = wvc.query.Filter.by_property("vendor_id").equal(vendor_id)

    result = collection.query.hybrid(
        query=query,
        alpha=alpha,
        fusion_type=wvc.query.HybridFusion.RELATIVE_SCORE,
        filters=filters,
        limit=limit,
        return_metadata=wvc.query.MetadataQuery(score=True),
    )

    return [
        {
            "text": obj.properties["text"],
            "source": obj.properties.get("source"),
            "score": obj.metadata.score,
        }
        for obj in result.objects
    ]
```

---

## Reranking

**Rule:** Always rerank for production. Initial retrieval (vector/hybrid) optimizes recall; reranking optimizes precision.

```python
import cohere

co = cohere.Client(os.environ["COHERE_API_KEY"])

def rerank_results(
    query: str,
    documents: list[dict],
    text_key: str = "text",
    top_n: int = 5,
    model: str = "rerank-english-v3.0",
) -> list[dict]:
    """Rerank retrieved documents by relevance to query."""
    if not documents:
        return []

    texts = [doc[text_key] for doc in documents]

    reranked = co.rerank(
        model=model,
        query=query,
        documents=texts,
        top_n=top_n,
    )

    return [
        {
            **documents[r.index],
            "rerank_score": r.relevance_score,
        }
        for r in reranked.results
    ]


# Full pipeline: retrieve → rerank
async def retrieve_and_rerank(
    query: str,
    query_embedding: list[float],
    pool: asyncpg.Pool,
    top_k_retrieve: int = 20,  # retrieve more, rerank down
    top_k_final: int = 5,
) -> list[dict]:
    candidates = await search_vendors(pool, query_embedding, limit=top_k_retrieve)
    return rerank_results(query, candidates, top_n=top_k_final)
```

---

## LangChain Integration

For LangChain-based pipelines, use `PGVector` from `langchain_community.vectorstores.pgvector` with `OpenAIEmbeddings(model=EMBEDDING_MODEL)`. Set `distance_strategy="cosine"` to match the index ops class. See the `agentic-ai-dev` skill for full LangGraph + RAG patterns.

---

## Two-Stage Retrieval

Pattern: pgvector (structured DB data) → Weaviate (external docs) → merge → rerank.

Key rules:
- Retrieve `N×3` candidates from each stage, rerank down to `N` final
- Tag each result with `"source": "internal"` or `"source": "external"` before merging
- Run `rerank_results(query, all_candidates)` across the merged list — not separately per stage
- Log `pg_candidates` and `weaviate_candidates` counts for observability

Full pattern: use `/scaffold-rag-pipeline --storage=both` to generate the complete implementation.
