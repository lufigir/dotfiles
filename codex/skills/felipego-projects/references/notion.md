# Notion reference — felipego.com Projects/Proyectos

Everything you need to read and write the portfolio project rows. Resolve IDs
and schema live every time — never hardcode or remember them, they can drift
if the databases get restructured.

> **Access path:** all `notion-*` tool references in this file route through
> **Executor** — call them inside `mcp__executor__execute` as
> `tools.notion_mcp.user.felipegiraldo.<name_with_underscores>` (e.g.
> `notion-fetch` → `tools.notion_mcp.user.felipegiraldo.notion_fetch`). These
> databases are in the `felipegiraldo` workspace.

## Where the databases live

Find the parent hub page named **"Databases"** (under the `felipego.com`
workspace page) with `notion-search({ query: "Databases" })`, then
`notion-fetch` it — it holds two mirrored sets of databases, an **English**
column and an **Español** column. The two you care about are **Projects**
(English) and **Proyectos** (Español); fetching the hub page (or searching by
name directly) gives you each one's current `data_source_id` / `collection://`
reference.

When creating a page, pass the parent as
`{"type": "data_source_id", "data_source_id": "<the id you just resolved, without the "collection://" prefix>"}`.

**Always `notion-fetch` each data source first** to get the current SQLite schema
and the current `tags` option list. The tool's own guidance says the same — never
write from a remembered schema.

## Schema (both databases share this shape)

Properties: `title` (title), `slug` (text), `description` (text),
`tags` (multi_select), `githubLink` (url), `previewLink` (url),
`order` (number), `show` (checkbox), `img` (file), `gallery` (file).

Value formats for the write tools:

- **`show`** — checkbox: `"__YES__"` to publish, `"__NO__"` to hide. New rows
  should be `"__YES__"` once ready.
- **`tags`** — JSON array of strings, each **must** be an existing option in that
  database's list (fetch to see the current set; English and Español have
  slightly different lists). Example: `["Eve", "Next.js", "PostgreSQL", "Vercel AI SDK"]`.
- **`order`** — number; controls sort position. Match the neighbors' scale
  (existing rows use small integers like 8).
- **`githubLink` / `previewLink`** — plain URL strings. (These are *not* named
  `url`/`id`, so no `userDefined:` prefix is needed. Only properties literally
  named `url` or `id` need that prefix.)
- **`img` / `gallery`** — file properties. You generally can't upload binaries
  here from the MCP; leave the user's existing files untouched on update, and on
  create leave them empty for the user to add (see Placeholders).
- **`title`** — inline markdown string.

## Create vs. update

1. Query by slug in **both** data sources:
   ```
   SELECT url, title, slug FROM "collection://<id>" WHERE slug = '<slug>'
   ```
   (via `notion-query-data-sources`). If SQL mode isn't available on the plan,
   use `notion-search` scoped to the data source instead.
2. **Exists** → `notion-update-page`. Prefer `update_content` with
   `content_updates` (targeted search-and-replace) so you touch only what
   changed and leave the user's images/diagrams alone. Use `update_properties`
   for property changes.
3. **Doesn't exist** → `notion-create-pages` under the data source, with
   properties + body.

Do both languages. Keep `slug` identical across the two rows — that's the join
key felipego.com uses.

## Page-body template

The site renders the page body below the properties. Keep this house structure
(seen on existing rows). Headings in the row's own language.

**Read `references/content-structure.md` first** — it defines this structure in
full, says *what information each section should show*, and gives the type
variants (full-stack app / AI agent / ML-data project / small tool) you pick
between. The template below is the default (full-stack) shape; adapt the middle
to the variant that matches the project.

```
<one-paragraph intro: what it is, who it's for, the problem it removes>

## Architecture and Tech Stack        (ES: ## Arquitectura y Stack Tecnológico)
### Core Architecture                 (ES: ### Arquitectura Central)
- **Agent framework / Framework**: ...
- **Model / Modelo**: ...
- **Frontend**: ...
- **Database / Base de datos**: ...
- **Validation / Validación**: ...
- **UI**: ...
### Layered Architecture              (ES: ### Arquitectura en Capas)
[diagram goes here — Phase 5 appends it as an HTML block right after this heading]
<one paragraph explaining the layering>
### Request Flow                      (ES: ### Flujo de una Petición)
[diagram goes here — Phase 5 appends it as an HTML block right after this heading]

## Key Features                       (ES: ## Características Principales)
### <feature>                         (short, concrete, one paragraph each)
### Tools/Features at a Glance        (optional: diagram appended here in Phase 5 too)
...

## Technical Highlights               (ES: ## Destacados Técnicos)
### <highlight>
...

## Project Structure                  (ES: ## Estructura del Proyecto)
```plain text
<annotated file tree>
```

## Impact and Scalability             (ES: ## Impacto y Escalabilidad)
- ...

---
## Notes                              (ES: ## Notas)
Built on <stack>. Code is public on [GitHub](<repo url>). For a deeper
technical deep-dive, see the full [documentation wiki](<mintlify url>).
<IMAGE PLACEHOLDERS for screenshots go here or inline near their sections>
```

Write the Spanish body in natural Spanish — translate meaning, don't calque
English word order. Technical tokens (`eve`, `Zod`, tool names, file paths) stay
as-is in both.

Don't add a quick-facts/"At a Glance" block before the Architecture section —
the site's project card and page header already show the stack (with real tech
logos), links, and status; a body-level summary just repeats the intro
paragraph.

## Diagrams — HTML-block kit by default, Mermaid as fallback

The default way to illustrate Architecture and Request Flow is now the shared
**HTML-block diagram kit** — interactive, theme-aware, styled with the site's
own design tokens. Full workflow, the three standard diagram shapes, the
preview-before-shipping steps, and the scripts that create/replace the blocks
are all in **`references/html-diagrams.md`** — read it before authoring any
diagram. No Excalidraw, no external image services either way.

Base every diagram on the real architecture you read from the wiki/repo — don't
decorate. If a diagram would be guesswork, skip it (prefer an image placeholder)
rather than inventing structure.

Mermaid (fenced ` ```mermaid ` blocks, native Notion rendering) is still an
acceptable lighter-weight option — see "When Mermaid is still fine" in
`references/html-diagrams.md` for when to reach for it instead.

## Image placeholders — explicit and greppable

The user fills images in by hand later, so make every image slot **impossible to
miss and trivial to find**. Never insert a real-looking image URL you don't have
— a fake `res.cloudinary.com/...` link is worse than a visible placeholder
because it looks done and rots silently.

Use this exact marker so it's greppable:

```
> 🖼️ **IMAGE PLACEHOLDER** — <what this image should show, e.g. "budget-vs-actual chart in dark mode">
```

Put one wherever the house layout expects a screenshot (e.g. under "Tools at a
Glance", near a feature it illustrates, in the gallery area). After writing, grep
the body for `IMAGE PLACEHOLDER` and report the full list back to the user so
they know exactly what to replace and where.

Leave the `img` and `gallery` file **properties** empty on create (the user adds
files in the Notion UI); don't clear them on update.

## HTML blocks — see references/html-diagrams.md

A Notion **HTML block** is an `embed` block backed by an uploaded `.html` file.
felipego.com renders it in a sandboxed, theme-aware iframe — this is now the
default mechanism for Architecture/Request-Flow diagrams and any interactive
widget (see the Diagrams section above). **`references/html-diagrams.md`** has
the full workflow: the shared CSS kit, the three standard diagram shapes,
authoring/preview/shipping steps, and the scripts (`scripts/wrap-diagram.mjs`,
`scripts/notion-html.mjs`) that build and publish them — `notion-create-pages`
/ `notion-update-page` cannot create HTML blocks themselves, only those scripts
(run from the felipego.com site repo checkout) can.
