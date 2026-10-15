---
name: mcp-integrations
description: Use whenever the task involves an external integration connected through Executor (Notion, Context7, Firecrawl, Supabase, Neon, Vercel, PostHog, Cloudinary, Higgsfield, or any other app surfaced by the mcp__executor__* tools), and before doing by hand something a connected service already does (testing a migration on a branch, tuning a slow query, reading production logs, checking RLS). Ensures these are always accessed through Executor instead of a direct MCP server, the public API, or the CLI, and says which direct MCPs are the exception.
---

All external integrations go **through Executor**, never a direct MCP server, the public API, or a CLI shortcut. Executor exposes five tools:

| Tool | For |
|---|---|
| `mcp__executor__search` | Find tools: exact `path`, one-line description, input type, and each app's linked accounts |
| `mcp__executor__describe` | Full description and TypeScript signature (input and output) for up to 20 paths |
| `mcp__executor__call` | One call, or an array of independent calls run concurrently |
| `mcp__executor__execute` | A JavaScript program, when one result feeds the next call or a large result must be filtered before it reaches you |
| `mcp__executor__resume` | Continue a call paused for approval or input, with the user's answer. Never rerun the call instead |

Executor's own guidance lives in `mcp__executor__skills`: `{ app: "executor", name: "executor" }` to start, `name: "code-mode"` before writing a non-trivial `execute` program. Each app also ships a `tools` skill (`{ app: "<slug>" }`).

**Discover, don't memorize.** Apps, tool names and accounts change over time. `search` with a `namespace` (the app slug) and a small `limit` returns the exact path and input shape. Any app added to Executor shows up there automatically; this skill does **not** keep an inventory of them.

Never construct a path or an argument list from memory. Paths use the app slug, and slugs with a hyphen need bracket notation: `tools["notion-mcp"].notion_search`, `tools.firecrawl.developer.developerSearch`. Copy them exactly as `search` returns them. A guessed path costs an `UnknownTool` round trip and a guessed argument costs an `InvalidToolInput`; `search` and `describe` would have avoided both.

**Absence from `ToolSearch` is not absence of the integration.** These apps are not exposed as `mcp__<name>__*` tools; they live *inside* Executor. Before telling the user an integration is unavailable, run `search` and read `unavailableApps` in the result.

## Accounts

Every call takes the account as an argument, next to the tool's own input:

```js
tools["notion-mcp"].notion_search({ accountId: "acc_…", input: { query: "…" } })
```

`search` lists each app's linked accounts once in `namespaces`, with an ID and a label (`acc_0baa… (lufigir) | acc_4527… (centrodeprototipado)`). Pick the account by its label and pass its `accountId`; never reuse an ID from memory, since relinking an account changes it. Which integrations have several accounts changes over time, so read the list rather than assuming.

- `lufigir` is the default, the personal account (Cloudinary still labels it `felipegiraldo`); `centrodeprototipado` (Vercel: `centroDePrototipadoFullAccount`) is only for that project.
- An app with a single linked account uses that one, whatever its label: today PostHog is on `centrodeprototipado` and Higgsfield on `lgiraldoo`.
- Use the account the user tells you to use: it's the source of truth.
- If the user didn't specify and it isn't obvious, **ask before writing** (reading from the wrong account is harmless; creating/editing, migrations, deploys, or branches are not).
- **Firecrawl is the exception**: `sekuz`, `lufigir`, `lgiraldoo` and `luisgir827` are four free plans (1,000 credits a month each, on different billing dates), not contexts. Use whichever has credits: check `tools.firecrawl.billing.getCreditUsage` for all four before a batch, or when a call fails for credits.

### Health and budgets

An app with no linked account, or one whose server did not answer, comes back in `unavailableApps` with a `reason`; calling it fails with that reason. `executor.appAccounts.userList({ path: { app: "app_…" } })` (the app ID from `executor.appManagement.list`) returns each linked account's sign-in state and last health check. When a task needs a broken one, say so up front instead of discovering it mid-task. Accounts connect only through Executor's secure links (`appAccounts.userConnect` in the `executor` app), never by pasting a secret into chat.

Firecrawl's free plan allows roughly ten requests a minute per account, and the counter is shared with any other session using the key. Fan out at most five calls at once; pace a longer list sequentially. A `query` or `json` format costs about five credits against one for plain markdown, so ask a targeted question only when it replaces reading the page.

An `execute` program allows 100 tool calls, 5 minutes and 64 KB of output; return only the fields you need.

## Reach by intent

The integrations hold more than the obvious half of their tools. Before doing by hand something a connected service already does, check this table, then find the exact tool with `search`.

| The task | Reach for |
|---|---|
| Try a schema change before it touches real data | Neon's migration flow (apply on a temporary branch, test, then complete or discard); branches on Neon or Supabase |
| A slow query, or which queries are slow | Neon's slow-query list, explain and query-tuning flow on a temporary branch |
| Check a Supabase project after DDL: missing RLS, unsafe functions, unindexed keys | Supabase advisors (`get_advisors`). Run them after every migration |
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

## Context7 (`context7`)

Generated from Context7's REST API, so the parameters go under `input.query`. Two ways in:

1. **When you know the library**: `search.searchLibraries({ accountId, input: { query: { libraryName, query } } })`, both required, with `query` as the user's full question for ranking; then `context.getContext({ accountId, input: { query: { libraryId, query, type: "txt" } } })` with the chosen ID (prefer exact name match, higher `benchmarkScore`, and a version-specific ID when the user names a version).
2. **When you don't**: `search.searchDocumentation({ accountId, input: { query: { query, type: "txt" } } })` picks the library and returns the snippets in one call, slower. Narrow it with `library` and `version` when you can.

`type: "txt"` returns readable snippets; the default is JSON. The `addLibrary.*`, `refresh` and `policies` tools change the shared Context7 index or the teamspace: confirm before calling them.

Use it when the user asks about libraries, frameworks, or API references, or needs current code examples instead of relying on training data.

## Firecrawl (`firecrawl`)

The general research and web-access surface. Not one tool with one use: a dozen groups that answer different questions, and picking wrong is what makes it feel redundant with things you already have.

The app is generated from Firecrawl's REST API, so inputs follow the HTTP shape: query-string parameters under `input.query`, path parameters under `input.path`, the payload under `input.body`. Several tools (scrape, monitors, feedback) type their `body` as `unknown`. For those, read the request body in Firecrawl's API reference (`support.searchSupportDocs`, or Context7) before calling; don't guess field names.

### Against Context7

| | Indexes | Answers |
|---|---|---|
| **Context7** | Official library docs, resolved by version | "How do I use this API in the version installed here?" |
| **`developer.developerSearch`** | GitHub issues, **merged pull requests**, READMEs, curated docs. Filter with `types`, `repos`, `language` | "Does this actually work, or did someone report that it doesn't?" |

Context7 to build, Firecrawl to find out whether you can build on top of it.

The worked example: oxlint's rules reference lists `eslint/no-restricted-syntax`. Context7 confirms it, because the docs say so. The binary does not have it. And the negation semantics the whole boundary table depends on were broken for a year, recorded in an issue and in no documentation anywhere. **Docs describe intent; issues record reality.**

### Reading the web

Three tools, and the difference is how much you already know about where the answer is.

| You know | Tool | Notes |
|---|---|---|
| The exact page | `scraping.scrapeAndExtractFromUrl` | One URL to markdown, or straight to fields against a JSON schema. Prefer it over a plain fetch on heavy or JS-rendered pages. `scrapeAndExtractFromUrls` runs a batch as a job |
| The site but not the page | `mapping.mapUrls` | URL inventory without downloading bodies. `search` narrows it. Use it to find the page, then scrape that one |
| Neither | `search.searchAndScrape` | Web, news or images (`sources`). Supports `site:`, `-term`, `inurl:`, quoted phrases. Pass `categories: [{ type: "developer" }]` to get the developer index alongside the web results in one call |

`crawling.crawlUrls` is the fourth, and the one to reach for last. It walks a whole site and the result is enormous; bound it with `limit`, `includePaths` and `maxDiscoveryDepth` every time, and poll `getCrawlStatus`. Reasonable use: pulling a full documentation set once. Unreasonable use: anything a map plus two scrapes would have answered.

### Structured data: Alexandria

When a task needs the same fields across many entities (companies, people, package registries, GitHub repos, filings, prices, public records), Firecrawl has typed data providers under the name Alexandria. `search.searchAndScrape` with `sources: [{ type: "alexandria" }]` returns matching provider contracts in `data.tools` instead of results, and that discovery is free; a scrape with the provider runs it and returns sourced records. Prefer a provider over scraping several pages for the same fields. For reading docs or articles it changes nothing.

### Documents

A PDF or document **at a URL** goes through `scrapeAndExtractFromUrl`, which parses it. `scraping.parseFile` takes the file's bytes as base64 instead, for a file somebody sent; the base64 counts against the 64 KB program source limit of `execute`, so it only fits small files. Either way the output is markdown, a summary, targeted answers to a question, or JSON against a schema. The schema output is what makes it worth calling instead of skimming: ask for the five fields you need and get them typed.

### Research that can wait

`agent.startAgent` starts an asynchronous job from a `prompt`, optional seed `urls` and an optional JSON `schema`. It searches, navigates, reads and assembles a structured result across many sources. It returns **only a job ID**; poll `agent.getAgentStatus` until `completed` or `failed`, which commonly takes several minutes, and never poll inside one `execute` program. Set `maxCredits` low: the default is 2,500, more than a free plan holds.

Use it when the question is genuinely a synthesis ("compare how these four libraries handle X", "what's the state of Y in 2026") and the answer can wait. Do not use it for anything a developer search answers in one call, and never start one whose result the task cannot afford to wait for.

### The live browser

`interact.createBrowserSession` opens a remote browser session, and `interact.executeBrowserCode` navigates, clicks, fills, or runs code against the page. Two things to keep straight:

- It is **not the user's browser**. The Brave MCP drives the user's Brave on this machine, which is what you want for debugging the local app, inspecting the console, or anything needing the user's logged-in session. Firecrawl's is a clean remote browser, which is what you want for a site that blocks scraping or needs a form filled to reveal content.
- It **acts on the live site**. Submitting a form is a real, external side effect. Confirm before anything that writes.

Close it with `interact.deleteBrowserSession` when done.

### Monitors

`monitoring.createMonitor` schedules a recurring scrape, crawl or search and **diffs each check against the previous one**, returning a unified text diff for markdown targets or changed field paths for JSON. It can judge whether a change is meaningful against a plain-language `goal`, and notify by email or webhook.

This is the surface with no equivalent anywhere else in the toolkit, and the obvious use here is the `VERIFY:` blocks in `project-architecture`: pointed at the docs a reference depends on, they stop being "remember to re-read this" and become "you get told when it changes". `runMonitor` forces a check now; `getMonitorCheck` and `listMonitorChecks` read results; `updateMonitor` and `deleteMonitor` manage them. A monitor schedules real future network work, so create one deliberately, not to satisfy a passing curiosity.

### Papers

`research.researchSearchPapers` searches abstracts and metadata across biomedical, life-science, clinical and arXiv literature. `research.researchGetPaper` takes a DOI, PMID, PMC or arXiv id: without a `query` it returns canonical metadata, with one it pulls the passages relevant to that question. `research.researchRelatedPapers` walks the citation graph from up to ten seeds.

Distinct from `search.searchAndScrape` with `categories: [{ type: "research" }]`, which only restricts *web* results to research-affiliated sites. These read the literature itself.

### Feedback

`feedback.submitEndpointFeedback` (and `search.submitSearchFeedback` for a search) rates a completed job. Send the endpoint, job id, rating and issue codes; never the page contents. Worth doing when a result was badly wrong, since it is what improves the index.
