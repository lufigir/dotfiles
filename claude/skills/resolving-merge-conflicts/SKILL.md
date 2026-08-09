---
name: resolving-merge-conflicts
description: >
  Use when you need to resolve an in-progress git merge/rebase conflict, or when a
  merge, rebase, cherry-pick or pull leaves conflict markers. Spanish triggers:
  "conflicto", "conflictos", "resuelve el merge", "arregla el rebase",
  "tengo conflictos", "no puedo hacer merge".
---

1. **See the current state** of the merge/rebase. Check git history, and the conflicting files.

2. **Find the primary sources** for each conflict. Understand deeply why each change was made, and what the original intent was. Read the commit messages, check the PRs, check original issues/tickets.

3. **Resolve each hunk.** Preserve both intents where possible. Where incompatible, pick the one matching the merge's stated goal and note the trade-off. When the goal doesn't settle it — both sides are live and losing either one costs something real — put that hunk to the user through the `AskUserQuestion` selector per the global `CLAUDE.md` rules, with the two sides and the combination as options and the cost of each in its `description`. One tab per genuinely undecidable hunk, batched into as few calls as the cap allows; the hunks the goal already settles never reach the selector. Do **not** invent new behaviour. Always resolve; never `--abort`.

4. Discover the project's **automated checks** and run them — typically typecheck, then tests, then format. Fix anything the merge broke.

5. **Finish the merge/rebase.** Stage everything and commit. If rebasing, continue the rebase process until all commits are rebased.
