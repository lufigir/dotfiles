# HTML-block diagrams — felipego.com diagram kit

felipego.com renders a Notion **HTML block** (an `embed` backed by an uploaded
`.html` file) in a sandboxed iframe, and **injects the site's design-system
tokens + the current light/dark theme live into that frame**. An HTML block
styled with those tokens matches the portfolio and follows the theme toggle
automatically — no hardcoded colors, no separate dark-mode branch. This is now
the **default** way to illustrate a project's architecture and request flow
(replacing static diagram images), and the general mechanism for any
interactive widget a project write-up wants.

This reference is the whole workflow: the shared CSS kit, the icon sprite, the
standard diagram shapes (grouped-tier architecture is the default), how to
build/preview/ship a diagram, and when Mermaid is still the better choice.

## Why a shared kit, not bespoke CSS per project

"In felipego.com style" means every project's diagrams should look like **one
consistent system**, not each project inventing its own box-and-arrow styling.
`assets/diagram-style.css` is that one system: a small set of classes
(`.tier`/`.tier-lbl`/`.tier-link`, `.node`/`.ic`, the branch connectors
`.fork`/`.merge`/`.bus`, `.arrow`, `.step`, `.tool`, `.grid`, `.route`,
`.mono`, `.center`, `.row`, `button.kit`), each styled only with the site's
CSS variables. `assets/icons.svg` is the matching icon sprite — a fixed set of
line icons for common architecture concepts (browser, server, database…). You
author the **content** per project (labels, structure, which icon fits) but
never the **style** — `scripts/wrap-diagram.mjs` inlines both the shared CSS
and the icon sprite for you, so neither can drift between projects.

Two things the kit does that are easy to miss but matter a lot for how solid
the diagrams read:

- **The site's real fonts are embedded** (Outfit + JetBrains Mono, as
  data-URI `@font-face` at the top of `diagram-style.css`). The sandboxed
  iframe never receives the parent page's web fonts, so without this a diagram
  silently falls back to a system font and looks "off-brand". Keep those
  `@font-face` rules — that's what makes `var(--font-sans)`/`var(--font-mono)`
  actually resolve to the portfolio's type inside the frame.
- **Depth uses the site's signature hard offset shadow** (`0 3px 0`), drawn in
  the injected `--border`/`--primary` so it stays theme-aware. That crisp
  "stacked paper" look is what stops the monochrome palette from reading as
  washed-out. Don't add soft blurred shadows or hard-coded colors.

Read `assets/diagram-style.css` for the exact class list and the full CSS-variable
reference in its header comment before authoring a diagram body.

## The icon sprite

`assets/icons.svg` is a fixed set of line icons, auto-inlined into every
diagram by `scripts/wrap-diagram.mjs`. Use one as a node's first child:

```html
<div class="node"><span class="ic"><svg><use href="#i-server"/></svg></span><div><div class="t">API</div><div class="s">REST</div></div></div>
```

Available ids: `i-browser`, `i-user`, `i-users`, `i-mobile`, `i-server`,
`i-api`, `i-cpu` (agent/compute), `i-database`, `i-cache`, `i-cloud`
(external API/LLM), `i-queue`, `i-webhook`, `i-lock`, `i-file`, `i-terminal`,
`i-mail`, `i-chart`, `i-bot`, `i-bucket` (object storage), `i-search`,
`i-gear`, `i-globe`, `i-clock` (cron/scheduler), `i-key` (API key/auth).

Pick the **closest match** — this is a fixed list, the same way `tags` is a
fixed option list in Notion, so every project's diagrams draw from the same
visual vocabulary. If a node genuinely has no good match, it's fine to omit
the `.ic` span entirely (a plain text node is still valid). Don't invent a
one-off inline `<svg>` per diagram; if a repo's architecture needs a concept
that's missing, add it to `assets/icons.svg` once so it's available to every
future project, rather than duplicating a bespoke icon inline.

## The standard shapes

Pick whichever matches what you're depicting — don't force a shape that doesn't fit.

### 1. Grouped-tier architecture (default) — `.tier` / `.node` / `.ic`

The default shape for Architecture diagrams: a dashed group box per layer
(e.g. Client / Application / Data) labeled with `.tier-lbl`, each containing
one or more `.row` of icon `.node`s, joined tier-to-tier by a simple
`.tier-link`. This is what makes a diagram read as real system-design
architecture instead of a plain stack of boxes. Give the most important
shared layer (e.g. a shared analytics/service module, or the primary
datastore) the `.accent` class so it stands out.

```html
<div class="d">
  <div class="tier"><span class="tier-lbl">Client</span>
    <div class="node"><span class="ic"><svg><use href="#i-browser"/></svg></span><div><div class="t">Browser</div><div class="s">Web chat + inline chart renderer</div></div></div>
  </div>
  <div class="tier-link"></div>
  <div class="tier"><span class="tier-lbl">Application</span>
    <div class="row">
      <div class="node"><span class="ic"><svg><use href="#i-api"/></svg></span><div><div class="t">API</div><div class="s mono">/api/v1</div></div></div>
      <div class="node"><span class="ic"><svg><use href="#i-cpu"/></svg></span><div><div class="t">Agent</div><div class="s">authored tools + skills</div></div></div>
    </div>
  </div>
  <div class="tier-link"></div>
  <div class="tier"><span class="tier-lbl">Data</span>
    <div class="row">
      <div class="node accent"><span class="ic"><svg><use href="#i-database"/></svg></span><div><div class="t mono">Postgres</div><div class="s">shared datastore</div></div></div>
      <div class="node"><span class="ic"><svg><use href="#i-cloud"/></svg></span><div><div class="t">LLM</div><div class="s">external API</div></div></div>
    </div>
  </div>
</div>
```

If a tier-to-tier transition needs a protocol label, nest a label pill just
before the `.tier-link` (same convention as the branch connectors below):
`<div class="clbl-wrap"><span class="clbl mono">HTTP</span></div>`.

#### Fan-out between tiers (`.fork` / `.merge` / `.bus`)

**Show the connections, don't just point down.** A single centered `.arrow`
between a node and a `.row` of children hides *which* box feeds *which*. Use
the branch connectors instead whenever a layer fans out or converges — they
draw a real stem + horizontal bus + one leg (with arrowhead) per child, so the
wiring is legible:

- `.fork` — one parent fans out to N children. Put it **between** a single
  `.node` and the `.row` below it; set the child count inline:
  `<div class="fork" style="--n:3"><i></i><i></i><i></i></div>` (one `<i>` per
  child, and `--n` = that count).
- `.merge` — N children converge into one parent (mirror of `.fork`; same
  `--n` + `<i>` pattern), placed between a `.row` and the single `.node` below.
- `.bus` — N parallel 1:1 legs, between two `.row`s of the **same** width. No
  `--n` needed; just one `<i>` per column.
- Row→row where the widths differ (e.g. 2→4): stack a `.merge` (of the upper
  width) immediately followed by a `.fork` (of the lower width) — reads as
  "these gather, then redistribute to those".
- Keep a plain `.arrow` only for true 1→1 node-to-node hops; it now renders a
  gradient stem + filled arrowhead, with an optional label pill.

An optional label pill sits above any connector: `.arrow` uses an inner
`<span class="lbl mono">…</span>`; the branch connectors take a sibling
`<div class="clbl-wrap"><span class="clbl mono">…</span></div>` just before
them (the wrap script's authored bodies do this automatically).

```html
<div class="d">
  <div class="tier"><span class="tier-lbl">Client</span>
    <div class="node"><span class="ic"><svg><use href="#i-browser"/></svg></span><div><div class="t">Browser</div><div class="s">Web chat + inline chart renderer</div></div></div>
  </div>
  <!-- one tier fans out to two nodes in the next → .fork with --n:2 (label pill above it) -->
  <div class="clbl-wrap"><span class="clbl mono">/api/v1/*  ·  HTTP</span></div>
  <div class="fork" style="--n:2"><i></i><i></i></div>
  <div class="tier"><span class="tier-lbl">Application</span>
    <div class="row">
      <div class="node"><span class="ic"><svg><use href="#i-cpu"/></svg></span><div><div class="t">Agent</div><div class="s">authored tools + skills</div></div></div>
      <div class="node"><span class="ic"><svg><use href="#i-api"/></svg></span><div><div class="t mono">REST API</div><div class="s mono">/api/*</div></div></div>
    </div>
    <!-- two boxes converge into the shared layer → .merge with --n:2 -->
    <div class="merge" style="--n:2"><i></i><i></i></div>
    <div class="node accent"><span class="ic"><svg><use href="#i-file"/></svg></span><div><div class="t mono">lib/shared.ts</div><div class="s">one shared library — same functions for both front doors</div></div></div>
  </div>
  <!-- true 1→1 hop → keep a plain .arrow -->
  <div class="arrow"><span class="lbl mono">SQL</span><span class="line"></span><span class="chev">▼</span></div>
  <div class="tier"><span class="tier-lbl">Data</span>
    <div class="node"><span class="ic"><svg><use href="#i-database"/></svg></span><div><div class="t">Postgres</div><div class="s">…</div></div></div>
  </div>
</div>
```

### 2. Numbered flow (`.step` / `.num`)

A request/data-flow sequence as numbered rows — clearer than a Mermaid
sequence diagram once there are 5+ hops, and reads well on mobile.

```html
<div class="d">
  <div class="step">
    <div class="num">1</div>
    <div><div class="path">User <span class="to">→ Agent</span></div><div class="desc">natural-language question</div></div>
  </div>
  <div class="step">
    <div class="num">2</div>
    <div><div class="path">Agent <span class="to">→ Shared lib</span></div><div class="desc">calls a typed tool (Zod-validated)</div></div>
  </div>
  <!-- one .step per hop -->
</div>
```

### 3. Card grid (`.tool` / `.grid` / `.route`)

A "features/tools at a glance" grid — one card per tool/endpoint/feature, each
with a name, one-line description, and an optional route/tag badge.

```html
<div class="d"><div class="grid">
  <div class="tool"><span class="ic"><svg><use href="#i-chart"/></svg></span><div class="n">get_summary</div><div class="dsc">plain-totals summary</div><span class="route">/api/summary</span></div>
  <div class="tool"><span class="ic"><svg><use href="#i-chart"/></svg></span><div class="n">get_trend</div><div class="dsc">revenue/expense trend by month or department</div><span class="route">/api/trend</span></div>
  <!-- one .tool per item; the .ic icon is optional, same sprite as .node -->
</div></div>
```

### Beyond static diagrams: small interactive widgets

`button.kit` / `button.kit.ghost` are available for a project whose write-up
benefits from something the reader can click (a live counter, a toggle between
two datasets, a "change color" demo, etc.) — same rule applies: no hardcoded
colors, and keep it self-contained (inline all JS/CSS, no external requests —
the sandbox blocks them). Only add an interactive widget when it genuinely
demonstrates something about the project; a static diagram is usually enough.

## Workflow: author → wrap → preview → ship

1. **Author the body fragment** for one diagram (just the inner HTML — a
   `<div class="d">…</div>`), based on the real architecture you read from the
   wiki/repo. If a diagram would be guesswork, don't invent one — say so and
   skip it, same as the image-placeholder rule.

2. **Wrap it** into a complete, self-contained document with the shared kit:

   ```
   node scripts/wrap-diagram.mjs body.html --out diagram.html
   ```

3. **Preview in both themes before publishing** (this is public, live
   portfolio content — verify it, don't ship blind):
   - Write a small preview HTML that sets the same CSS variables felipego.com
     uses (`app/globals.css` in the site repo has the current `:root`/`.dark`
     values) on `:root`/`.dark`, includes a "toggle theme" button that flips a
     `.dark` class on `<html>`, and iframes/inlines your diagram body styled
     with the same kit CSS.
   - Serve it over `http://localhost` — a one-liner Node static server on a
     scratch port is enough; prefer this over `file://`, where module loading
     and fetch behave differently — and open it with the Chrome DevTools MCP
     (`new_page` + `navigate_page`). `take_screenshot` in light, `click` the
     "toggle theme" button, `take_screenshot` in dark.
   - Confirm: text is legible in both themes, nothing relies on a hardcoded
     color, and the layout doesn't overflow at ~760px wide (the typical
     content column width).

4. **Ship it** with `scripts/notion-html.mjs`, run **from the felipego.com
   site repo checkout** (it needs `@notionhq/client`, already a dependency
   there, and `NOTION_API_KEY` from that repo's `.env.local`):

   - New page, adding a diagram for the first time:
     ```
     node scripts/notion-html.mjs add <pageId> diagram.html
     # or, to place it right after a specific existing block:
     node scripts/notion-html.mjs list <pageId>              # find the anchor block's id
     node scripts/notion-html.mjs add <pageId> diagram.html --after <blockId>
     ```
   - Updating an existing diagram in place (same position):
     ```
     node scripts/notion-html.mjs replace <blockId> diagram.html
     ```
   - Do this **once per language** (English page and Español page each get
     their own HTML block, content translated same as the rest of the body —
     labels inside the diagram should be in the row's language).

5. **Verify on the live page** (or `pnpm dev` locally against the same
   content): re-fetch the Notion page, confirm the block is where you expect,
   and — if a local dev server is available — open the project page with the
   Chrome DevTools MCP and confirm the diagram renders, sizes itself, and
   matches the current theme.

## Placement: right after the section's heading (or an existing image)

On a **fresh page** (Phase 4 just created it), the body has the section
heading (e.g. "Layered Architecture") but no diagram yet — that's intentional,
since `notion-create-pages`/`notion-update-page` write Markdown and can't
create an HTML block. Find that heading's block id and anchor there:

```
node scripts/notion-html.mjs list <pageId>              # find the heading block's id
node scripts/notion-html.mjs add <pageId> diagram.html --after <headingBlockId>
```

If the page already has a placeholder image or screenshot for this section
instead (an **update** to an older row), add the HTML diagram **after** it
rather than replacing it, unless the user asked you to replace — this lets a
static screenshot and the interactive diagram coexist until the user decides to
prune one.

## When Mermaid is still fine

Mermaid (fenced ` ```mermaid ` blocks) still works and renders natively inside
the Notion app itself (an HTML block only renders as a live sandboxed iframe on
the *website*; inside Notion's own editor it just shows as an embedded file).
Prefer Mermaid when:
- the diagram is simple enough that Notion's native rendering during editing
  matters more than matching the site's exact visual system, or
- you want something quick and the user hasn't asked specifically for the
  polished/interactive treatment.

Otherwise, default to the HTML kit for Architecture and Request Flow — it's
proven in production (Financial Analytics Agent project) and is what "in
felipego.com style" now means for this skill.

## Script reference

- `scripts/wrap-diagram.mjs <bodyFile> [--out <outFile>]` — inlines
  `assets/diagram-style.css` around a body fragment. No Notion dependency; runs
  from anywhere.
- `scripts/notion-html.mjs list <pageId>` — list a page's direct children
  (index, type, id, short preview) to find an anchor block id.
- `scripts/notion-html.mjs add <pageId> <htmlFile> [--after <blockId>]` —
  upload and append a new HTML block.
- `scripts/notion-html.mjs replace <blockId> <htmlFile>` — swap an existing
  HTML block's content in place (same position).
- `scripts/notion-html.mjs delete <blockId>` — remove an HTML block.

All `notion-html.mjs` commands need `@notionhq/client` + `NOTION_API_KEY` —
run them from the felipego.com site repo checkout, which has both (the script
auto-loads `.env.local` from the current directory if `NOTION_API_KEY` isn't
already set).
