# Browser Testing — Combined Workflow Patterns

## The Power of Combining Both Tools

The most effective testing approach uses **both Playwright MCP and Browser-Use together**:

1. **Playwright MCP** monitors the internals (network, console, performance)
2. **Browser-Use** performs user actions (click, fill, navigate)
3. **Playwright MCP** checks for errors after each action

This gives you both the **user perspective** (what they see/do) and the **technical perspective** (what's happening under the hood).

---

## Pattern 1: Login Flow with Full Debugging

**Goal:** Test login functionality while monitoring network requests and console errors.

### Step 1: Open with Playwright MCP

```typescript
// Start monitoring
mcp__playwright__new_page({ url: "http://localhost:4200" })
mcp__playwright__browser_navigate({ type: "url", url: "http://localhost:4200/login" })
```

### Step 2: Use Browser-Use for User Interaction

```typescript
// Act like a real user
mcp__browser-use__browser_navigate({ url: "http://localhost:4200/login" })
mcp__browser-use__browser_get_state({ include_screenshot: false })

// Example response shows:
// index: 4 = email input
// index: 5 = password input
// index: 6 = submit button

mcp__browser-use__browser_input({ index: 4, text: "test@example.com" })
mcp__browser-use__browser_input({ index: 5, text: "password123" })
mcp__browser-use__browser_click({ index: 6 })
```

### Step 3: Check Playwright MCP for Issues

```typescript
// Did any console errors occur?
mcp__playwright__browser_console_messages({ types: ["error", "warn"] })

// Did the API call succeed?
mcp__playwright__browser_network_requests({ resourceTypes: ["xhr", "fetch"] })

// Is auth token stored?
mcp__playwright__browser_evaluate({ script: "localStorage.getItem('authToken')" })
```

### Step 4: Verify State

```typescript
// Check if redirect happened
mcp__browser-use__browser_get_state({ include_screenshot: false })
// Should show URL changed to /dashboard
```

### Expected Output

**User Perspective (Browser-Use):**
- ✅ Form fields filled successfully
- ✅ Submit button clicked
- ✅ Redirected to /dashboard
- ✅ "Logout" link now visible

**Technical Perspective (Playwright MCP):**
- ✅ POST /api/auth/login → 200 OK
- ✅ Response contains auth token
- ✅ No console errors
- ✅ Cookie set with HttpOnly flag
- ✅ localStorage updated with token

---

## Pattern 2: Performance Testing

**Goal:** Measure page load performance under various network conditions.

### Step 1: Baseline Performance

```typescript
// Navigate and start tracing
mcp__playwright__browser_navigate({ type: "url", url: "https://example.com" })
mcp__playwright__browser_start_tracing()

// Wait for page load (manual or automated)
// ...

mcp__playwright__browser_stop_tracing({ filePath: "./baseline-trace.json" })
```

### Step 2: Analyze Metrics

```typescript
// Extract key metrics
mcp__playwright__browser_stop_tracing({ insight: "LCPBreakdown" })
// Returns: Largest Contentful Paint = 1.2s

mcp__playwright__browser_stop_tracing({ insight: "TotalBlockingTime" })
// Returns: TBT = 150ms

mcp__playwright__browser_stop_tracing({ insight: "RenderBlocking" })
// Returns: 3 render-blocking resources (app.css, vendor.js, main.js)
```

### Step 3: Test Under Slow Conditions

```typescript
// Simulate slow network
mcp__playwright__browser_emulate_network({ profile: "Slow 3G" })

// Simulate slow CPU (4x slowdown)
mcp__playwright__browser_emulate_cpu({ rate: 4 })

// Repeat performance trace
mcp__playwright__browser_navigate({ type: "reload", ignoreCache: true })
mcp__playwright__browser_start_tracing()
// ... wait for load ...
mcp__playwright__browser_stop_tracing({ filePath: "./slow-trace.json" })
```

### Step 4: Compare Results

```typescript
mcp__playwright__browser_stop_tracing({ insight: "LCPBreakdown" })
// Returns: LCP = 5.8s (degraded from 1.2s)

mcp__playwright__browser_stop_tracing({ insight: "TotalBlockingTime" })
// Returns: TBT = 2400ms (degraded from 150ms)
```

### Actionable Insights

- **LCP increased 4.8x** on slow network → Optimize images, use CDN
- **TBT increased 16x** on slow CPU → Reduce JavaScript bundle size
- **Render-blocking resources** → Defer non-critical CSS/JS

---

## Pattern 3: E2E User Flow Testing

**Goal:** Test complete user journey from signup → email verification → dashboard.

### Step 1: Signup Page

```typescript
// Navigate and fill signup form
mcp__browser-use__browser_navigate({ url: "https://app.com/signup" })
mcp__browser-use__browser_get_state({ include_screenshot: false })

// Fill form fields
mcp__browser-use__browser_input({ index: 4, text: "newuser@example.com" })
mcp__browser-use__browser_input({ index: 5, text: "SecurePass123!" })
mcp__browser-use__browser_input({ index: 6, text: "SecurePass123!" })
mcp__browser-use__browser_select({ index: 7, value: "individual" })
mcp__browser-use__browser_click({ index: 8 })  // Submit
```

### Step 2: Validate API Calls (Playwright MCP)

```typescript
// Check network requests
mcp__playwright__browser_network_requests({ resourceTypes: ["xhr", "fetch"] })

// Expected:
// POST /api/auth/signup → 201 Created
// Response: { "message": "Check email for verification link" }

// Check console
mcp__playwright__browser_console_messages({ types: ["error"] })
// Expected: No errors
```

### Step 3: Verify Redirect

```typescript
mcp__browser-use__browser_get_state({ include_screenshot: false })
// Expected: URL = /verify-email
// Expected: Message "Check your email for verification link"
```

### Step 4: Simulate Email Click (Manual Step)

For demo purposes, extract verification token from network response:

```typescript
mcp__playwright__browser_network_requests({ reqid: 5 })
// Extract token from response body
```

Navigate directly to verification link:

```typescript
mcp__browser-use__browser_navigate({
  url: "https://app.com/verify?token=abc123xyz"
})
```

### Step 5: Verify Completion

```typescript
// Check final state
mcp__browser-use__browser_get_state({ include_screenshot: false })
// Expected: URL = /dashboard
// Expected: Welcome message visible

// Check auth state
mcp__playwright__browser_evaluate({
  script: "localStorage.getItem('authToken')"
})
// Expected: Token present

mcp__playwright__browser_evaluate({
  script: "document.cookie"
})
// Expected: Session cookie set
```

### Verification Checklist

- ✅ Signup form submitted successfully
- ✅ API returned 201 Created
- ✅ No console errors during flow
- ✅ Redirected to /verify-email
- ✅ Verification link navigated to /dashboard
- ✅ Auth token stored in localStorage
- ✅ Session cookie set
- ✅ User now sees authenticated UI

---

## Pattern 4: Form Validation Testing

**Goal:** Test client-side and server-side validation with immediate feedback.

### Step 1: Submit Empty Form

```typescript
mcp__browser-use__browser_navigate({ url: "https://app.com/contact" })
mcp__browser-use__browser_get_state({ include_screenshot: false })

// Click submit without filling fields
mcp__browser-use__browser_click({ index: 9 })
```

### Step 2: Check Validation Messages

```typescript
// Get updated state to see validation errors
mcp__browser-use__browser_get_state({ include_screenshot: false })
// Expected: Error messages visible below each field

// Check console for validation logic
mcp__playwright__browser_console_messages()
// Expected: No JavaScript errors (validation should work)
```

### Step 3: Fill with Invalid Data

```typescript
mcp__browser-use__browser_input({ index: 4, text: "not-an-email" })
mcp__browser-use__browser_input({ index: 5, text: "Hi" })  // Too short
mcp__browser-use__browser_click({ index: 9 })

// Check state again
mcp__browser-use__browser_get_state({ include_screenshot: false })
// Expected: "Invalid email" and "Message too short" errors
```

### Step 4: Submit Valid Data

```typescript
mcp__browser-use__browser_input({ index: 4, text: "user@example.com" })
mcp__browser-use__browser_input({ index: 5, text: "Hello, I need help with billing." })
mcp__browser-use__browser_click({ index: 9 })

// Check network request
mcp__playwright__browser_network_requests({ resourceTypes: ["xhr", "fetch"] })
// Expected: POST /api/contact → 200 OK

// Check final state
mcp__browser-use__browser_get_state({ include_screenshot: false })
// Expected: Success message "Thank you! We'll respond within 24 hours."
```

---

## Pattern 5: Accessibility Testing

**Goal:** Verify page is accessible to screen readers and keyboard navigation.

### Step 1: Get Accessibility Tree

```typescript
mcp__playwright__browser_navigate({ type: "url", url: "https://app.com/login" })
mcp__playwright__browser_snapshot({ verbose: true })

// Examine output for:
// - Proper heading hierarchy (h1, h2, h3)
// - Form labels associated with inputs
// - Button text is descriptive
// - Image alt text present
```

### Step 2: Test Keyboard Navigation

```typescript
mcp__browser-use__browser_navigate({ url: "https://app.com/login" })

// Tab through form
mcp__browser-use__browser_keys({ keys: "Tab" })
mcp__browser-use__browser_keys({ keys: "Tab" })
mcp__browser-use__browser_keys({ keys: "Tab" })

// Check focus order via state
mcp__browser-use__browser_get_state({ include_screenshot: false })

// Submit with Enter
mcp__browser-use__browser_keys({ keys: "Enter" })
```

### Step 3: Verify ARIA Attributes

```typescript
mcp__playwright__browser_evaluate({
  script: `
    const input = document.querySelector('input[type="email"]');
    JSON.stringify({
      hasAriaLabel: !!input.getAttribute('aria-label'),
      hasLabel: !!input.labels?.length,
      ariaRequired: input.getAttribute('aria-required'),
      ariaInvalid: input.getAttribute('aria-invalid')
    })
  `
})

// Expected: All fields have proper labels and ARIA attributes
```

---

## Pattern 6: Multi-Device Testing

**Goal:** Test responsive design across mobile, tablet, and desktop.

### Step 1: Mobile Viewport

```typescript
mcp__playwright__browser_resize({ width: 375, height: 667 })
mcp__playwright__browser_navigate({ type: "url", url: "https://app.com" })
mcp__playwright__browser_screenshot({ fullPage: true, filePath: "./mobile.png" })

// Check mobile menu
mcp__playwright__browser_snapshot()
// Verify hamburger menu present, desktop nav hidden
```

### Step 2: Tablet Viewport

```typescript
mcp__playwright__browser_resize({ width: 768, height: 1024 })
mcp__playwright__browser_navigate({ type: "reload" })
mcp__playwright__browser_screenshot({ fullPage: true, filePath: "./tablet.png" })
```

### Step 3: Desktop Viewport

```typescript
mcp__playwright__browser_resize({ width: 1920, height: 1080 })
mcp__playwright__browser_navigate({ type: "reload" })
mcp__playwright__browser_screenshot({ fullPage: true, filePath: "./desktop.png" })
```

### Step 4: Compare Layouts

Review screenshots to verify:
- ✅ Mobile: Hamburger menu, single column layout
- ✅ Tablet: Collapsed sidebar, 2-column layout
- ✅ Desktop: Full navigation, 3-column layout

---

## Pattern 7: Error Monitoring During User Flow

**Goal:** Catch JavaScript errors, failed API calls, and console warnings during critical flows.

### Setup: Start Monitoring Before Flow

```typescript
// Clear console and network
mcp__playwright__browser_navigate({ type: "reload", ignoreCache: true })

// Start fresh recording
const initialConsole = mcp__playwright__browser_console_messages()
const initialNetwork = mcp__playwright__browser_network_requests()
```

### Execute User Flow

```typescript
// User performs actions via browser-use
mcp__browser-use__browser_navigate({ url: "https://app.com/checkout" })
mcp__browser-use__browser_get_state({ include_screenshot: false })

mcp__browser-use__browser_input({ index: 4, text: "4242424242424242" })  // Card number
mcp__browser-use__browser_input({ index: 5, text: "12/25" })  // Expiry
mcp__browser-use__browser_input({ index: 6, text: "123" })  // CVV
mcp__browser-use__browser_click({ index: 10 })  // Submit payment
```

### Check for Issues After Each Step

```typescript
// After form fill
const consoleAfterFill = mcp__playwright__browser_console_messages({ types: ["error", "warn"] })
// Expected: No new errors

// After submit
const consoleAfterSubmit = mcp__playwright__browser_console_messages({ types: ["error"] })
// Expected: No errors

// Check network requests
const networkRequests = mcp__playwright__browser_network_requests({
  resourceTypes: ["xhr", "fetch"]
})

// Find the payment API call
const paymentRequest = mcp__playwright__browser_network_requests({ reqid: 15 })
// Expected: POST /api/payments → 200 OK
// Check response body for success confirmation
```

### Report Issues

If errors found:

```typescript
// Get detailed error
const errorDetails = mcp__playwright__browser_console_messages({ msgid: 5 })

// Example error:
// "Uncaught TypeError: Cannot read property 'amount' of undefined at processPayment (checkout.js:45)"

// Take screenshot of error state
mcp__playwright__browser_screenshot({ filePath: "./payment-error.png" })
```

---

## Best Practices Summary

### 1. Start with Playwright MCP Monitoring
Open the page with playwright first to capture all network/console activity from the start.

### 2. Use Browser-Use for Interactions
Let browser-use handle all user actions (clicking, typing) — it's more reliable for complex flows.

### 3. Check DevTools After Critical Actions
After form submission, navigation, or API calls, immediately check:
- `list_console_messages` for errors
- `list_network_requests` for failed API calls
- `evaluate_script` for state verification

### 4. Never Use Screenshots in browser_get_state
Use `include_screenshot: false` to avoid 126K+ token overflow. Use `playwright.browser_screenshot` if you need visuals.

### 5. Close Sessions When Done
Always run `browser_close_all()` to free resources.

### 6. Combine Both Perspectives in Reports
Present both:
- **User Perspective**: What they see, what they do, what feedback they get
- **Technical Perspective**: Network calls, response codes, console errors, performance

### 7. Use Real Chrome for Logged-In Testing
When testing features requiring authentication, use `browser-use --browser real` to access existing sessions.

---

## Workflow Decision Tree

```
Need to test a feature?
  │
  ├─ Need to inspect network/console?
  │  → Start with playwright
  │
  ├─ Need to interact like a user?
  │  → Use browser-use
  │
  └─ Need both technical + user perspective?
     → Use BOTH:
        1. Open with playwright
        2. Interact with browser-use
        3. Validate with playwright
```

## Flutter Web Testing Patterns

### DDC Bootstrap (Critical)

Flutter web in development mode (DDC) does NOT auto-start. Must manually bootstrap:
```python
page.wait_for_load_state("networkidle", timeout=20000)
time.sleep(2)
if page.evaluate("typeof window.$dartRunMain === 'function'"):
    page.evaluate("window.$dartRunMain()")
    time.sleep(6)
```

### Pixel-Coordinate Interaction

Flutter web renders to WebGL canvas — no HTML form elements. All clicks must use pixel coordinates:
- `page.mouse.click(x, y)` then `page.keyboard.type(text)`
- Use `headless=False` for Playwright — Flutter DDC requires a visible display
- Get coordinates from screenshots by visual inspection

### Playwright Mouse API Notes

- `page.mouse.triple_click()` does NOT exist — use Ctrl+A then Backspace to clear inputs
- For clearing: `page.keyboard.press("Control+a")` then `page.keyboard.press("Backspace")`

### MCP Fallback to Playwright

If playwright and browser-use MCPs are not available as direct `mcp__*` calls:
- Install `playwright` Python library and use Playwright directly
- `pip3 install playwright && playwright install chromium`
