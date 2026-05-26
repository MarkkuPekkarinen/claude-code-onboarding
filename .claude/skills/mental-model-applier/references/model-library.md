# Mental Model Library

Reference catalog for model selection. Load when choosing models for a specific problem.

## Decision Making

| Model | Core Claim | Best For |
|-------|-----------|----------|
| **Expected Value** | Multiply probability × outcome for each option; choose the highest | Decisions with quantifiable outcomes under uncertainty |
| **Regret Minimization** | Choose the option you will regret least at age 80 | Long-horizon, irreversible decisions where logic and emotion conflict |
| **Reversibility Test** | Prefer reversible decisions; apply more scrutiny to irreversible ones | Any decision where the cost of being wrong is asymmetric |
| **Opportunity Cost** | Every choice forecloses alternatives; the real cost includes what you give up | Resource allocation, time investment, build vs. buy decisions |
| **Pre-Mortem** | Imagine it failed. What caused it? Work backward. | Before committing to a plan — surfaces risks before they occur |

## Systems & Feedback

| Model | Core Claim | Best For |
|-------|-----------|----------|
| **Second-Order Thinking** | Ask "and then what?" twice. Consequences of consequences matter more. | Policies, product changes, decisions with broad reach |
| **Feedback Loops** | Outputs become inputs; systems either self-reinforce or self-correct | Diagnosing why a problem persists or escalates despite fixes |
| **Unintended Consequences** | Complex systems route around interventions in unexpected ways | Regulations, incentive structures, architectural constraints |
| **Leverage Points** | Small interventions at the right place produce disproportionate effects | Prioritizing where to intervene in a stuck system |

## People & Incentives

| Model | Core Claim | Best For |
|-------|-----------|----------|
| **Principal-Agent Problem** | Agents act in their own interest when it diverges from the principal's | Contractor relationships, team alignment, delegation design |
| **Goodhart's Law** | When a measure becomes a target, it ceases to be a good measure | Metrics, KPIs, performance review design |
| **Prisoner's Dilemma** | Rational individual action produces collectively irrational outcomes | Competitive dynamics, cooperation problems, standards adoption |
| **Hanlon's Razor** | Never attribute to malice what can be explained by incompetence | Diagnosing organizational failure, customer complaints |
| **Status Games** | Much human behavior is driven by relative standing, not absolute gain | Team dynamics, pricing strategy, adoption resistance |

## Strategy & Competition

| Model | Core Claim | Best For |
|-------|-----------|----------|
| **Competitive Moats** | Sustainable advantage comes from switching costs, scale, or network effects | Evaluating product defensibility, build vs. buy, pricing |
| **OODA Loop** | Observe → Orient → Decide → Act; faster loops win | Competitive response, crisis management, iterative product development |
| **Blue Ocean Strategy** | Compete in uncontested space rather than fighting over existing demand | Market positioning, finding underserved segments |
| **Game Theory** | Anticipate opponent moves and their responses to your moves | Pricing wars, negotiation, standards battles |

## Diagnosis & Root Cause

| Model | Core Claim | Best For |
|-------|-----------|----------|
| **Five Whys** | Ask "why?" five times to reach root cause rather than symptom | Bug diagnosis, recurring failure, organizational dysfunction |
| **Inversion** | Define what failure looks like, then eliminate its causes | Reframing problems, finding non-obvious solutions |
| **First Principles** | Break problem into foundational truths; rebuild from there | Overcoming conventional wisdom, designing from scratch |
| **Map vs. Territory** | The model is not reality; acting on the model as if it were reality causes errors | Over-reliance on metrics, simulations, or frameworks |

## Complexity & Design

| Model | Core Claim | Best For |
|-------|-----------|----------|
| **Occam's Razor** | Among competing explanations, prefer the simplest that fits the evidence | Architecture decisions, debugging, hypothesis selection |
| **Forcing Function** | Design constraints that make the right behavior the default behavior | Preventing future mistakes, onboarding design, safety systems |
| **Minimum Viable Feedback** | Find the smallest test that confirms or refutes the core assumption | Product validation, architectural spikes, research design |
| **Abstraction Layers** | Separate concerns so each layer only talks to the layer directly adjacent | System design, API contracts, delegation of responsibility |

## Bias & Judgment

| Model | Core Claim | Best For |
|-------|-----------|----------|
| **Availability Heuristic** | We overweight recent, vivid, or memorable events in probability estimates | Post-incident policy changes, risk assessment after failures |
| **Sunk Cost Fallacy** | Past investment is irrelevant to future decisions; only future costs and benefits matter | Deciding whether to continue a failing project or approach |
| **Overfitting** | A model that perfectly explains past data may generalize poorly to new data | Strategy built entirely from past experience, data-driven decisions |
| **Confirmation Bias** | We preferentially seek and weight evidence that confirms existing beliefs | Research design, evaluating a new technology or hire |
| **Scope Insensitivity** | Human intuition does not scale linearly with magnitude | Evaluating large-scale impact, prioritization across vastly different sizes |

## Application Notes

- Never apply the same three models to every problem — the table above is a selection tool, not a ranked list.
- Cross-domain application (e.g. a psychology model + a systems model + a strategy model) produces more insight than three models from the same domain.
- If two candidate models would produce the same insight, replace one with a model from a different domain.
- The dominant insight must require all three models to produce — if one model alone produces it, the other two were not the right selection.
