# Models per role

Decided 2026-11-24. Pick the agent and model for a worker from this table.

| Role | Agent | Model |
|---|---|---|
| Bot Home Chat (Nix, Gea) | claude | opus |
| Scheduled reviews (Daily/Weekly) | claude | sonnet (Executor OAuth is stable there) |
| Code worker | antigravity | gemini-4-neon-medium |
| Large multi-file task | antigravity | Orchestrator (Neon) planner + Hydrogen executor, always followed by a separate reviewer |
| Verify / PR review (read-only, never pushes) | claude | sonnet; opus for large PRs |
| Hard bug / architecture | antigravity | gemini-4-carbon-high |
| Search / mechanical | antigravity | gemini-4-hydrogen-low; Claude subagents: haiku |
| Claude Pro exhausted | antigravity | claude-sonnet-5-5 (uses Google's separate "Claude and GPT models" meter) |

## Rules

- One worker per task, and a separate read-only reviewer for every change it makes. Gemini writes, Claude verifies; a worker never reviews its own work.
- Never verify inside agy Orchestrator mode: it drops verifier subagents to Hydrogen (reported for agy 1.5.13, https://discuss.ai.google.dev/t/203336).
- Gemini 4 Argon, Gemini 3.8 Flash, GPT-OSS-120b and Claude 4.6 leave Antigravity on 2026-11-30. Don't use them.
