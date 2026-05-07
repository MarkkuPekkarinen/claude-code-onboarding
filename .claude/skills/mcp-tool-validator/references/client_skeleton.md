# MCP Test Client — Internals Reference

Read this only when modifying `mcp_test_client.py` itself (e.g., adding a new transport, supporting auth headers, or changing session lifecycle).

## Architecture

```
┌────────────────────────────────────────────────┐
│  main() / main_async()                         │
│   ↓                                            │
│  MCPTestClient(server_url, transport)          │
│   ├─ list_tools()      → ['tool_a', 'tool_b']  │
│   └─ run_scenarios()   → [ScenarioResult, ...] │
│        ↓                                       │
│      _run_one()                                │
│        ↓                                       │
│      AssertionEngine.evaluate()                │
│        ↓                                       │
│      _assert_<name>()  (one per assertion)     │
└────────────────────────────────────────────────┘
```

## Transport detection

`MCPTestClient._detect_transport(url)` chooses based on URL prefix:
- `stdio://command args` → stdio_client (subprocess)
- `*/sse` → sse_client (legacy SSE)
- everything else → streamablehttp_client (modern HTTP)

To force a transport, pass `--transport {stdio,sse,http}`.

## Session lifecycle

Each call to `list_tools()` or `run_scenarios()` opens its own session.
For 15 tools × 3 scenarios = 45 calls, this happens inside ONE session
(see `run_scenarios` — the async-with block wraps the loop).

If a scenario hangs the session (e.g., long-running tool with no timeout),
the entire run hangs. Mitigations:
1. Add `max_duration_ms` to every scenario as a soft timeout signal
2. Wrap `session.call_tool()` in `asyncio.wait_for()` if needed (not yet
   in skeleton — add per-project)

## Adding auth

For tools requiring auth, two options:

**Option A — environment variables (recommended for local dev)**
The MCP server reads its own auth from env. Set in docker-compose.

**Option B — per-request headers (HTTP only)**
Modify `_open_session()` to pass headers to `streamablehttp_client`.
The MCP SDK supports this via the `headers` kwarg.

```python
def _open_session(self):
    if self.transport == "http":
        headers = {"Authorization": f"Bearer {os.environ['MCP_TOKEN']}"}
        return streamablehttp_client(self.server_url, headers=headers)
    ...
```

## Adding a new transport

1. Add a branch in `_detect_transport()` and `_open_session()`
2. Import the SDK's client constructor
3. Ensure the constructor returns `(read, write, ...)` streams compatible
   with `ClientSession`

## Performance notes

- `tools/list` is called twice per validation run (once by the test client,
  once by `validate_coverage.py`). Cheap — don't optimize.
- For 100+ scenarios, consider parallel `call_tool` invocations using
  `asyncio.gather` — but be aware some MCP servers serialize requests.
- The assertion engine is pure-Python and runs in microseconds. Don't optimize.

## Testing the test client itself

Trust but verify. Add a smoke test:

```python
# tests/test_mcp_test_client_self.py
import pytest
from mcp_test_client import AssertionEngine

def test_content_contains_passes_when_present():
    eng = AssertionEngine()
    class FakeResponse:
        isError = False
        content = [type("X", (), {"type": "text", "text": "hello world"})()]
    assert eng._assert_content_contains("hello", FakeResponse()) is None

def test_content_contains_fails_when_missing():
    eng = AssertionEngine()
    class FakeResponse:
        isError = False
        content = [type("X", (), {"type": "text", "text": "hello world"})()]
    msg = eng._assert_content_contains("goodbye", FakeResponse())
    assert "missing" in msg
```
