---
name: domain-modeling
description: >
  Build and sharpen a project's domain model — the CONTEXT.md glossary and the ADRs
  in docs/adr/. Use when the user wants to pin down domain terminology or a
  ubiquitous language, record an architectural decision, or when another skill needs
  to maintain the domain model. Spanish triggers: "glosario", "cómo llamamos a",
  "terminología", "nombres del dominio", "modelo de dominio", "documenta la decisión",
  "ADR", "deja constancia de por qué".
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* `CONTEXT.md` for vocabulary is not this skill — that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

## File structure

Most repos have a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `CONTEXT-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily — only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately: your glossary defines "cancellation" as X, but they seem to mean Y.

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term: they say "account", but do they mean the Customer or the User? Those are different things.

### Put term decisions through the selector

Both moves above end in a decision with named candidates, so they go through the `AskUserQuestion` selector per the global `CLAUDE.md` rules, with your proposed canonical term first and what each reading commits the model to in its `description`.

These fire often and land in the middle of other work, so **batch them**: hold the term questions until you have up to four and put them in one call, rather than interrupting once per word.

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up — capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` should be totally devoid of implementation details. Do not treat `CONTEXT.md` as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. When all three hold, offer it through the `AskUserQuestion` selector as a two-option tab (write it now / skip it), naming in the question which decision it would record. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).
