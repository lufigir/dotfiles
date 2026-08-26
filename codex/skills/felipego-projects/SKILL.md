---
name: felipego-projects
description: >
  Use when creating or updating a project entry for felipego.com — the bilingual
  Notion "Projects" (English) / "Proyectos" (Español) portfolio databases that
  power the site as a headless CMS. Driven by a single input: a GitHub repo URL.
  The workflow: generate a Mintlify wiki from the repo, read that wiki as the
  source of truth, write rich English + Spanish project pages in Notion via
  Executor, and illustrate them with interactive HTML-block diagrams styled
  with felipego.com's own design system (falling back to native Mermaid when
  that's not warranted), plus explicit, easy-to-find image placeholders left
  for the user to fill in later. Trigger whenever the user mentions adding,
  publishing, or updating a felipego.com project, a portfolio project item, the
  Notion Projects/Proyectos databases, generating project documentation, or
  making a Mintlify wiki for a repo — even if they don't spell out every step.
  Uses Notion (via the Executor MCP hub) and the Chrome DevTools MCP.
---

# felipego.com project publisher

Publish or refresh a portfolio project in the bilingual Notion databases behind
[felipego.com](https://felipego.com). One project = two Notion rows (English +
Español) that share the same `slug`. The site renders each row's **properties**
(title, description, tags, links, images) and its **page body** (the long
technical write-up, illustrated with diagrams).

**The only thing you strictly need from the user is a GitHub repo URL.**
Everything else — slug, title, whether it's a create or an update — is derived;
only ask when something genuinely can't be inferred (see Phase 1).

The pipeline has five phases. Do them in order; each feeds the next.

```
1. Gather inputs  →  2. Generate Mintlify wiki (Chrome)  →  3. Read the wiki  →  4. Write to Notion (EN + ES)  →  5. Diagrams & interactive HTML blocks
```

The guiding idea: the Mintlify wiki, auto-generated from the repo, is a rich and
*current* description of the project. Rather than invent the write-up, generate
that wiki, read it, and translate it into the house style of the Notion project
pages — illustrated with diagrams built from that same real architecture, not
decorative filler.

## Before you start — safety and setup

- **You never enter credentials.** For a public repo, generating a Mintlify wiki
  needs no sign-in — you may type the notify-me email
  (`luisgir827@gmail.com`) and trigger generation yourself (see
  `references/mintlify.md`). But connecting/authorizing a repo through GitHub's
  OAuth screen is a real access grant: drive the browser *to* that screen, then
  pause and ask the user to click Authorize/Install themselves. Never type a
  password or OTP/magic-link code, and never click "Authorize"/"Allow" on an
  OAuth screen on their behalf.
- **Confirm the Notion write.** Creating or overwriting a portfolio page is
  outward-facing. Show the user the content you're about to write and get a clear
  yes before calling the Notion write tools.
- **Load the tools you need up front.** Notion runs through **Executor**
  (`mcp__executor__execute`), not a direct MCP server. This skill's databases
  live in the **`felipegiraldo`** workspace, so every Notion tool named below in
  short form (`notion-fetch`, `notion-search`, `notion-query-data-sources`,
  `notion-create-pages`, `notion-update-page`) maps to
  `tools.notion_mcp.user.felipegiraldo.<name_with_underscores>` inside an
  `execute` call — e.g. `notion-search` → `tools.notion_mcp.user.felipegiraldo.notion_search`.
  Also load the Chrome DevTools MCP (`mcp__chrome-devtools__new_page`,
  `navigate_page`, `take_snapshot`, `take_screenshot`, `click`, `fill`) and
  `WebFetch`. In Claude Code these may be deferred — load them with one
  `ToolSearch` call.
- **Phase 5 needs a working directory.** `scripts/notion-html.mjs` requires
  `@notionhq/client` + `NOTION_API_KEY`, which only exist in the felipego.com
  site repo checkout — run that script (and any local preview server) with the
  site repo as the current directory, regardless of where this skill itself is
  invoked from.

Read `references/notion.md` for the exact database IDs, schema, property formats,
and the page-body template. Read `references/html-diagrams.md` for the diagram
kit, shapes, and scripts. Read `references/mintlify.md` for the browser steps.
Pull them in as you reach each phase rather than all at once.

## Phase 1 — Gather inputs

**Required input: the GitHub repo URL** (or `owner/name`). Derive everything
else instead of asking for it upfront:

- **slug** — the repo name, kebab-cased (matches existing rows' convention).
- **GitHub URL** — the repo URL itself.
- **Title** — humanize the repo name, but check the README's H1 / package.json
  `name` for a clearer product name (e.g. "Financial Analytics Agent" rather
  than "financial-analytics-agent") and prefer that.
- **previewLink** (live demo URL) — check the README for a live-demo badge/link,
  and `package.json` `homepage`. If genuinely not discoverable, ask the user
  once rather than guessing or leaving it silently wrong.
- **Create or update?** Don't ask — query Notion by the derived slug (Phase 4)
  to find out for certain. If the user's repo-name guess for the slug turns out
  wrong (no match, but a very similarly-named row exists), surface that instead
  of silently creating a duplicate.

Only fall back to asking the user directly for something in this list if it
truly isn't derivable from the repo. If the user already gave you a title, slug,
or live URL up front, use what they said instead of deriving it.

## Phase 2 — Generate the Mintlify wiki

Follow `references/mintlify.md`. In short: open `https://mintlify.wiki/explore`
in Chrome, have the user sign in and authorize the GitHub repo, trigger
generation, and wait for it to finish. The result lives at
`https://mintlify.wiki/<owner>/<repo>`.

If a wiki for this repo already exists, you can skip straight to reading it —
but offer to regenerate first if the repo has changed materially since, so the
Notion content reflects the current code.

## Phase 3 — Read the wiki

Read the generated wiki as the source of truth for the write-up. Prefer
`WebFetch` on the wiki URL(s); if pages are gated or JS-rendered, read them in
Chrome (`take_snapshot`, or `evaluate_script` returning `document.body.innerText`)
on the open page. Capture: what the project is, architecture,
tech stack, key features, notable technical decisions, and project structure —
the raw material for the Notion body.

Cross-check anything load-bearing against the actual repo (model IDs, tool
counts, file paths) before writing it as fact — generated docs can lag or
overstate. When in doubt, read the file.

## Phase 4 — Write to Notion (English + Español)

Everything specific to this step — database IDs, the SQLite schema, property
value formats (`show` = `__YES__`, `tags` as a JSON array from a fixed option
list, etc.), the create-vs-update decision, and the bilingual page-body
template — is in `references/notion.md`. Follow it exactly; the site depends on
these shapes. Leave the diagram slots in the body template as placeholders for
now — Phase 5 fills them in.

**What to put in each section — the house content structure — is in
`references/content-structure.md`.** Read it before writing the body: it defines
the fixed spine (intro → Architecture → Key Features → Technical Highlights →
Project Structure → Impact → Notes) and the type variants (full-stack app / AI
agent / ML-data project / small bot-tool) so the page fits what the project
actually is. Every project — new or refreshed — should end up on this
structure; it's what makes the portfolio read as one consistent system.
No "At a Glance" quick-facts block — the site's project card and page header
already show stack (with real tech logos, see `lib/tech-icons.ts` in the site
repo), links, and status, so a body-level summary would just repeat the intro
paragraph.

The essentials:

1. **Fetch the data source schema first** (both English and Español). Property
   names and the allowed `tags` options can drift — never write from a
   remembered schema. This also tells you whether the project already exists.
2. **Write both languages.** English body in English, Spanish body in natural
   Spanish (translate meaning, don't calque). Same `slug`, same structure, tags
   drawn from each database's own option list.
3. **Images as explicit placeholders**, never invented URLs. Every screenshot /
   gallery image the user will add later gets a clearly-marked placeholder
   (see the convention in `references/notion.md`) so they're trivial to find and
   replace. Leaving a real-looking but fake image URL is worse than a visible
   placeholder — don't do it.
4. **Create** via `notion-create-pages` under the right `data_source_id`, or
   **update** via `notion-update-page` (prefer targeted `update_content`
   search-and-replace over full `replace_content` — smaller, safer, and it won't
   disturb the user's images/diagrams).

## Phase 5 — Diagrams & interactive HTML blocks

Illustrate the Architecture and Request Flow sections (and optionally a
"Tools/Features at a Glance" grid) with the shared **HTML-block diagram kit** —
interactive, sandboxed, and styled purely with felipego.com's own design-system
CSS variables, so it matches the portfolio and follows the light/dark theme
automatically. This is the default now, replacing static diagram images; native
Mermaid remains an acceptable lighter-weight fallback (see
`references/html-diagrams.md` for when).

Full workflow, the icon sprite, the standard diagram shapes (grouped-tier
architecture is the default, plus numbered flow and card grid), and the exact
script commands are all in
**`references/html-diagrams.md`** — read it before authoring a diagram. In
short:

1. **Author** each diagram's body content from the real architecture you read
   in Phase 3 — don't decorate or invent structure.
2. **Wrap** it with the shared CSS kit: `node scripts/wrap-diagram.mjs
   body.html --out diagram.html` (inlines `assets/diagram-style.css`).
3. **Preview it in both light and dark** with the Chrome DevTools MCP before
   publishing — this is live, public content.
4. **Ship it** with `scripts/notion-html.mjs add/replace`, run from the
   felipego.com site repo checkout (needs `@notionhq/client` +
   `NOTION_API_KEY`, which that repo already has) — once per language.

This phase has side effects on live services just like Phase 4 — confirm the
diagram content with the user before publishing if there's any doubt about
what it depicts.

## Verify (supervised dry-run)

This skill has side effects on live services, so verify by hand rather than by
automated benchmark:

- Re-fetch both Notion pages and confirm the body rendered (headings, code
  blocks, links, and either Mermaid diagrams or HTML blocks all present).
- If HTML-block diagrams were added, confirm in Chrome (locally or
  on the live site) that they render, size themselves, and match the current
  theme — in both light and dark.
- Grep the body for the placeholder marker and read the list back to the user so
  they know exactly what's left to fill in.
- Remind the user the change appears on felipego.com once the site revalidates.

## Final checklist

- [ ] Mintlify wiki generated (or intentionally reused) and read
- [ ] Facts cross-checked against the repo
- [ ] Body follows the house content structure + the right type variant
      (`references/content-structure.md`) — spine sections present, no "At a
      Glance" block, middle adapted to the project type
- [ ] English row created/updated
- [ ] Español row created/updated (same slug)
- [ ] Architecture + Request Flow diagrams present in both (HTML-block kit, or
      Mermaid if that was the better fit)
- [ ] HTML-block diagrams previewed in light + dark before publishing
- [ ] Every image is a visible placeholder, no fabricated URLs
- [ ] Placeholder list reported back to the user
