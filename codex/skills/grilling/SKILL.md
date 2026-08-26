---
name: grilling
description: >
  Grill the user relentlessly about a plan, decision, or idea until you both reach
  a shared understanding. You MUST use this before any creative work — building a
  feature, adding functionality, changing behaviour, designing a component — and
  before entering plan mode. Also use when the user wants to stress-test their
  thinking, or on any 'grill' trigger phrase. Spanish triggers: "vamos a hacer",
  "vamos a armar", "vamos a construir", "quiero hacer/armar/construir", "necesito
  que", "hay que agregar", "podemos hacer", "grilléame", "interrógame",
  "pregúntame lo que necesites", "cuestióname".
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round, then wait for the user's answers before the next round.

**Ask through the `AskUserQuestion` selector, never as plain text.** This is the point of the skill: the user picks instead of typing prose. Build every call per the selector rules in the global `CLAUDE.md` (one decision per tab, 3 options, recommendation first, the "Other" escape hatch, the caps), plus what is specific to a grilling round:

- One **frontier decision** per tab. The reasoning you would have written as prose lives in each option's `description`: what that choice buys and what it costs.
- A frontier routinely exceeds the cap of 4 tabs. When it does, issue back-to-back calls of at most 4 until the frontier is covered. They are still one round, so don't recompute the tree in between.
- Use `preview` when the options are concrete artifacts worth comparing side by side: layout mockups, competing snippets, config shapes. Skip it for plain preference questions. Previews don't work with `multiSelect`.
- A question with no enumerable answer space (a name, a URL, an open-ended constraint) goes in prose, but grouped with the round rather than replacing it: selector first, then the open one.

Each round the user answers reshapes the tree — settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it — don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report — ask the rest of the frontier now. The _decisions_ are the user's — put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
