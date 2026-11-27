# Models per role

Decided 2026-11-27. Pick the agent and model for a worker from this table.

| Role | Agent | Model |
|---|---|---|
| Bot Home Chat (Nix, Gea) | claude | opus (Claude Opus 5.5), medium effort |
| Scheduled reviews (Daily/Weekly) | claude | sonnet (Executor OAuth is stable there) |
| Code / writing / search / mechanical worker (default) | antigravity | gemini-4-neon-medium; Claude subagents: haiku |
| Large multi-file task | antigravity | Orchestrator (Neon) planner + Hydrogen executor, then review by risk |
| Verify / PR review (read-only, never pushes) | claude | per [Review by risk](#review-by-risk) |
| Hard bug / architecture | antigravity | gemini-4-carbon-high |
| Trivial search | antigravity | gemini-4-hydrogen-low |
| Claude Pro exhausted | antigravity | claude-sonnet-5-5 (uses Google's separate "Claude and GPT models" meter) |

## Load

- Neon Medium is the workhorse of the Antigravity subscription: send volume there. Use Hydrogen Low only for trivial search, Carbon High only for hard bugs and architecture.
- Spend Claude Pro only on the bots' Home Chat (opus), scheduled reviews (sonnet) and the reviews below.
- When Claude Pro is exhausted, reviews go to antigravity claude-sonnet-5-5.

## Fallback

- Workers always start in antigravity, with the model from the table (Neon Medium by default). Check `agy models` if a model name is in doubt; models leaving Antigravity (see [Rules](#rules)) are never picked.
- If agy refuses for quota, the same worker role moves to the Claude account: claude sonnet for writing/code workers, claude haiku for trivial search. Note it on the item so the next worker returns to agy once the quota resets.
- If Claude Pro is also exhausted, use antigravity claude-sonnet-5-5 (separate meter) for reviews and urgent work only.

## Review by risk

If a change fits several rows, use the highest risk.

| Risk | Change | Review |
|---|---|---|
| Low | Docs, text, config, or under ~50 lines with CI green | No reviewer worker: the bot reads the diff itself and merges |
| Normal | Other code | One read-only reviewer, claude sonnet, one round |
| High | Writes to production data, migrations, money, auth, or over ~300 lines | Full review: claude sonnet; opus for large PRs |

For normal changes:

- The reviewer reads only `gh pr diff` and the files it touches.
- It does not re-run what CI already ran; it runs something only to reproduce a specific failure.
- Requested changes go back to the same author worker (`orca orchestration send`), and the re-review looks only at the fix diff.

## Rules

- One worker per task; whether its change gets a separate read-only reviewer follows [Review by risk](#review-by-risk). Gemini writes, Claude verifies; a worker never reviews its own work.
- Never verify inside agy Orchestrator mode: it drops verifier subagents to Hydrogen (reported for agy 1.5.13, https://discuss.ai.google.dev/t/203336).
- Gemini 4 Argon, Gemini 3.8 Flash, GPT-OSS-120b and Claude 4.6 leave Antigravity on 2026-11-30. Don't use them.
