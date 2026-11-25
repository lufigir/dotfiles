---
name: pruning-agent-memory
description: >
  Prune what agents read about a project: AGENTS.md / CLAUDE.md, the auto memory
  (MEMORY.md and its files) and design reasoning that belongs in ADRs. Use after
  merging a branch, when memory piles up session logs, or when asked to clean up
  agent docs. Spanish triggers: "limpia la memoria", "ordena la memoria",
  "limpieza de AGENTS.md", "poda la documentación", "pon orden en el proyecto".
---

# Pruning agent memory

What an agent loads about a project settles into **sediment**: session logs, decisions
already superseded, "before we did X", facts the code has since contradicted. Each stale
line is a distractor the agent may follow. This skill cores through it: every line ends up
as a live rule in one place, a design reason in an ADR, a real pending item, or deleted.

Read [`writing-for-agents`](../writing-for-agents/SKILL.md) first; its pruning rules
(single source of truth, cache, relevance, no-ops) are the criteria used here.

In Claude Code, Auto Dream (the `/memory` toggle) already merges duplicates and prunes `MEMORY.md` in the
background, but only by structure. This skill adds what it can't do: check each claim
against the code, move reasoning out to ADRs, and cover `AGENTS.md`.

## Steps

1. **Inventory.** Read in full, and note each file's line count:
   - the global instructions (`~/.claude/CLAUDE.md` for Claude, `~/.gemini/config/AGENTS.md` for agy; both generated from the dotfiles' `agents/AGENTS.md`, so prune that source);
   - the repo's `AGENTS.md`, `CLAUDE.md` and `.claude/rules/`, whichever exist;
   - the project memory (Claude Code: `~/.claude/projects/<slug>/memory/MEMORY.md`; skip it if your harness keeps none) and every file in that
     folder, linked or not;
   - `docs/adr/` and the rest of `docs/`;
   - `git log --oneline main..HEAD` and the last ~30 commits of `main`.
   If the user ran Claude Code's `/doctor prompt-audit`, take its findings as input; it checks paths and
   commands but not code names, and skips the auto memory.
   *Done:* every file listed with its line count, none skimmed.
2. **Verify against the code.** For each path, function, constant, column, env var, script,
   command and number that a document states, look it up (`rg`, the file, `package.json`,
   the schema). The code wins: a claim it contradicts is rewritten or deleted. A pending item
   the log shows as done is deleted.
   - A claim about state outside the repo (production migrations, a deploy, an account,
     settings) is checked read-only in that service, through Executor (`mcp-integrations`).
   - Every file in `docs/` needs a document that points to it; one with no pointer gets one
     or goes to the delete bucket in step 3.
   *Done:* every named thing and every `docs/` file checked, with the contradictions and
   orphans listed.
3. **Classify every block** into one bucket:

   | Bucket | Where it goes |
   |---|---|
   | Live rule or how the app works today | Stays, in present tense, in the one document that owns it |
   | Design reason for a decision already taken (why, measurements, rejected options) | An ADR in `docs/adr/`, with a pointer from `AGENTS.md` |
   | History: dates of redesigns, deploys, session logs, "HECHO", retired features, model or prompt comparisons | Deleted; git holds it |
   | Real pending work on the product | `AGENTS.md` "Pendiente" |
   | The user's own side of the job, or what blocks a branch | A `project` memory (or life-os, per the boundary in the global instructions) |
   | The user's preference or a rejected proposal | A `feedback` memory |
   | Local environment, accounts, data outside the repo | A `reference` memory |
   | Duplicate of a source already loaded (global instructions, `AGENTS.md`, config) or a one-command lookup | Deleted |

   A number stays only if an agent needs it to work, and then it names its constant in the
   code. A fact that can go stale is written with its source and the date it was verified.
   *Done:* no block left unclassified.
4. **Propose.** Before writing anything, ask with the question selector: which memories are
   deleted, condensed or rewritten (name each file), and which ADRs to create. Recommend; the
   user decides.
   *Done:* every deletion and every new ADR approved.
5. **Apply.**
   - `AGENTS.md`: rewrite in present tense; keep the sections the user asked to keep.
   - Memory: one fact per file with the frontmatter the memory system expects, links with
     `[[name]]`, one line per file in `MEMORY.md`; delete the files approved for deletion.
   - ADRs: `docs/adr/NNNN-<slug>.md` (status, date, context, decision, consequences), written
     from the code and passed through `humanize`.
   - Format the edited files with the repo's formatter, only those files.
   *Done:* every approved change applied and nothing else touched (code stays as it is).
6. **Commit and report.** One `docs:` commit for the repo files, after asking; never push.
   Report: line counts before and after, sections changed, memories deleted or condensed,
   and what stayed pending.

## Triggers worth suggesting

After a branch merges (its session logs go stale at once), after a model change, and once a
month on an active project.
