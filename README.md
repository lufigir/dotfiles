# dotfiles

Personal configuration files, symlinked from here to keep them in sync across machines.
`install.ps1` runs on Windows, macOS and Linux under PowerShell 7+, detects the OS and
links each config where that system expects it.

## Contents

- `wezterm/.wezterm.lua` — WezTerm terminal config (theme, keybindings, panes, tab bar)
- `oh-my-posh/material.omp.json` — Oh My Posh prompt theme (Material, tweaked)
- `powershell/Microsoft.PowerShell_profile.ps1` — PowerShell profile (Oh My Posh init + Linux-style aliases + the purple theme applied to `$PSStyle` and PSReadLine; `touch`/`which`/`grep` are defined on Windows only, since on macOS/Linux the real binaries are on PATH and beat these stand-ins. When [eza](https://github.com/eza-community/eza) is installed it takes over the listings: `ls` is the plain grid with icons, `la` adds dotfiles, `ll` is the detailed list (size, relative date, per-file git status and the branch of any subdirectory that is a repo), `lt` is a 2-level tree and `lg` swaps the branch column for the full git status of each subrepo (seconds, not milliseconds). eza prints text rather than objects, so pipe from `gci` instead)
- `claude/settings.json` — global Claude Code settings (model, hooks, plugins, skillOverrides)
- `claude/CLAUDE.md` — global Claude Code instructions (commit rules, pointer to personal skills)
- `claude/skills/` — personal Claude Code skills (see the opt-in model below)
- `zed/settings.json` — Zed editor settings (theme, fonts, LSP, agent)
- `lint/` — the lint preset that every project copies: oxlint with the boundary,
  evidence, design-system (`@shadcn/lint`) and framework families, oxfmt for
  formatting, `anti-slop` vendored, a CI workflow, and `rule-tests/`, which asserts the rules still bite.
  One vendor (oxc), no ESLint, no Prettier. See `lint/README.md`; the reasoning lives
  in `project-architecture`'s `lint-guardrails.md` reference
- `zed/extensions.md` — reference list of installed extensions (manual install, see note below)

### Personal skills

- `commit-and-push` — git add + version bump + commit + push
- `mcp-integrations` — Notion, Context7, Supabase, Vercel through Executor (Notion and Supabase have 2 accounts each: `felipegiraldo` and `centrodeprototipado`)
- `project-architecture` — two modes: bootstrap a new project with a layered architecture, and answer architecture questions mid-build against the repo's own `AGENTS.md`; 12 references (layers, routing, DAL, schema and migrations, multi-tenancy, API contracts, async work, uploads, security, performance, operations, design system) whose version-specific claims are always verified against the live docs
- `felipego-projects` — publish/update felipego.com portfolio projects in Notion; off by default
- `deslop` — taste-level review of a branch's diff for the patterns that mark AI-written
  code: narrated comments, placeholder names, wrappers around one call, defensive
  catches that swallow, tests that mock everything. Twenty-four rules in six categories,
  with a verdict band. Runs inside `commit-and-push` on every diff that touches code
  (safe fixes applied, the rest reported) and on demand as `/deslop`. Deliberately the complement of the
  linter rather than an overlap: lint owns the rules with a syntactic shape, this owns
  the ones with only a smell

Check each skill's `SKILL.md` for the current, authoritative on/off state and
scope — the list above is descriptive, not the source of truth; `claude/settings.json`'s `skillOverrides` is.

### Vendored skills (Matt Pocock)

Vendored from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) at commit
`84fdeff`, replacing the `superpowers` plugin. Vendored rather than installed as a plugin
for two reasons: `Clean-ClaudeBaseline` deletes anything in `~/.claude/skills` that isn't a
symlink into this repo, and the plugin is read-only — the descriptions need editing (see below).

**Auto-invoked** (they fire on their own when the context matches):

- `grilling` — the relentless interview: asks the whole *frontier* of unblocked questions per round, numbered, each with a recommended answer, and dispatches sub-agents to look up facts instead of asking. This is what replaced `superpowers:brainstorming`.
- `diagnosing-bugs` — diagnosis loop for hard bugs, starting from a failing repro
- `writing-for-agents` — how to write skills, `CLAUDE.md` and `AGENTS.md`

**Slash-only** (`disable-model-invocation: true` upstream — deliberate: these are expensive
verbs you trigger, not criteria that fire on their own):

- `/grill-me` — one-line alias that runs a `grilling` session

**Local modifications** — only the `description` frontmatter:

- Each description gained **Spanish trigger phrases**. Upstream only lists English ones, and `claude/settings.json` sets `"language": "Español"`, so a prompt like *"no funciona el login"* or *"vamos a armar el dashboard"* would never have matched.
- `grilling`'s description also carries the "MUST use before any creative work" framing that made `superpowers:brainstorming` fire reliably.

**Deliberately not vendored:** `research` (would bypass the Executor rule in `CLAUDE.md`),
`code-review` (collides with Claude Code's built-in `/code-review`), `setup-matt-pocock-skills` (writes its own repo
context file, which `AGENTS.md` already is), the `to-spec`/`to-tickets`/`implement`
pipeline, and the human-facing set (`teach`, `triage`, `wizard`, `wayfinder`, `handoff`, `wait-what`, `prototype`).

**Dropped after measuring** — counted over 85 session transcripts, both were invoked zero
times:

- `domain-modeling` maintained a `CONTEXT.md` glossary and ADRs under `docs/adr/`. Neither
  file exists in any of the twenty projects, and both duplicate something that does: the
  glossary is what `AGENTS.md` already carries, and the entity model is the ERD that
  `project-architecture`'s bootstrap produces. Three sources of truth for one domain model
  is the failure mode those references warn about. Every skill that read `CONTEXT.md` now
  reads `AGENTS.md`.
- `resolving-merge-conflicts` never fired because the scenario does not arise: work is solo
  and `commit-and-push` lands everything on `main`.
- `tdd`, `codebase-design` and `/improve-codebase-architecture` were dropped in a second
  count: zero invocations over 28 sessions (2026-09-13 to 2026-09-24), even after
  `project-architecture` started routing into the first two.

The same count explained the rest. `mcp-integrations` (13 invocations), `grilling` (11) and
`commit-and-push` (9) are the only ones with real usage, and the only ones with a **routing
mechanism**: the first is named in `CLAUDE.md`, the second carries a "MUST use before any
creative work" framing, the third is a verb you type. The others were islands — nothing
pointed at them. `project-architecture` now routes into `diagnosing-bugs` at the moment it applies, which is the fix: a good skill nothing reaches
is a skill that does not exist.

**Updating:** there's no auto-update — re-copy from upstream and re-apply the description
edits above. `agents/openai.yaml` is dropped from each skill (it's Codex config).

#### Opt-in model (per-project enablement)

All skills live globally (symlinked, synced), but the global default is **lean**: only the universal ones stay ON. Situational/single-project skills are OFF by default via `skillOverrides` in `claude/settings.json` and get turned on **per project** in that repo's own `.claude/settings.json` (project config overrides the global one).

To enable one in a project, in its `.claude/settings.json`:

```json
{ "skillOverrides": { "felipego-projects": "on" } }
```

#### Measuring whether a skill fires (`claude plugin eval`)

A skill's `description` is the only thing that decides whether it gets invoked, and editing
one is guesswork until it is measured. [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals)
runs a prompt in an isolated session and a `tool_used: Skill` grader says whether the skill
was actually chosen, so a description change can be checked before it is committed instead
of being audited months later by counting transcripts.

The command needs a plugin root, so `claude/.claude-plugin/plugin.json` wraps this directory
as a plugin named `dotfiles-skills`. A plugin auto-discovers its skills in `skills/`, which
is already the layout here, so nothing moved and no symlink was needed. The manifest is inert
outside eval runs: `install.ps1` links `settings.json`, `CLAUDE.md` and each skill folder
individually, never this directory, so Claude Code has no path by which to load it as a plugin
in a normal session.

Cases live in `claude/evals/<case>/`, one `prompt.md` plus one or more graders:

```powershell
claude plugin eval ./claude --ablation none --runs 3   # trigger suite, no judge calls
claude plugin eval ./claude --case <case> --runs 1     # one case while iterating
```

`--ablation none` runs only the with-plugin arm. The default also runs every case again with
no plugin loaded and reports `Δ`, the contribution of the plugin, which doubles the cost and
tells you nothing extra when the grader is "was this skill invoked" (that check cannot pass
without the plugin, so the eval excludes it from the score in both arms anyway).

Keep graders free where possible: `regex`, `tool_used`, `tool_order` and `file_exists` are
computed from the transcript, while `llm` and `baseline` call a judge model. Each trigger
case costs about $0.20 per run of the suite, all of it the agent runs themselves.

The first run of `claude plugin validate ./claude` paid for the whole exercise: it found that
`project-architecture`'s `description` was an unquoted YAML scalar containing `week six: where
does this file go`, which fails to parse, so the skill had been loading with **empty metadata**
and no description at all. It could never have been auto-invoked. The description is now a
folded block scalar (`description: >`), the same shape the Pocock skills use.

Note that the `skill-creator` plugin has its own `evals/evals.json` format, which is
unrelated and incompatible with this one.


## Zed

`settings.json` is symlinked from `%APPDATA%\Zed` on Windows and from
`~/.config/zed` on macOS and Linux. Extensions can't be
symlinked (Zed has no CLI or declarative file to install them);
`zed/extensions.md` is just a manual reference list for installing them by
hand from the editor (`Ctrl+Shift+X` or the `zed: extensions` command palette).

## MCP and plugins

Three MCP servers are part of the baseline. None of them lives in the repo (they're registered in `~/.claude.json`, which isn't symlinkable) — the `claude` component of `install.ps1` adds all three with `claude mcp add`.

- **Executor** (`mcp__executor__execute`) — all external integrations (Notion, Context7, Supabase, Vercel) go through this single MCP server hosted at executor.sh, which centralizes connections and supports multiple accounts per integration (2 Notion workspaces, 2 Supabase organizations, etc.). Connections themselves are managed in the Executor dashboard, not in this repo. The first time, authorize it with `/mcp`.
- **Chrome DevTools** (`mcp__chrome-devtools__*`) — browser automation and debugging: navigate, click/fill, snapshots and screenshots, console and network inspection, performance traces. Runs locally over stdio (`npx -y chrome-devtools-mcp@latest`, needs **Node 22+** and Google Chrome) and drives its **own dedicated Chrome profile**, so it never touches the personal one. The profile persists, so any sign-in only has to happen once. This replaces the Claude in Chrome extension.
- **NotebookLM** (`mcp__notebooklm-mcp__*`) — NotebookLM notebooks as a long-context knowledge system: query a notebook (`notebook_query`), add sources (`source_add`), generate/download studio content, share, etc. Runs locally over stdio from PyPI (`uvx --from notebooklm-mcp-cli notebooklm-mcp`, needs [uv](https://docs.astral.sh/uv/): `winget install astral-sh.uv`, `brew install uv`, or `curl -LsSf https://astral.sh/uv/install.sh | sh`), so nothing is installed permanently. Auth is **cookie-based per Google account**: run `uvx --from notebooklm-mcp-cli nlm login` once (it opens a browser). It exposes ~43 tools, so keep it **toggled off with `/mcp`** unless the project actually uses a notebook. It uses undocumented internal APIs, so it can break without notice.
- **Plugins:** only **`skill-creator`** is used. Plugins don't live in the repo (they're installed from the Claude Code store); `install.ps1` runs `claude plugin install skill-creator@claude-plugins-official`. **`superpowers` was dropped** — its skill set is replaced by the vendored Matt Pocock skills below, which cover the same ground in a fraction of the words and don't force a fixed idea→ship pipeline.
- **Cleanup:** at the end, `install.ps1` leaves Claude on this exact baseline. It detects whatever's extra on the other PC (plugins ≠ skill-creator, MCP ≠ executor/chrome-devtools/notebooklm-mcp, loose skills in `~/.claude/skills`, and unmanaged `rules`/`settings.local.json`), shows the plan, and asks for **one single confirmation** (default No) before deleting. If there's nothing outside the baseline, it doesn't ask.

## Installing on a new machine

1. Install **PowerShell 7+** — it's the shell everywhere and the installer runs on it.
   Windows already ships it via `winget install Microsoft.PowerShell`; on macOS
   `brew install powershell/tap/powershell`; on Linux see [the Microsoft docs](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux).
2. **Windows only:** enable **Developer Mode** (Settings > Privacy & security > For developers) so symlinks can be created without admin. macOS and Linux need nothing.
3. Clone the repo and run the installer:

   ```powershell
   git clone https://github.com/astrxnomo/dotfiles.git ~/Code/dotfiles
   pwsh ~/Code/dotfiles/install.ps1
   ```

4. Pick the components you want on this machine — everything starts checked, so a bare
   Enter installs the lot. Anything missing is reported at the end with the install
   command for that OS: the installer links configs, it never installs packages.
5. Restart WezTerm / open a new PowerShell tab.
6. Open Claude Code and run `/mcp` to authorize Executor (Notion, Context7, Supabase, Vercel connections).
7. Authenticate NotebookLM once: `uvx --from notebooklm-mcp-cli nlm login`.
8. Open Zed and install the extensions listed in `zed/extensions.md` by hand.

### Components

The installer opens a picker over these five: `↑↓` (or `j`/`k`) to move, space to toggle,
`a` for all/none, Enter to confirm, Esc to bail out. Everything starts checked. Without an
interactive console — piped input, CI — it falls back to a numbered list you answer
comma-separated. `-All` takes everything and `-Components wezterm,zed` skips the prompt
altogether, which is what you want when re-running it.

| Component | Windows | macOS / Linux |
| --- | --- | --- |
| `wezterm` | `~/.wezterm.lua` | same |
| `oh-my-posh` | `~/.config/oh-my-posh/material.omp.json` | same (`$XDG_CONFIG_HOME` if set) |
| `powershell` | `~/Documents/PowerShell/…` | `~/.config/powershell/…` |
| `zed` | `%APPDATA%\Zed\settings.json` | `~/.config/zed/settings.json` |
| `claude` | `~/.claude/…` | same |

The `powershell` target is resolved from `$PROFILE`, so it follows a Documents folder
redirected to OneDrive instead of guessing `~/Documents`.

Picking `claude` is what registers the three MCP servers, installs the `skill-creator`
plugin and runs the baseline cleanup; the other components only create symlinks.
