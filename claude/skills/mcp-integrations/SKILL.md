---
name: mcp-integrations
description: Use whenever the task involves an external integration connected through Executor (Notion, Context7, Firecrawl, Supabase, Neon, Vercel, PostHog, Cloudinary, Higgsfield, or any other MCP surfaced by mcp__executor__execute), and before doing by hand something a connected service already does (testing a migration on a branch, tuning a slow query, reading production logs, checking RLS). Ensures these are always accessed through Executor instead of a direct MCP server, the public API, or the CLI, and says which direct MCPs are the exception.
---

All external integrations go **through Executor** (`mcp__executor__execute`), never a direct MCP server, the public API, or a CLI shortcut. Call `skills({ name: "execute" })` inside Executor first if you're unsure how to write the sandboxed code.

**Discover, don't memorize.** Connections and tool names change over time. Use `tools.search({ query: "...", namespace: "<integration>_mcp" })` (or the bare integration name, e.g. `"vercel"`) to find the exact tool path and argument shape. Any MCP added to Executor shows up here automatically — this skill does **not** keep an inventory of them.

Never construct a tool path or an argument list from memory. `tools.search` returns the path; `tools.describe.tool({ path })` returns the exact `inputTypeScript`. Calling a guessed path costs a `tool_not_found` round trip, and a guessed argument name costs a validation error — both of which the two discovery calls would have avoided.

**Absence from `ToolSearch` is not absence of the integration.** These MCPs are not exposed as `mcp__<name>__*` tools; they live *inside* Executor. Searching the harness tool list for `mcp__supabase__*` and finding nothing proves only that there is no direct server. Before telling the user an integration is unavailable, run `tools.search` inside Executor, or list what is actually connected with `tools.executor.coreTools.connections.list({})`.

## Accounts

Every tool path carries a `.user.<account>` segment, whether the integration has one connected account or several: `context7_mcp.user.context7.resolve_library_id`, `notion_mcp.user.felipegiraldo`, `supabase_mcp.user.centrodeprototipado`. There is no un-suffixed form — `context7_mcp.resolve_library_id` is a `tool_not_found`, not a shortcut. Take the whole path from `tools.search`; never assemble it from the integration name.

Which integrations are split across several accounts changes over time, so check with `tools.search` rather than assuming a given integration has only one.

- `felipegiraldo` is the default; `centrodeprototipado` is only for that project.
- Use the account the user tells you to use — it's the source of truth.
- If the user didn't specify and it isn't obvious, **ask before writing** (reading from the wrong account is harmless; creating/editing, migrations, deploys, or branches are not).
- **Firecrawl is the exception**: `lgiraldoo` and `lufigir` are two free plans (1,000 credits a month each, on different billing dates), not two contexts. Use whichever has credits, and check with `firecrawl_credit_usage` before a batch or when a call fails for credits.

### Health and budgets

`connections.list` returns each connection's `lastHealth`. An `expired` OAuth connection fails every call until the user signs in again in Executor, so when a task needs one, say so up front instead of discovering it mid-task.

Firecrawl's free plan allows roughly ten requests a minute per account, and the counter is shared with any other session using the key. Fan out at most five calls at once; pace a longer list sequentially. A `query` or `json` format costs about five credits against one for plain markdown, so ask a targeted question only when it replaces reading the page.

## Reach by intent

The integrations hold more than the obvious half of their tools. Before doing by hand something a connected service already does, check this table, then find the exact tool with `tools.search`.

| The task | Reach for |
|---|---|
| Try a schema change before it touches real data | Neon's migration flow (apply on a temporary branch, test, then complete or discard); branches on Neon or Supabase |
| A slow query, or which queries are slow | Neon's slow-query list, explain and query-tuning flow on a temporary branch |
| Check a Supabase project after DDL: missing RLS, unsafe functions, unindexed keys | Supabase advisors. Run them after every migration |
| Database types for the app | Supabase's TypeScript type generation |
| A production error, a failed deploy, what the server logged | Vercel runtime logs and deployment events |
| Feature flags | Vercel flags or PostHog, whichever the project uses |
| How users use a product: events, funnels, insights | PostHog. Its single `exec` tool fronts the whole API; read its description first |
| Store, transform or find images and video | Cloudinary, including visual similarity search and generation |
| Generated video, audio, 3D or a quick website | Higgsfield |
| Pages, databases, meeting notes, custom agents in Notion | Notion |
| Structured records across many entities: companies, packages, repos, filings | Firecrawl's Alexandria providers (below) |

## Outside Executor

A few MCPs are connected directly because Executor cannot hold them. The rule "through Executor" covers what Executor has; these have no Executor path, so use them as they are:

| MCP | For | Not for |
|---|---|---|
| `brave` | The only local browser: the local app (console, network, Lighthouse, performance traces, screenshots) and anything behind the user's login, such as the UNAL library (per the `research` skill). Work in tabs you open | Public pages a clean browser can read; use Firecrawl |
| `notebooklm-mcp` | Holding and querying a corpus of sources over weeks | One-off reading |
| claude.ai connectors (Claude Docs, Google Drive, Canva) | Documents to share, the user's Drive files, designs | Anything Executor also connects |

## Context7 (`context7_mcp`)

Two-step flow, worth remembering because it isn't obvious from the tool list:

1. `tools.context7_mcp.user.context7.resolve_library_id({ libraryName, query })` — both required; omitting either one fails validation. `query` is the user's full question, and improves relevance ranking.
2. `tools.context7_mcp.user.context7.query_docs({ libraryId, query })` — use the library ID from step 1 (prefer exact name match, higher benchmark score, and version-specific IDs when the user names a version).

Use it when the user asks about libraries, frameworks, or API references, or needs current code examples instead of relying on training data.

## Firecrawl (`firecrawl_mcp`)

The general research and web-access surface. Not one tool with one use: nine that answer different questions, and picking wrong is what makes it feel redundant with things you already have.

### Against Context7

| | Indexes | Answers |
|---|---|---|
| **Context7** | Official library docs, resolved by version | "How do I use this API in the version installed here?" |
| **`firecrawl_developer_search`** | GitHub issues, **merged pull requests**, READMEs, curated docs | "Does this actually work, or did someone report that it doesn't?" |

Context7 to build, Firecrawl to find out whether you can build on top of it.

The worked example: oxlint's rules reference lists `eslint/no-restricted-syntax`. Context7 confirms it, because the docs say so. The binary does not have it. And the negation semantics the whole boundary table depends on were broken for a year, recorded in an issue and in no documentation anywhere. **Docs describe intent; issues record reality.**

### Reading the web

Three tools, and the difference is how much you already know about where the answer is.

| You know | Tool | Notes |
|---|---|---|
| The exact page | `firecrawl_scrape` | One URL to markdown, or straight to fields against a JSON schema. Prefer it over a plain fetch on heavy or JS-rendered pages |
| The site but not the page | `firecrawl_map` | URL inventory without downloading bodies. `search` narrows it. Use it to find the page, then scrape that one |
| Neither | `firecrawl_search` | Web, news or images. Supports `site:`, `-term`, `inurl:`, quoted phrases. Pass `categories: ["developer"]` to get the developer index alongside the web results in one call |

`firecrawl_crawl` is the fourth, and the one to reach for last. It walks a whole site and the result is enormous; bound it with `limit`, `includePaths` and `maxDepth` every time. Reasonable use: pulling a full documentation set once. Unreasonable use: anything `map` plus two `scrape` calls would have answered.

### Structured data: Alexandria

When a task needs the same fields across many entities (companies, people, package registries, GitHub repos, filings, prices, public records), Firecrawl has typed data providers under the name Alexandria. `firecrawl_search` already returns matching providers in `data.tools`; `firecrawl_find_tools` browses them and returns a provider's contract, and discovery is free; `firecrawl_scrape` with an `alexandria` body runs one and returns sourced records. Prefer a provider over scraping several pages for the same fields. For reading docs or articles it changes nothing.

### Documents

`firecrawl_parse` takes a **file**, not a site: PDF, Word, HTML and more, out as markdown, a summary, targeted answers to a question, or JSON against a schema. This is the one to use for a spec, a contract, a bank statement, a paper somebody sent — anything that would otherwise mean reading a PDF by hand. The schema output is what makes it worth calling instead of skimming: ask for the five fields you need and get them typed.

### Research that can wait

`firecrawl_agent` starts an asynchronous job from a prompt, optional seed URLs and an optional JSON schema. It searches, navigates, reads and assembles a structured result across many sources. It returns **only a job ID**; poll `firecrawl_agent_status` until `completed` or `failed`, which commonly takes several minutes.

Use it when the question is genuinely a synthesis ("compare how these four libraries handle X", "what's the state of Y in 2026") and the answer can wait. Do not use it for anything a `developer_search` answers in one call, and never start one whose result the task cannot afford to wait for.

### The live browser

`firecrawl_interact` opens a remote browser session: navigate, click, fill, or run Bash/Python/Node against the page. Two things to keep straight:

- It is **not the user's browser**. The Brave MCP drives the user's Brave on this machine, which is what you want for debugging the local app, inspecting the console, or anything needing the user's logged-in session. Firecrawl's is a clean remote browser, which is what you want for a site that blocks scraping or needs a form filled to reveal content.
- It **acts on the live site**. Submitting a form is a real, external side effect. Confirm before anything that writes.

Close it with `firecrawl_interact_stop` when done.

### Monitors

`firecrawl_monitor_create` schedules a recurring scrape, crawl or search and **diffs each check against the previous one**, returning a unified text diff for markdown targets or changed field paths for JSON. It can judge whether a change is meaningful against a plain-language `goal`, and notify by email or webhook.

The simple form takes `page`/`pages` or `queries` plus a required `goal`. Retention, schedule and change-tracking format come from the advanced `body` form.

This is the surface with no equivalent anywhere else in the toolkit, and the obvious use here is the `VERIFY:` blocks in `project-architecture`: pointed at the docs a reference depends on, they stop being "remember to re-read this" and become "you get told when it changes". `monitor_run` forces a check now; `monitor_check` and `monitor_checks` read results; `monitor_update` and `monitor_delete` manage them. A monitor schedules real future network work, so create one deliberately, not to satisfy a passing curiosity.

### Papers

`firecrawl_research_search_papers` searches abstracts and metadata across biomedical, life-science, clinical and arXiv literature. `research_read_paper` pulls passages from one paper relevant to a question, `research_inspect_paper` returns canonical metadata for a DOI, PMID, PMC or arXiv id, and `research_related_papers` walks the citation graph from up to ten seeds.

Distinct from `firecrawl_search` with `categories: ["research"]`, which only restricts *web* results to research-affiliated sites. These read the literature itself.

### Feedback

`firecrawl_feedback` rates a completed search, scrape, parse or map job. Send the endpoint, job id, rating and issue codes; never the page contents. Worth doing when a result was badly wrong, since it is what improves the index.
