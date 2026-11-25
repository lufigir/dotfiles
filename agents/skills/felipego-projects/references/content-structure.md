# Content structure — how every felipego.com project page is organized

This is the house structure for a portfolio project write-up: what sections to
include, in what order, and **what information each one should actually show**.
The goal is that every project reads as the same system — a visitor can scan any
project and find "what is it / why / how it's built / what's clever / how it's
laid out / what it proves" in the same places — while still fitting the project's
real shape.

The rule of thumb: **the spine is fixed, the middle flexes by project type.**
Keep the outer frame identical everywhere; swap the architecture/features
sections for the variant that matches what the project actually is. Never invent
structure a project doesn't have — an ML notebook has no "Request Flow", a
landing page has no "microservices". Fit the truth into the nearest spine slot.

## The universal spine (every project, in this order)

1. **Intro paragraph** — 1–3 sentences, no heading. What it is, who it's for,
   and the concrete problem it removes. This is the hook; lead with the value,
   not the tech.

2. **## Architecture and Tech Stack** *(see type variants below)*
   - **### Core Architecture** — a bulleted stack breakdown: framework, language,
     frontend, backend, database, validation, key libraries. One line each.
   - **### Layered Architecture** — HTML-block diagram of the real layers
     (see `references/html-diagrams.md`). Only when there's a genuine
     architecture to draw.
   - **### Request Flow** — HTML-block diagram of one representative
     request/data path. Only when there's a real flow.

3. **## Key Features** *(see type variants)*
   - **### Features at a Glance** — a card-grid HTML block, one card per
     feature/endpoint/tool with a one-line description and an optional route/tag.
   - Then 3–6 **### <feature>** paragraphs — each concrete and specific
     (what it does + why it's non-trivial), not marketing fluff.

4. **## Technical Highlights** — the engineering decisions worth bragging about:
   a hard trade-off resolved, a clever constraint, a non-obvious design choice,
   a measurable win. This is what separates a portfolio from a README.

5. **## Project Structure** — an annotated file tree in a ```plain text``` block,
   comments explaining what each important directory/file is for.

6. **## Impact and Scalability** — bullets: what the project proves, how it
   extends, and any real results/metrics (users, performance, accuracy, etc.).

7. **--- ## Notes** — a short recap of the stack, then the links: GitHub, live
   demo, and the documentation wiki. Image placeholders live here or inline near
   the feature they illustrate (see the placeholder convention in `notion.md`).

Don't add a quick-facts/"At a Glance" block — the site's project cards already
show type, stack (with real tech logos), links, and status at a glance; a
duplicate summary in the body just repeats the intro paragraph.

## Type variants — swap sections 2–5 to match the project

Pick the variant that matches what the project *is*. The spine (1, 4, 5, 6, 7)
stays the same in all of them.

### A. Full-stack app  (AgendaUN, Tourify, Shop Microservers, Eventify, KiraWebs)
The default. Architecture: Core Architecture + Layered Architecture diagram +
Request Flow diagram. Key Features: Features-at-a-glance grid + feature
paragraphs. For a genuinely small site (a landing page), it's fine to drop the
Request Flow diagram and keep just a light architecture diagram or none.

### B. AI agent  (Financial Analytics Agent)
Like full-stack, but the "Features at a Glance" grid is a **tools/skills** grid
(one card per agent tool with its route), and Request Flow traces a
prompt → tool → data → answer turn. Call out eval/testing and model choice in
Technical Highlights.

### C. ML / data project  (Loan Status Prediction, and ML parts of Khipu)
Replace "Request Flow" with **### ML Pipeline** — a numbered-flow diagram of
`data → preprocessing → training → evaluation → deployment`. Replace the
features grid with:
- **### Dataset** — source, size, key features/columns.
- **### Models & Results** — models compared and the winner, in a small table
  (accuracy / F1 / AUC / inference time), plus feature importance. Metrics are
  the "features" of an ML project — show them concretely.
Keep intro, Technical Highlights, Impact, Notes.

### D. Bot / small tool  (Ticket Bot)
Lightweight: intro, Core Architecture (short), a Features-at-a-glance grid,
maybe one small flow diagram if there's a real interaction loop, Notes. Don't
force a heavy layered-architecture diagram onto something small.

## What "good information" looks like (quick checklist)

- Lead with the **problem and the user**, not the framework.
- Every feature paragraph says something a README wouldn't — a decision, a
  constraint, a number.
- Prefer **specifics over adjectives**: "3-per-minute Redis rate limit" beats
  "robust rate limiting"; "82.7% accuracy, 32 ms inference" beats "high
  performance".
- Diagrams depict the **real** architecture (cross-checked against the repo),
  never decorative boxes.
- Every image is an explicit placeholder (see `notion.md`), never a fabricated
  URL.
- Both languages carry the same structure; translate meaning, keep technical
  tokens (`Zod`, tool names, file paths) as-is.

When creating or refreshing a project, fill this structure from the Mintlify
wiki + the repo (Phases 2–3 of `SKILL.md`), choose the variant, and only then
author the diagrams (Phase 5). If a section has no truthful content for a given
project, omit the section — an honest shorter page beats a padded one.
