---
name: streaming-protocols
description: "Use when designing or debugging streaming in AI systems — SSE, NDJSON, HTTP Streaming, WebSocket, MCP transport, or A2UI transport. Covers the three-layer mental model, bidirectionality, real-world wire formats (OpenAI, Anthropic, MCP), production pitfalls (proxy buffering, compression, mobile reconnection), and the decision guide for which protocol to use when."
allowed-tools: Read, Grep, Glob, Bash, WebFetch
metadata:
  triggers: SSE, server-sent events, NDJSON, HTTP streaming, WebSocket, streaming protocol, MCP transport, streamable HTTP, bidirectional streaming, traceparent, streaming AI, token streaming
  related-skills: a2ui-angular, mcp-builder, agentic-ai-dev
  domain: infrastructure
  role: reference
  scope: architecture
  output-format: guidance
last-reviewed: "2026-05-25"
---

# Streaming Protocols for AI Systems

## Iron Law

**Pick one option from each of the three layers (Transport / Framing / Message). The "which protocol?" question answers itself.**

Most streaming confusion comes from treating options at different layers as alternatives. They compose — they are not competitors.

---

## 1. The Three-Layer Mental Model

```
┌─────────────────────────────────────────────────────────┐
│  MESSAGE LAYER — what each message means                │
│  JSON-RPC · A2UI envelope · OpenAI delta · plain JSON   │
├─────────────────────────────────────────────────────────┤
│  FRAMING LAYER — how messages are delimited             │
│  SSE events · NDJSON lines · HTTP chunks · WS frames    │
├─────────────────────────────────────────────────────────┤
│  TRANSPORT LAYER — the connection itself                │
│  HTTP · HTTP Streaming · WebSocket · stdio              │
└─────────────────────────────────────────────────────────┘
```

```
Transport opens the pipe.
Framing chops the pipe into messages.
Message format gives each message meaning.
```

**The most common real-world stack:**

```
HTTP Streaming (transport)
  └── SSE (framing)
        └── JSON-RPC or provider-specific JSON (message)
```

**For tool/agent IPC:**

```
stdio (transport)
  └── newline-delimited JSON (framing)
        └── JSON-RPC 2.0 (message)
```

---

## 2. SSE vs HTTP Streaming — The Core Confusion

**SSE is not a competitor to HTTP Streaming. SSE is one *kind* of HTTP Streaming.**

```
HTTP Streaming  (the behavior: server sends response gradually)
    │
    ├── SSE                 ← text/event-stream, blank-line framed
    ├── NDJSON              ← one JSON object per line
    ├── Chunked HTML        ← progressive page rendering
    ├── Raw binary chunks   ← video/audio, file downloads
    └── Custom formats      ← gRPC-Web, protobuf streams
```

Asking "SSE vs HTTP Streaming" is like asking "JSON vs HTTP body" — JSON is *one of the things* you can put in a body.

**Why people conflate them:**

1. In browsers, `EventSource` is the only ergonomic way to consume HTTP streams. Everything else requires `fetch()` + `ReadableStream` + manual byte parsing.
2. ChatGPT, Claude, Perplexity all use SSE — so "streaming response" colloquially means "SSE response."
3. MCP's transport naming confused everyone: the old transport was "HTTP+SSE"; the new one is "Streamable HTTP" — these sound like alternatives when they're not.

**When to pick which framing:**

| Scenario | Best framing | Why |
|----------|-------------|-----|
| Browser receives live updates | **SSE** | Native `EventSource`, auto-reconnect, simple to parse |
| AI agent token streaming to a UI | **SSE** | Browser-friendly, typed event names for tool use |
| Server-to-server streaming | NDJSON | No event-name overhead, easy to log/replay |
| Batch processing pipelines | NDJSON | Line-addressable, replayable, strong tooling |
| stdio IPC (MCP local) | NDJSON | OS-pipe-friendly newline framing |
| Binary data (video, files) | Raw chunks | No text encoding overhead |
| gRPC internal ML platforms | gRPC frames | Strong types, multiplexing, codegen |

---

## 3. Bidirectionality — Half-Duplex vs Full-Duplex

| | HTTP/1.1 Streaming | HTTP/2 Streaming | WebSocket |
|--|-------------------|-----------------|-----------|
| Direction per stream | Half-duplex | Half-duplex within a stream | **Full-duplex** |
| Bidirectional in practice? | Only by opening 2+ requests | Yes, via separate streams | Yes, natively |
| Auto-reconnect? | Yes (SSE `Last-Event-ID`) | Per protocol | No — implement yourself |
| Works through corporate proxies? | Almost always | Almost always | Often blocked or buggy |
| Good for AI token streaming? | **Yes** (standard choice) | Yes | Overkill |
| Good for voice / collab editing? | No | Marginal | **Yes** |
| Server can initiate? | No (only respond) | Server push (limited) | Yes, anytime |

**The crisp distinction:**

```
HTTP Streaming = one-direction-at-a-time per request (walkie-talkie)
WebSocket      = both-directions-simultaneously on one connection (phone call)
```

**Why ChatGPT's "stop generating" button closes the connection:** once the POST is sent, the client is in receive-only mode. There's no upstream channel to send a "stop" message on. The only option is to drop the connection.

**Pick HTTP Streaming (SSE) when:**
- Data flow is dominantly server → client
- You need to traverse corporate proxies and CDNs reliably
- You want browser auto-reconnect and resumability for free
- You're streaming LLM tokens, agent progress, A2UI updates

**Pick WebSocket when:**
- Genuinely simultaneous bidirectional flow (voice, multiplayer, collab editing)
- Frequent small messages in both directions
- Server initiates messages as often as the client does

**Practical reality for AI apps:** 95% of the time, SSE is the right choice. WebSocket earns its weight for voice and collaborative editing — not for token streaming.

---

## 4. MCP Bidirectionality Pattern (How HTTP Fakes Full-Duplex)

MCP needs bidirectional communication (clients call tools; servers call back via `sampling/createMessage`, `roots/list`, elicitation). It achieves this over half-duplex HTTP using two simultaneous requests:

```
CLIENT                                MCP SERVER
  │                                     │
  │── POST /mcp (tools/call) ──────────►│
  │◄── HTTP 200, SSE response ──────────│  ← Stream A: responds to client POST
  │◄── data: {progress notification}    │
  │◄── data: {final result}             │
  │                                     │
  │── GET  /mcp (Accept: SSE) ─────────►│
  │◄── HTTP 200, SSE response ──────────│  ← Stream B: long-lived GET for
  │◄── data: {server→client request}    │    server-initiated messages
  │                                     │
  │── POST /mcp (response to above) ───►│  ← Client replies via new POST
  │◄── HTTP 200 ────────────────────────│
```

"Bidirectional messaging" in MCP = messages flow in both directions across two streams, **not** both directions on a single TCP stream.

**Two headers that carry the operational glue:**

| Header | Purpose |
|--------|---------|
| `Mcp-Session-Id` | Set by server at init. Must be echoed on every subsequent request. Missing = silent state bugs. |
| `Last-Event-ID` | Standard SSE header. Client sends last received ID on reconnect; server replays missed events. |

**SSE deprecation note:** SSE was deprecated as a *standalone MCP transport* (March 2025, replaced by Streamable HTTP). SSE itself is alive and well for LLM streaming, dashboards, and all browser-facing live updates.

---

## 5. Real-World Wire Formats

### OpenAI / Compatible APIs (SSE, bare JSON)

```
data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":"The"},"index":0}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":" answer"},"index":0}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{},"finish_reason":"stop","index":0}]}

data: [DONE]
```

- Bare JSON (not JSON-RPC) — request/response pairing is implicit in the HTTP exchange
- `[DONE]` sentinel is OpenAI's convention, not part of the SSE spec
- Client extracts `choices[0].delta.content` and appends to rendered message

### Anthropic (SSE, typed events)

```
event: message_start
data: {"type":"message_start","message":{"id":"msg_01...","role":"assistant"}}

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"The answer"}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: message_stop
data: {"type":"message_stop"}
```

- `event:` field carries semantic type — clients dispatch on type rather than inspecting payload shape
- Makes tool use, thinking blocks, and multi-modal content cleaner to handle
- Mid-stream errors arrive as `event: error` with HTTP status still 200

### MCP (JSON-RPC over SSE or newline-delimited)

```
event: message
data: {"jsonrpc":"2.0","method":"notifications/progress","params":{"progressToken":"t1","progress":30}}

event: message
data: {"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"done"}]}}
```

### A2UI over SSE

```
event: a2ui
data: {"version":"v0.9","createSurface":{"surfaceId":"ticket_1","catalogId":"..."}}

event: a2ui
data: {"version":"v0.9","updateDataModel":{"surfaceId":"ticket_1","path":"/status","value":"Open"}}
```

### A2UI over NDJSON (replay / eval / debugging)

```jsonl
{"version":"v0.9","createSurface":{"surfaceId":"ticket_1","catalogId":"..."}}
{"version":"v0.9","updateDataModel":{"surfaceId":"ticket_1","path":"/status","value":"Open"}}
{"version":"v0.9","updateComponents":{"surfaceId":"ticket_1","components":[...]}}
```

---

## 6. Production Pitfalls Checklist

### ❌ Proxy Buffering (Silent Stream Killer)
Nginx, CloudFront, and most CDNs buffer responses by default. Your "streaming" tokens arrive in one batch.

**Fix:**
```nginx
location /stream {
  proxy_buffering off;
  add_header X-Accel-Buffering no;
}
```
Also set `X-Accel-Buffering: no` as a response header from your app server.

### ❌ gzip / Brotli Breaks SSE
Compression middleware accumulates bytes before compressing — turns smooth token flow into chunky bursts.

**Fix:** Disable compression for `text/event-stream` responses. The bandwidth saving is not worth the latency cost.

```ts
// Express example
app.use(compression({
  filter: (req, res) => {
    if (res.getHeader('Content-Type') === 'text/event-stream') return false;
    return compression.filter(req, res);
  },
}));
```

### ❌ SSE Connection Timeouts on Long Agent Runs
Long agent runs exceed default proxy timeouts (often 60s). Connection drops mid-stream.

**Fix:** Send periodic keepalive comments:
```
: keepalive

```
(A colon-prefixed line is an SSE comment — ignored by clients, but prevents timeout.)

### ❌ Mobile Reconnection Without `Last-Event-ID`
iOS kills HTTP connections when the app backgrounds. Without `Last-Event-ID`, the stream restarts from scratch on reconnect.

**Fix:**
1. Include `id:` field on every SSE event
2. Buffer events server-side for ≥60 seconds after sending
3. On reconnect, client sends `Last-Event-ID` header; server replays from that point

```ts
// Client: use exponential backoff — default EventSource reconnect is too aggressive
const es = new EventSource('/stream');
let retryDelay = 1000;
es.onerror = () => {
  setTimeout(() => reconnect(), retryDelay);
  retryDelay = Math.min(retryDelay * 2, 30000);
};
```

4. Surface "reconnecting..." state to the user — silent staleness is worse than a visible indicator
5. For long agent runs (>10 min backgrounded): provide a polling fallback that returns current state

### ❌ Missing `traceparent` Propagation
A single user action may generate 30+ network calls. Without a correlation ID, cross-service debugging is impossible.

**Fix:** Generate `traceparent` (W3C Trace Context) at the edge; forward it on every outbound call.

```
User action
  └─► Backend generates traceparent: 00-{trace_id}-{span_id}-01
        ├─► POST to LLM API — Header: traceparent
        ├─► POST to MCP server — Header: traceparent, Mcp-Session-Id
        └─► SSE response to client — echo traceparent back
```

Every modern observability tool (Langfuse, Datadog, Honeycomb, Grafana Tempo) understands `traceparent`. Include it in NDJSON logs so you can join logs across services after the fact.

### ❌ Conflating JSON-RPC `id` and SSE `id`
They are unrelated and live at different layers.

| Field | Layer | Purpose |
|-------|-------|---------|
| JSON-RPC `id` | Message | Correlates request to response within a JSON-RPC session |
| SSE `id` | Framing | Enables reconnection via `Last-Event-ID` header |

### ❌ Treating Streamable HTTP and SSE as Competitors
Streamable HTTP (MCP) is a *transport pattern*. SSE is *one of the response formats* Streamable HTTP can return. They compose.

### ❌ WebSocket "Because It's Realtime"
If data flow is server→client only (which most LLM streaming is), WebSocket adds operational complexity without benefit. SSE is simpler, proxy-friendly, and auto-reconnecting. Reach for WebSocket only when you genuinely need bidirectional realtime.

---

## 7. Decision Guide

| Your need | Transport | Framing | Message |
|-----------|-----------|---------|---------|
| Chat UI with token streaming | HTTP Streaming | SSE | Provider JSON (OpenAI/Anthropic) |
| Local AI app calling tools | stdio | newline-delimited | JSON-RPC (MCP) |
| Remote AI app calling tools | HTTP Streaming | JSON or SSE | JSON-RPC (MCP) |
| Agent pushing UI updates (A2UI) | HTTP Streaming | SSE | A2UI envelope |
| Recording agent runs (eval/replay) | File / HTTP POST | NDJSON | App-specific trace |
| Bulk LLM inference | HTTP | NDJSON | Provider JSON (Batch API) |
| Voice / collaborative editing | WebSocket | WS frames | App-specific |
| High-perf server-to-server AI | HTTP/2 | gRPC frames | Protobuf |
| Simple one-shot answer | HTTP | — | Plain JSON |

---

## 8. NDJSON's Real-World Niche

NDJSON rarely appears in the live request path (SSE wins there). It dominates in three places:

1. **stdio IPC** — MCP local servers, language servers, CLI tools. Newline framing is OS-pipe-friendly.
2. **Batch / bulk APIs** — OpenAI Batch API, Anthropic Batch API return NDJSON. Common Crawl, eval traces, log shipping (Vector, Fluent Bit) all favor NDJSON.
3. **Replay and eval** — Recording an agent run as NDJSON gives a perfect, line-addressable trace. Langfuse, Braintrust, W&B Weave ingest these directly.

```
SSE        → live, server→client, browser-facing
NDJSON     → batch, logs, replay, stdio, server-to-server
WebSocket  → genuinely bidirectional realtime (voice, collab editing)
Plain JSON → one-shot response, no streaming needed
```

---

## Cheat Sheet

**Three rules that catch 90% of bugs:**

1. Don't compress SSE responses — it buffers your stream into chunky bursts.
2. Echo `Mcp-Session-Id` on every MCP request after init, or session state silently breaks.
3. Propagate `traceparent` across every layer, or you'll never debug a multi-hop agent failure.

**The four real-world stacks:**

| Stack | Transport | Framing | Message |
|-------|-----------|---------|---------|
| Chat token streaming | HTTP Streaming | SSE | Provider JSON |
| MCP (local) | stdio | newline-delimited | JSON-RPC |
| MCP (remote) | HTTP Streaming | JSON or SSE | JSON-RPC |
| Generative UI (A2UI) | HTTP Streaming | SSE | A2UI envelope |
