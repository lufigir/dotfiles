# dotfiles

Personal configuration files, symlinked from here to keep them in sync across machines.
`install.ps1` runs on Windows, macOS and Linux under PowerShell 7+, detects the OS and
links each config where that system expects it.

## Contents

- `wezterm/.wezterm.lua` — WezTerm terminal config (theme, keybindings, panes, tab bar)
- `oh-my-posh/material.omp.json` — Oh My Posh prompt theme (Material, tweaked)
- `powershell/Microsoft.PowerShell_profile.ps1` — PowerShell profile (Oh My Posh init + Linux-style aliases + the purple theme applied to `$PSStyle` and PSReadLine; `touch`/`which`/`grep` are defined on Windows only, since on macOS/Linux the real binaries are on PATH and beat these stand-ins. When [eza](https://github.com/eza-community/eza) is installed it takes over the listings: `ls` is a long list with icons, size, relative date, per-file git status and the branch of any subdirectory that is a repo; `ll`/`la` add dotfiles, `lt` is a 2-level tree and `lg` swaps the branch column for the full git status of each subrepo (seconds, not milliseconds). eza prints text rather than objects, so pipe from `gci` instead)
- `claude/settings.json` — global Claude Code settings (model, hooks, plugins, skillOverrides)
- `claude/CLAUDE.md` — global Claude Code instructions (commit rules, pointer to personal skills)
- `claude/skills/` — personal Claude Code skills (see the opt-in model below)
- `zed/settings.json` — Zed editor settings (theme, fonts, LSP, agent)
- `zed/extensions.md` — reference list of installed extensions (manual install, see note below)

### Personal skills

- `commit-and-push` — git add + version bump + commit + push
- `mcp-integrations` — Notion, Context7, Supabase, Vercel through Executor (Notion and Supabase have 2 accounts each: `felipegiraldo` and `centrodeprototipado`)
- `project-architecture` — two modes: bootstrap a new project with a layered architecture, and answer architecture questions mid-build against the repo's own `AGENTS.md`; 12 references (layers, routing, DAL, schema and migrations, multi-tenancy, API contracts, async work, uploads, security, performance, operations, design system) whose version-specific claims are always verified against the live docs
- `felipego-projects` — publish/update felipego.com portfolio projects in Notion; off by default

Check each skill's `SKILL.md` for the current, authoritative on/off state and
scope — the list above is descriptive, not the source of truth; `claude/settings.json`'s `skillOverrides` is.

### Vendored skills (Matt Pocock)

Vendored from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) at commit
`84fdeff`, replacing the `superpowers` plugin. Vendored rather than installed as a plugin
for two reasons: `Clean-ClaudeBaseline` deletes anything in `~/.claude/skills` that isn't a
symlink into this repo, and the plugin is read-only — the descriptions need editing (see below).

**Auto-invoked** (they fire on their own when the context matches):

- `grilling` — the relentless interview: asks the whole *frontier* of unblocked questions per round, numbered, each with a recommended answer, and dispatches sub-agents to look up facts instead of asking. This is what replaced `superpowers:brainstorming`.
- `tdd` — red→green loop, seams, and the test anti-patterns worth naming
- `codebase-design` — the deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality) and the deletion test
- `domain-modeling` — maintains `CONTEXT.md` (domain glossary) and ADRs in `docs/adr/`
- `diagnosing-bugs` — diagnosis loop for hard bugs, starting from a failing repro
- `resolving-merge-conflicts` — finishes an in-progress merge/rebase hunk by hunk
- `writing-for-agents` — how to write skills, `CLAUDE.md`, `CONTEXT.md`

**Slash-only** (`disable-model-invocation: true` upstream — deliberate: these are expensive
verbs you trigger, not criteria that fire on their own):

- `/grill-me` — one-line alias that runs a `grilling` session
- `/improve-codebase-architecture` — scans git history for hot spots, applies the deletion test, and emits a visual HTML report of deepening opportunities to the temp dir

**Local modifications** — only the `description` frontmatter, plus one line in `tdd`:

- Each description gained **Spanish trigger phrases**. Upstream only lists English ones, and `claude/settings.json` sets `"language": "Español"`, so a prompt like *"no funciona el login"* or *"vamos a armar el dashboard"* would never have matched.
- `grilling`'s description also carries the "MUST use before any creative work" framing that made `superpowers:brainstorming` fire reliably.
- `tdd`'s refactoring line points at Claude Code's built-in `/code-review` instead of Pocock's `code-review` skill, which isn't vendored (the built-in is stronger: multi-agent cloud review, `--fix`, inline PR comments) and would have collided on name.

**Deliberately not vendored:** `research` (would bypass the Executor rule in `CLAUDE.md`),
`code-review` (name collision, see above), `setup-matt-pocock-skills` (writes its own repo
context file; `domain-modeling` already maintains `CONTEXT.md`), the `to-spec`/`to-tickets`/`implement`
pipeline, and the human-facing set (`teach`, `triage`, `wizard`, `wayfinder`, `handoff`, `wait-what`, `prototype`).

**Updating:** there's no auto-update — re-copy from upstream and re-apply the description
edits above. `agents/openai.yaml` is dropped from each skill (it's Codex config).

#### Opt-in model (per-project enablement)

All skills live globally (symlinked, synced), but the global default is **lean**: only the universal ones stay ON. Situational/single-project skills are OFF by default via `skillOverrides` in `claude/settings.json` and get turned on **per project** in that repo's own `.claude/settings.json` (project config overrides the global one).

To enable one in a project, in its `.claude/settings.json`:

```json
{ "skillOverrides": { "felipego-projects": "on" } }
```

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
