# Playwright MCP (playwright-cli) — Tool Reference

Playwright MCP (`@playwright/mcp`) is the deterministic browser automation tool for Claude Code. It exposes Playwright's full API as MCP tools — typed, reliable, and inspectable. All tools are prefixed `mcp__playwright__` in Claude Code.

## Navigation

### browser_navigate
Navigate to a URL or perform navigation actions.

```
mcp__playwright__browser_navigate({
  url: "https://localhost:4200/login"
})
```

**Params:** `url` (string, required) — absolute URL including scheme.

---

### browser_snapshot
Get the accessibility tree of the current page. Use this to find element references for clicking, filling, and hovering. Cheaper than a screenshot — use this first.

```
mcp__playwright__browser_snapshot()
```

Returns: structured accessibility tree with `ref` identifiers for each interactive element.

**Rule:** Use `browser_snapshot` to discover element refs before `browser_click` or `browser_fill`. Never hard-code refs — they change between renders.

---

### browser_screenshot
Capture a screenshot of the current page. Safe — does not overflow context.

```
mcp__playwright__browser_screenshot({
  filename: "login-page.png",   // optional — omit to get base64 inline
  fullPage: false               // true = full scrollable page
})
```

**Rule:** Use this for visual evidence in test reports. NOT `browser_get_state({ include_screenshot: true })` from Browser-Use.

---

## Interaction

### browser_click
Click an element using its accessibility ref from `browser_snapshot`.

```
mcp__playwright__browser_click({
  ref: "button-submit-3"     // ref from browser_snapshot output
})
```

---

### browser_fill
Fill an input field by ref.

```
mcp__playwright__browser_fill({
  ref: "input-email-1",
  value: "user@example.com"
})
```

---

### browser_type
Type text into the currently focused element character by character (simulates keystrokes).

```
mcp__playwright__browser_type({
  text: "Hello World"
})
```

Use `browser_fill` for most inputs. Use `browser_type` only when keystroke-by-keystroke simulation matters (e.g. autocomplete triggers).

---

### browser_select_option
Select an option from a `<select>` dropdown.

```
mcp__playwright__browser_select_option({
  ref: "select-country-2",
  values: ["AU"]      // option value, not label
})
```

---

### browser_hover
Move the mouse over an element (triggers hover states, tooltips).

```
mcp__playwright__browser_hover({
  ref: "button-menu-4"
})
```

---

### browser_press_key
Press a keyboard key or shortcut.

```
mcp__playwright__browser_press_key({
  key: "Enter"          // also: "Tab", "Escape", "ArrowDown", "Control+a"
})
```

---

### browser_handle_dialog
Accept or dismiss a browser dialog (alert, confirm, prompt).

```
mcp__playwright__browser_handle_dialog({
  accept: true,
  promptText: "optional text for prompt dialogs"
})
```

Set this BEFORE the action that triggers the dialog.

---

### browser_upload_file
Upload a file via a file input element.

```
mcp__playwright__browser_upload_file({
  ref: "input-file-upload-1",
  paths: ["/tmp/test-document.pdf"]
})
```

---

## Inspection

### browser_network_requests
Return all network requests made since the page loaded (or since last navigation).

```
mcp__playwright__browser_network_requests()
```

Returns: array of `{ url, method, status, timing }` objects.

**When to use:** After every form submission, button click, or navigation to verify API calls succeeded.

---

### browser_console_messages
Return all console messages (log, warn, error) from the current page session.

```
mcp__playwright__browser_console_messages()
```

Returns: array of `{ type, text, location }` objects.

**Rule:** Any `error` type message = automatic NEEDS WORK in validation reviews. Check after every critical action.

---

### browser_evaluate
Execute arbitrary JavaScript in the page context and return the result.

```
mcp__playwright__browser_evaluate({
  expression: "localStorage.getItem('authToken')"
})

// Multi-line
mcp__playwright__browser_evaluate({
  expression: "JSON.parse(localStorage.getItem('user') || '{}')"
})
```

**Common uses:** Check localStorage/sessionStorage, read DOM state, verify Angular component state.

---

## Page Control

### browser_wait_for
Wait for a CSS selector to be visible, or for the network to be idle.

```
// Wait for element
mcp__playwright__browser_wait_for({
  selector: ".dashboard-container",
  state: "visible",       // visible | hidden | attached | detached
  timeout: 5000
})

// Wait for network idle (all requests complete)
mcp__playwright__browser_wait_for({
  waitForNetwork: true,
  timeout: 10000
})
```

---

### browser_resize
Set the browser viewport dimensions.

```
mcp__playwright__browser_resize({
  width: 375,
  height: 812    // iPhone 14 viewport
})
```

Common viewports:
- Mobile: `375 × 812` (iPhone 14)
- Tablet: `768 × 1024` (iPad)
- Desktop: `1280 × 720`

---

### browser_close
Close the current browser context.

```
mcp__playwright__browser_close()
```

---

## Tabs

### browser_tab_new
Open a new tab and navigate to a URL.

```
mcp__playwright__browser_tab_new({
  url: "https://localhost:4200/dashboard"
})
```

---

### browser_tab_list
List all open tabs.

```
mcp__playwright__browser_tab_list()
```

---

### browser_tab_close
Close a specific tab by index.

```
mcp__playwright__browser_tab_close({
  index: 1
})
```

---

## Performance Tracing

### browser_start_tracing
Begin recording a Playwright performance trace. Captures network timing, CPU, screenshots timeline.

```
mcp__playwright__browser_start_tracing({
  screenshots: true,
  snapshots: true
})
```

---

### browser_stop_tracing
Stop recording and save the trace file.

```
mcp__playwright__browser_stop_tracing({
  path: "./trace.zip"
})
```

View with: `npx playwright show-trace trace.zip`

---

## PDF

### browser_pdf_save
Save the current page as a PDF.

```
mcp__playwright__browser_pdf_save({
  path: "./page-output.pdf"
})
```

---

## Install & MCP Config

```bash
# Install
npm install -g @playwright/mcp@latest

# Install browsers (first time)
npx playwright install chromium
```

`.mcp.json` entry:
```json
"playwright": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@playwright/mcp@latest"],
  "timeout": 60000
}
```

---

## playwright-cli vs browser-use vs chrome-devtools

| Task | playwright-cli | browser-use |
|------|---------------|-------------|
| Scripted test steps | ✅ Preferred | Works |
| Network request list | ✅ `browser_network_requests` | ❌ Not available |
| Console messages | ✅ `browser_console_messages` | ❌ Not available |
| Execute JS | ✅ `browser_evaluate` | ❌ Not available |
| Performance trace | ✅ `browser_start_tracing` | ❌ Not available |
| Autonomous goal completion | ❌ Needs scripting | ✅ Preferred |
| Real Chrome with existing login | Limited | ✅ `--browser real` |

**Rule:** Default to playwright-cli. Switch to browser-use only for autonomous/exploratory tasks where you describe a goal, not steps.
