---
name: browser-testing
description: Browser automation and testing using Chrome DevTools MCP (debugging, performance, network inspection) and Browser-Use MCP (human-like UI interaction, form filling, E2E flows). Use when the user needs to test web apps, debug browser issues, analyze performance, fill forms, run E2E user flows, or inspect network/console activity.
allowed-tools: Bash(browser-use:*), mcp:chrome-devtools, mcp:browser-use
---

# Browser Automation & Testing Skill

This skill combines **two MCP servers** for complete browser automation:

- **Chrome DevTools MCP** — Inspector, debugger, performance analyzer
- **Browser-Use MCP** — Human-like browser interaction and E2E testing

## When to Use Which Tool

### Chrome DevTools MCP — Use for INSPECTION & DEBUGGING

Use chrome-devtools when the task involves looking under the hood:

- Performance tracing and Core Web Vitals (LCP, CLS, TBT)
- Console error monitoring (`list_console_messages`)
- Network request inspection (`list_network_requests`)
- JavaScript execution in page context (`evaluate_script`)
- DOM and CSS debugging
- CPU/Network throttling (`emulate_cpu`, `emulate_network`)
- Connecting to user's running Chrome session (`--autoConnect`)

#### Chrome DevTools Key Tools

```
navigate_page         → Open a URL
take_snapshot         → Get accessibility tree of page
take_screenshot       → Capture page visual
click                 → Click an element
fill / fill_form      → Fill form fields
hover                 → Trigger hover effects
list_console_messages → View console output (errors, warnings, logs)
list_network_requests → See all HTTP requests/responses
evaluate_script       → Run JavaScript in page context
performance_start_trace → Start recording performance trace
performance_stop_trace  → Stop recording
performance_analyze_insight → Extract performance metrics (LCP, TBT, etc.)
emulate_cpu           → Throttle CPU (test slow devices)
emulate_network       → Throttle network (test slow connections)
resize_page           → Change viewport size
```

### Browser-Use MCP — Use for USER INTERACTION & E2E FLOWS

Use browser-use when the task involves acting like a human user:

- Filling out forms step by step
- Multi-step user flows (signup → verify → dashboard)
- Testing UI interactions (click, type, select, scroll)
- Running parallel browser sessions
- Using real Chrome with existing logins (`--browser real`)
- Element-by-index interaction for precise control

#### Browser-Use Key Commands

```
browser_navigate      → Open a URL
browser_get_state     → Get all interactive elements with indices (DO NOT include screenshots unless asked)
browser_click         → Click element by index
browser_type          → Type text into focused element
browser_input         → Click element then type text
browser_select        → Select dropdown option
browser_scroll        → Scroll up/down
browser_keys          → Send keyboard shortcuts
browser_switch_tab    → Switch between tabs
browser_close         → Close browser session
```

## Combined Workflow Pattern

The most powerful approach is using BOTH together:

1. **Chrome DevTools** monitors the internals (network, console, performance)
2. **Browser-Use** performs user actions (click, fill, navigate)
3. **Chrome DevTools** checks for errors after each action

### Example: Testing a Login Flow with Full Debugging

```
Step 1: Open the app with chrome-devtools
  → navigate_page to localhost:4200
  → Start monitoring console and network

Step 2: Use browser-use to interact like a user
  → browser_navigate to localhost:4200/login
  → browser_get_state (NO screenshot) to see form elements
  → browser_input [email_index] "test@example.com"
  → browser_input [password_index] "password123"
  → browser_click [submit_index]

Step 3: Check chrome-devtools for issues
  → list_console_messages — any errors after submit?
  → list_network_requests — did the API call succeed? What status code?
  → evaluate_script — check auth token in localStorage?
```

### Example: Performance Testing

```
Step 1: Use chrome-devtools for performance
  → navigate_page to the target URL
  → performance_start_trace
  → Wait for page load
  → performance_stop_trace
  → performance_analyze_insight "LCPBreakdown"
  → performance_analyze_insight "RenderBlocking"

Step 2: Emulate slow conditions
  → emulate_network "Slow 3G"
  → emulate_cpu 4x slowdown
  → Repeat performance trace
  → Compare results
```

### Example: E2E User Flow Testing

```
Step 1: Use browser-use for the full user journey
  → browser_navigate to /signup
  → browser_get_state (NO screenshot)
  → Fill all form fields using browser_input
  → browser_click submit
  → browser_get_state to verify redirect to /dashboard

Step 2: Use chrome-devtools to validate
  → list_network_requests — check all API calls succeeded
  → list_console_messages — no errors during flow
  → evaluate_script "document.cookie" — verify session cookie set
```

## Critical Rules

1. **NEVER include screenshots in browser_get_state** unless the user explicitly asks for one. Screenshots cause token overflow (126K+ characters).
2. **Pick the right tool for the job** — don't use browser-use for console errors, don't use chrome-devtools for complex form filling.
3. **Always close browsers when done** — `browser_close` for browser-use sessions.
4. **For chrome-devtools screenshots**, use `take_screenshot` which is optimized and doesn't cause overflow.
5. **When tasks require BOTH tools**, start chrome-devtools first for monitoring, then use browser-use for interaction, then check chrome-devtools for results.

## Decision Quick Reference

| Need to... | Use |
|---|---|
| Check console errors | chrome-devtools: `list_console_messages` |
| Monitor network requests | chrome-devtools: `list_network_requests` |
| Run performance trace | chrome-devtools: `performance_start_trace` |
| Execute JavaScript on page | chrome-devtools: `evaluate_script` |
| Inspect DOM/CSS | chrome-devtools: `take_snapshot` |
| Test on slow network/CPU | chrome-devtools: `emulate_network` / `emulate_cpu` |
| Fill out a form | browser-use: `browser_input` |
| Click buttons/links | browser-use: `browser_click` |
| Test full user flow | browser-use: navigate → get_state → input → click → verify |
| Test with real logged-in Chrome | browser-use: `--browser real` |
| Debug + Test together | chrome-devtools monitors, browser-use acts |
