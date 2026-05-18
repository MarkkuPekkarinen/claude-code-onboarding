---
name: ai-playbook
description: Production-grade decision framework for building AI features, AI workflows, AI agents, and AI-augmented systems. Use this skill whenever the user is designing, building, debugging, reviewing, or deciding whether to add AI to a system — including any work involving LLM calls, embeddings, RAG, agents, tool use, prompt engineering, evals, AI security/prompt injection, model routing, fine-tuning decisions, or AI-related architectural choices. Trigger on phrases like "build an agent", "add AI to", "use an LLM for", "RAG", "should I use AI", "AI feature", "agentic", "structured output", "tool calling", "eval set", "prompt injection", "vector store". Do NOT trigger for: pure non-AI coding tasks, questions about Claude Code tooling, or conceptual AI questions without an applied design context.
allowed-tools: Read
last-reviewed: 2026-05-17
---

# AI Application Playbook

> **Iron Law:** Start one tier below where you think you need to be. Most "agent" problems are workflows; most "workflow" problems are a single model call. Use the smallest pattern that works.

This skill encodes a production-grade framework for deciding when to use AI and how to ship it safely. The full playbook is in `playbook.md` (10k+ words across four layers); load it only when needed using the routing below.

## Prime Directive

> **Use AI for translation between the messy world and your clean system — never as the clean system itself.**

> **Everything the model reads is untrusted input. Everything the model writes is an untrusted proposal until validated.**

## Fast triage (use this first)

Before any AI design work, ask in order:

1. **Is the input messy / unstructured / ambiguous?** If no → deterministic code, stop.
2. **Can a downstream verifier (human or code) catch errors?** If no → don't use AI for the decision.
3. **Is this on the critical latency path with no fallback?** If yes → don't use AI here.
4. **Pick the smallest pattern that works**: single model call in a workflow → ReAct loop in a state machine → planning agent → autonomous agent. Start at #1.

If the answer to all three is "AI is appropriate," route to the relevant layer below.

## When to load the full playbook

Read `playbook.md` and apply the matching layer based on what the user is doing:

| User is doing... | Load these layers from playbook.md |
|------------------|-------------------------------------|
| Deciding whether to add AI to a feature | Layer 1 (Principles) |
| Architecting an AI feature | Layer 1 + Layer 2 (Operating Controls) |
| Writing code: schema validation, output contract, retries, fallback | Layer 2 §2.4, §2.5; Layer 3 §3.1, §3.5 |
| Writing prompts or designing prompts for security | Layer 2 §2.5; Layer 3 §3.2 (adversarial test catalog) |
| Building or reviewing an agent | Layer 2 §2.5, §2.6; Layer 3 §3.2 |
| Designing or evaluating RAG | Layer 2 §2.7; Layer 3 §3.2 retrieval-poisoning row |
| Picking a model / deciding to fine-tune | Layer 2 §2.9 |
| Sizing cost and latency | Layer 2 §2.10, §2.11; Layer 3 §3.4 |
| Designing eval set / regression tests | Layer 2 §2.14; Layer 3 §3.2 |
| Preparing for launch | Layer 4 §4.1 (unified launch checklist) |
| Setting up rollout or canary | Layer 4 §4.2 |
| Handling an incident | Layer 4 §4.3 |
| Testing kill switch | Layer 4 §4.4 |
| Onboarding to AI workflow (first 30 days) | Layer 4 §4.5 |
| Avoiding overbuilding | Layer 4 §4.6 |

For the unified Decision Record template, run the `/ai-decision-record` skill.
For the launch checklist, run `/ai-launch-check`.
For incident response, run `/ai-incident-response`.

## Default stance

When advising on AI design work:

- **Default to the Implementation Minimum** (six items in Layer 2 §2.3). Don't over-engineer on day one.
- **Push back when AI is the wrong tool.** The Red Flag Matrix (Layer 1 §1.6) lists where deterministic code wins.
- **Insist on the Output Contract** (Layer 2 §2.4) before any AI output mutates state.
- **Treat all model inputs as untrusted** — including retrieved documents, tool outputs, file uploads, and prior conversation turns from external sources.
- **Quote thumb rules sparingly.** Don't recite the playbook at the user; apply it.

## When NOT to load the full playbook

- Pure non-AI coding tasks (writing a SQL query, fixing a CSS bug, refactoring deterministic logic).
- Conversations about Claude Code or AI tooling itself, unless the user is *building* an AI feature using those tools.
- Questions about AI as a topic ("what is RAG?") without an applied design context.

When in doubt: skim the Fast Triage section, decide if AI is even the right answer, and only load `playbook.md` if it is.

## Fast triage example

```
User: "Should I use an LLM to classify support tickets into 5 buckets?"

Fast triage:
1. Is input messy/unstructured? YES — free-text tickets.
2. Can a downstream verifier catch errors? YES — human review queue + SLA.
3. On critical latency path with no fallback? NO — async classification.

→ AI is appropriate. Pattern: workflow (single model call + output contract).
   NOT an agent. Routing: Layer 2 §2.9 (model selection) + §2.14 (eval set: 100–300, precision/recall per class).

User: "I want to auto-approve expense reports under $100 using an LLM."

Fast triage:
1. Is input messy/unstructured? PARTIAL — structured form but free-text justification.
2. Can a downstream verifier catch errors? NO — auto-approval with no human check = direct financial action.

→ AI is NOT appropriate for auto-approval. Red Flag Matrix hit: Tier-4 action with no verifier.
   Recommend: AI as a draft/suggest assistant only, human approves.
```

## Verify (before routing to a lifecycle skill)

```
✅ Fast triage completed — AI is appropriate for this use case
✅ Correct playbook layer(s) identified from the routing table
✅ If user is starting a new feature → directed to /ai-decision-record
✅ If user is preparing to launch → directed to /ai-launch-check
✅ If there is a production incident → directed to /ai-incident-response
✅ Only loaded playbook.md sections relevant to the current task (not the full 10k words)
```

## If this skill cannot proceed

```
Situation: fast triage returns all NO (deterministic code is sufficient)
→ Do not load playbook.md. Output: "Based on the fast triage, this looks like a
  deterministic code problem. AI would add cost and complexity without benefit."

Situation: user insists on AI after triage says no
→ Apply the Red Flag Matrix (Layer 1 §1.6). Name the specific flags.
→ Output: "The Red Flag Matrix flags this as [reason]. I recommend against AI here.
  If you want to proceed anyway, run /ai-decision-record to document the justification."
```

## References

- Full playbook (4 layers): `.claude/skills/ai-playbook/playbook.md`
- Layer 1 §1.6 Red Flag Matrix: when NOT to use AI
- Layer 2 §2.3 Implementation Minimum: 6 required items before shipping any AI feature
- Layer 2 §2.4 Output Contract: schema → types → business rules → permissions → confidence → audit → route
- Layer 3 §3.2 Adversarial test catalog: prompt injection, tool misuse, retrieval poisoning
- Lifecycle skills: `/ai-decision-record` → `/ai-launch-check` → `/ai-incident-response` → `/ai-audit`
- OWASP LLM Top 10: https://owasp.org/www-project-top-10-for-large-language-model-applications/
