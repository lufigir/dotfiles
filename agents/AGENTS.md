# Global instructions

- Pick the agent and model for a worker from `D:\Code\dotfiles\agents\models.md`.
<!-- agy -->
- Respond in Spanish (`Español`) by default unless the user writes in another language, and keep responses concise.
<!-- /agy -->
<!-- claude -->
- Don't add attribution lines to git commit messages or PR descriptions: no `Co-Authored-By: Claude ...`, no `Claude-Session: ...` and no session link.
<!-- /claude -->
<!-- agy -->
- Don't add attribution lines to git commit messages or PR descriptions: no `Co-Authored-By: ...`, no agent or session trailers, and no session links.
<!-- /agy -->
- External integrations (Notion, Context7, Vercel, Supabase, …) always go **through Executor** ({{executor}}: `search` and `describe` to find a tool, `call` to run it, `execute` to chain calls), never a direct MCP or the public API. Every call takes an `accountId`, listed by `search`; see the `mcp-integrations` skill for the details, including the integrations that have more than one connected account: use the one the task specifies, and ask before writing if it isn't clear.
- **Firecrawl is the research and web-access surface**, and the reflex to build before answering from memory or from a single doc page. In the `firecrawl` app: `developer.developerSearch` for how a library, API or tool actually behaves (it indexes issues and merged PRs, so it knows the difference between what the docs claim and what people found); `search.searchAndScrape` for the open web, `scraping.scrapeAndExtractFromUrl` and `mapping.mapUrls` when you know the page or the site (a scrape also parses a PDF at a URL), `agent.startAgent` for a synthesis that can wait minutes, `interact.*` for a remote browser, `monitoring.*` to be told when a page changes, `research.*` for open scientific literature (arXiv, PubMed). The split with Context7: **Context7 answers "how do I use this", Firecrawl answers "does this actually work"**. Always reach for it before building on a documented feature you have not seen run. The `mcp-integrations` skill has the per-tool guidance.
- **Research of any kind starts in the `research` skill**: it picks the source for the question, and it is the only route to scholarly literature, the UNAL library subscriptions (Scopus, Web of Science and ~170 more) reached in the user's Brave ({{browse}}).
<!-- claude -->
- **Orca is the harness; when it and Claude Code both offer a tool, one of them owns the job.** Browser: the user's Brave ({{browse}}) for anything behind a login or the local app, Firecrawl for public pages; Orca's embedded browser and `orca computer` only when the user asks for them. Anything later or recurring: an Orca automation, never `CronCreate`, `/loop` or `/schedule`, which die with the session or run in the cloud without this machine's repos. Code work in its own workspace: an Orca worker; the `Agent` tool stays for short searches inside a session. Memory: the bot's `MEMORY.md` in Orca, not Claude Code's auto-memory. Gmail and Calendar: through Executor, not `orca gmail|calendar`.
<!-- /claude -->
<!-- agy -->
- **Orca is the harness; when it and Antigravity CLI (`agy`) both offer a tool, one of them owns the job.** Browser: the user's Brave ({{browse}}) for anything behind a login or the local app, Firecrawl for public pages; `agy`'s `/browser`, Orca's embedded browser, and `orca computer` only when the user asks for them. Anything later or recurring: an Orca automation, never `agy`'s `schedule` tool or `/schedule`, which die with the session. Code work in its own workspace: an Orca worker; `invoke_subagent` stays for short searches inside a session. Memory: the bot's `MEMORY.md` in Orca. Gmail and Calendar: through Executor, not `orca gmail|calendar`.
<!-- /agy -->
- **This machine is Windows, and Python's default stdout encoding is cp1252.** Any script that prints or writes text with accents, box-drawing characters or emoji dies with `UnicodeEncodeError` — including scripts you did not write. Run Python as `PYTHONUTF8=1 python ...`, and reach for `python` rather than `python3` (the `python3` alias resolves to the Microsoft Store stub and fails with "Python was not found").
<!-- claude -->
- There are personal skills in `~/.claude/skills` for recurring tasks. Check them when the task's name isn't obvious from the task itself. Some are off by default in `skillOverrides` and so don't show up in the available list; they're invoked by name (`/felipego-projects`). Others are slash-only by design (`disable-model-invocation`) and also stay out of that list — invoke them by name too: `/grill-me`.
<!-- /claude -->
<!-- agy -->
- Personal skills are linked in `~/.gemini/config/skills` (shared with `dotfiles/agents/skills`) and are also exposed as `/<skill-name>` slash commands. Project-specific opt-in skills (such as `felipego-projects`) stay out of the global folder and are loaded per project via `.agents/skills.json` when needed.
<!-- /agy -->
- **`D:\Code\life-os` is the user's private life repo** (documents, processes, notes). In a work repo shared with a team, what serves anyone on the product (code, spec, ADRs, technical research) stays in the repo; what is the user's own side of that job (their plan, invoices, execution reports, their meeting notes, a proposal not yet shared) goes to that job's process in `life-os/procesos/`, mapped in the "Repos de código" table of its README. Product research still open lives in that process; once decided, the final document moves to the repo (ADR or `docs/`, through a PR) and the process keeps only a log line pointing to it, never a copy in both. Shared repos never mention life-os.

## Working style

- Before implementing anything non-trivial: if there's ambiguity or multiple interpretations, ask instead of silently assuming.
<!-- claude -->
- **Ask through the `AskUserQuestion` selector, not in prose.** Default for every question with an enumerable answer, inside skills and outside them. Prose is only for what has nothing to pick from (a name, a URL, a free-form constraint).
  - One decision per question object; each renders as its own tab, and `header` is the tab label, so keep it under 12 characters.
  - Default to **3 options**, recommendation first, labelled `(Recomendado)`. Keep labels short and put the trade-off (what it buys, what it costs) in `description`. Two options only for a real binary, four only when the fourth is materially different.
  - The UI adds "Other" by itself, so never spend an option on "something else". When part of the answer is open (a date, a number), say in the question text that it goes in "Other".
  - `multiSelect: true` only when the choices genuinely combine, and there **never** tag options `(Recomendado)`: state the recommendation in the question instead.
  - A call caps at **4 tabs** and a tab at **4 options**. More decisions means chaining back-to-back calls; more candidates means the decision is badly grouped, so split or merge it.
<!-- /claude -->
<!-- agy -->
- **Ask through `ask_question`, not in prose** (unless dispatched as an Orca worker, where questions go through `orca orchestration ask`). Default for every question with an enumerable answer, inside skills and outside them. Prose is only for what has nothing to pick from (a name, a URL, a free-form constraint).
  - One decision per question item. Default to **3 options**, recommendation first, labelled `(Recommended)`. Two options only for a real binary, four only when the fourth is materially different.
  - The UI adds "Other" and numbering by itself, so never spend an option on "something else". When part of the answer is open (a date, a number), say in the question text that it goes in "Other".
  - `is_multi_select: true` only when the choices genuinely combine, and there **never** tag options `(Recommended)`: state the recommendation in the question instead.
<!-- /agy -->
- **Prose a person will read** (docs, READMEs, skills, reports, PR and commit bodies, messages, university deliverables), in Spanish or English, goes through the `humanize` skill before it ships.
- **When the user asks to clear the session** (or for a prompt to continue in a new one), first decide whether anything must survive. A next task unrelated to this one: tell them to run `/clear` with no prompt, since the repo, `AGENTS.md`, commits and memory already carry what matters. The same task continuing, or work moving to another repo, account or harness: give a continuation prompt of at most 15 lines that points at files, commits, branches and docs by path instead of copying their content, and names the next step and how to verify it. Write it right away: after the prompt cache expires, the turn rereads the whole conversation at full price.<!-- claude --> A path to abandon is `Esc Esc` (rewind), cheaper than `/compact`.<!-- /claude -->
- Surgical changes: only touch what the task asks for; don't "improve" adjacent code or delete unrelated dead code (mention it instead).

## Engineering principles

- No backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers: start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Don't reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Don't assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Don't accept a stopgap that only works for now and is meant to be replaced later.
