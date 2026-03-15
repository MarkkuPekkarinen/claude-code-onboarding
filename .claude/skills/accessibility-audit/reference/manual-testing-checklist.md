# Manual Accessibility Testing Checklist

Manual checks that automated tools cannot catch. Run after automated scan confirms baseline. Works for both Angular and Flutter.

> **Existing platform checklists** (load these too):
> - Angular: `.claude/skills/angular-spa/reference/accessibility-checklist.md`
> - Flutter: `.claude/skills/flutter-mobile/reference/accessibility-audit-checklist.md`

---

## Keyboard Navigation

| Check | Angular | Flutter |
|-------|---------|---------|
| Tab reaches all interactive elements | ✓ | Tab key in integration test |
| Enter/Space activates buttons | ✓ | `LogicalKeyboardKey.enter` |
| Escape closes modals/drawers | ✓ | `LogicalKeyboardKey.escape` |
| Focus indicator always visible | No `outline: none` without replacement | Focus decoration visible |
| No keyboard traps | Tab does not get stuck | Focus does not get stuck |
| Logical tab order | DOM order or tabindex | `FocusTraversalGroup` order |
| Skip link at top of page | `href="#main-content"` first element | Not applicable (native nav) |

**Manual test steps:**
1. Open page, press Tab — first focusable element should receive focus
2. Continue tabbing — every interactive element must be reachable
3. At each element: Enter or Space should activate it
4. Open a modal — focus must move inside; Tab must stay inside; Esc must close
5. After modal closes — focus must return to the trigger element

---

## Screen Reader Testing

**Tools:** VoiceOver (macOS/iOS), NVDA or JAWS (Windows), TalkBack (Android)

| Check | Angular | Flutter |
|-------|---------|---------|
| Page title is descriptive | `<title>` tag | App bar title or route |
| Headings create logical outline | h1 → h2 → h3, no skips | Semantics with `header: true` |
| All images have alt text | `alt` attribute or `alt=""` for decorative | `Semantics(label:...)` or `ExcludeSemantics` |
| Form fields have labels | `<label for>` or `aria-label` | `InputDecoration(labelText:)` |
| Error messages announced | `role="alert"` or `aria-live="polite"` | `Semantics(liveRegion: true)` |
| Dynamic updates announced | `aria-live="polite"` region | `SemanticsService.announce()` |
| Buttons have meaningful names | `aria-label` on icon-only buttons | `Semantics(label:)` on `IconButton` |

**Manual test steps:**
1. Enable screen reader (VoiceOver: Cmd+F5, TalkBack: hold both volume keys)
2. Navigate by headings — does structure make sense?
3. Navigate to each form — are labels read before field?
4. Submit form with error — is error message announced immediately?
5. Trigger a status update — is the live region read?

---

## Visual Checks

| Check | Threshold | Tools |
|-------|-----------|-------|
| Text contrast | >= 4.5:1 normal, >= 3:1 large (18px+) | Browser DevTools, Colour Contrast Analyser |
| UI component contrast | >= 3:1 against adjacent colors | Same |
| Text resizes to 200% | No truncation, no overlap | Browser zoom |
| Content reflows at 320px | No horizontal scroll | Responsive mode |
| Focus indicators visible | Min 2px, high contrast | Visual inspection |
| Color not sole indicator | Error icons, patterns, text | Grayscale mode (DevTools) |
| Animations can be paused | Prefers-reduced-motion honored | OS reduced motion setting |

**Manual test steps:**
1. Browser zoom to 200% — check text does not clip or overlap
2. Resize to 320px width — check no horizontal scroll appears
3. Enable grayscale (DevTools → Rendering → Emulate CSS media) — check all info still conveyed
4. Enable OS reduced motion — check animations stop or reduce

---

## Cognitive Accessibility

Checks automated tools cannot catch. Applies to both Angular and Flutter.

| Check | What Good Looks Like |
|-------|---------------------|
| Instructions are clear | "Enter your email address" not "Input required" |
| Error messages are helpful | "Password must be 8+ characters" not "Invalid password" |
| No time limits on forms | Or user can extend/disable the timer |
| Navigation is consistent | Same nav items in same order on every page |
| Important actions are reversible | Undo or confirm dialog before destructive action |
| Predictable behavior | Links do not open unexpected new windows; clicks do expected things |
| No moving content distracts | Carousels, auto-play videos can be paused |
| Form fields have visible labels | Labels visible, not just placeholder (placeholder disappears on focus) |

**Manual test steps:**
1. Complete a key user journey (create order, login, checkout) — note any confusion points
2. Trigger every error message — is it clear what went wrong and how to fix it?
3. Find the most destructive action (delete, cancel order) — is there a confirmation step?
4. Navigate away and back — are inputs preserved or is data lost without warning?

---

## Mobile-Specific (Flutter)

| Check | How to Test |
|-------|-------------|
| TalkBack (Android) | Settings → Accessibility → TalkBack → On |
| VoiceOver (iOS) | Settings → Accessibility → VoiceOver → On |
| 200% font scale | Settings → Display → Font Size → Largest |
| High contrast mode | Settings → Accessibility → High Contrast → On |
| Sufficient touch target spacing | Visually check — targets should not be adjacent without padding |

---

## Output Template

```
Manual Audit — [Date] — [Component/Page]
Tester: [Name]
Tools: [VoiceOver / NVDA / TalkBack / DevTools]

Keyboard: PASS / FAIL
- [Finding, if any]

Screen Reader: PASS / FAIL
- [Finding, if any]

Visual: PASS / FAIL
- [Finding, if any]

Cognitive: PASS / FAIL
- [Finding, if any]

Mobile (Flutter only): PASS / FAIL
- [Finding, if any]

Overall: WCAG 2.1 AA PASS / FAIL
```
