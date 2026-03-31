# Stripe Payment Integration

> **When to use**: Adding Stripe payments — subscription billing, one-time charges, payment links, Stripe Connect vendor payouts, or webhook handlers
> **Time estimate**: 2–4 hours per integration
> **Prerequisites**: Stripe account, Restricted API Key (`rk_*`), `.env` with `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET`

## Overview

Full Stripe payment lifecycle from MCP setup through webhook-first implementation to security-reviewed PR. Backend-only Stripe calls (Python/FastAPI), Flutter Payment Sheet for client UI, webhook as source of truth.

## Phases

### Phase 1 — Load Skill & Verify MCP

**Trigger**: Any task involving Stripe payments
**Action**: Load `stripe` skill (`skills/stripe/SKILL.md`)
**MCP**: `stripe` MCP server (27 tools via `@stripe/mcp`)

**Verify MCP is working**:
```
Use `search_stripe_documentation` tool to query the specific API you need
Use `list_products` / `list_customers` to verify connection
```

**Iron Law**: NO STRIPE API CALL WITHOUT WEBHOOK VERIFICATION

**Gate**: MCP responds, skill loaded, API signatures verified

---

### Phase 2 — Webhook Handler First

**Trigger**: Before implementing any payment mutation
**Principle**: Implement the webhook handler BEFORE the API call that triggers it

**Steps**:
1. Create webhook endpoint in Python/FastAPI
2. Add signature verification using `stripe.Webhook.construct_event()`
3. Handle each event type with a dedicated handler function
4. Log all events with structured context
5. Return `{"status": "ok"}` — Stripe retries on non-2xx

**Key events**:

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Activate subscription |
| `invoice.paid` | Record payment |
| `invoice.payment_failed` | Trigger dunning |
| `customer.subscription.updated` | Sync plan changes |
| `customer.subscription.deleted` | Downgrade tier |

**Gate**: Webhook handler passes unit test with mocked Stripe events

---

### Phase 3 — Backend API Implementation

**Trigger**: Webhook handlers are in place
**Skill**: `python-dev` (for FastAPI patterns)

**Rules**:
- All Stripe API calls in Python/FastAPI services, never from Flutter
- Idempotency key on every mutating call
- Restricted API Key (`rk_*`), not root secret key
- All amounts in cents (integer), never floating-point dollars
- No PCI data stored in your database

**Steps**:
1. Create customer on signup (`stripe.Customer.create`)
2. Create checkout session or payment intent
3. Return `client_secret` to Flutter
4. Stripe processes payment
5. Webhook confirms → update database

**Gate**: API endpoints work end-to-end with Stripe test mode keys

---

### Phase 4 — Flutter Client Integration (if applicable)

**Trigger**: App needs payment UI
**Skill**: `flutter-mobile`

**Pattern**: Flutter → Your Backend → Stripe (never Flutter → Stripe directly)

**Steps**:
1. Call backend to create PaymentIntent/SetupIntent
2. Receive `client_secret` from backend
3. Present Stripe Payment Sheet with `client_secret`
4. Stripe handles PCI-compliant card collection
5. Backend webhook confirms payment

**Gate**: Payment Sheet renders, test payment completes in sandbox

---

### Phase 5 — Stripe Connect (vendor payouts, if applicable)

**Trigger**: Need to pay vendors/contractors
**Skill**: `stripe` (Connect section)

**Steps**:
1. Create Express account for vendor (`stripe.Account.create`)
2. Generate onboarding link (`stripe.AccountLink.create`)
3. Vendor completes onboarding in Stripe-hosted UI
4. Create transfer after job completion (`stripe.Transfer.create`)
5. Handle `account.updated` and `transfer.created` webhooks

**Gate**: Vendor onboarding flow works, test transfer completes

---

### Phase 6 — Testing

**Local webhook testing**:
```bash
stripe listen --forward-to localhost:8000/webhooks/stripe
```

**Unit tests**:
- Mock Stripe API calls with `monkeypatch`
- Test webhook signature verification (valid + invalid)
- Test each event handler independently
- Test idempotency (duplicate events handled gracefully)

**Gate**: All tests pass, webhook handler handles duplicate events

---

### Phase 7 — Security Review

**Dispatch**: `security-reviewer` agent
**Checklist** (from `skills/stripe/SKILL.md`):
- [ ] Webhook signature verification on ALL endpoints
- [ ] Idempotency keys on ALL mutating API calls
- [ ] No PCI data in database
- [ ] Restricted API Keys used
- [ ] Test mode keys in dev/staging only
- [ ] All amounts in cents
- [ ] MCP `--tools` flag restricts to needed tools

**Gate**: Security reviewer verdict = no CRITICAL or HIGH findings

---

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Trusting client-side payment confirmation | Always verify via webhook |
| Storing card numbers in database | Use Stripe Payment Sheet / Checkout |
| Using root `sk_*` key | Create Restricted API Key with minimum permissions |
| Floating-point dollar amounts | Always use integer cents |
| Missing idempotency key | Add `idempotency_key` param to every mutating call |
| Not handling webhook retries | Make handlers idempotent — check if event already processed |

## Related Workflows

- [revenuecat-subscription-integration.md](revenuecat-subscription-integration.md) — Mobile IAP entitlements (pairs with Stripe)
- [feature-python-fastapi.md](feature-python-fastapi.md) — Backend service patterns
- [feature-flutter-mobile.md](feature-flutter-mobile.md) — Flutter client patterns
- [security-audit.md](security-audit.md) — Full security review
