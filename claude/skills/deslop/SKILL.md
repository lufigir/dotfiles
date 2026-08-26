---
name: deslop
description: Taste-level review of a branch's diff for the patterns that mark AI-written code, with a verdict and a ledger of what to strip.
disable-model-invocation: true
---

# Deslop

Writing code got cheap. Reading it did not.

That is the whole premise. An agent produces code that compiles, passes the linter, passes the type checker, and still costs the next reader three times what it should — because it narrates itself in comments, names things `data` and `result`, wraps one function in a class, catches exceptions it cannot handle, and mocks everything its tests were supposed to exercise. None of that is a bug. All of it is debt, and none of it has a syntactic signature a linter could match.

**This is the half `lint-guardrails.md` explicitly cannot cover.** The linter owns rules with a shape; this owns the rules with a smell. Run them both and neither has to pretend to do the other's job.

Slop fails at human utility, not at correctness. Do not fix behaviour here.

## Scope

Default to the branch against main:

```bash
git diff main...HEAD --stat
git diff main...HEAD
```

`...` and not `..`: you want what this branch added, not what main did meanwhile.

If the user named files, review those. If they asked for the whole repo, take the twenty most recently modified source files rather than everything — slop concentrates in what was written last, and a full-repo verdict nobody can act on is worse than a partial one somebody will.

Read the surrounding files too, not only the diff. Half these rules are "inconsistent with the rest of the file", and a hunk in isolation cannot tell you that.

## The rules

Six categories, twenty-four rules. Severity is how much a hit costs the reader, not how confident you are that it is slop.

### Comments (critical)

The category with the highest hit rate, because narration is what a model does when it is unsure.

| Rule | What it looks like |
|---|---|
| `comments-narration` | The statement below, restated in prose. `// increment the counter` above `counter++` |
| `comments-empty-docblocks` | `/** Gets the user. */` over `function getUser(): User`. The signature already said it |
| `comments-placeholder` | `// TODO: implement`, `// your code here`, `// Add error handling` left behind |
| `comments-closing-brace-labels` | `} // end if`, `} // end of loop` |

A good comment says **why**, or names an invariant, or warns about something non-obvious. `// SAFETY:` on a type assertion is a good comment; so is a line explaining why an exception exists. Everything that restates the code is noise that will go stale.

### Naming (critical)

| Rule | What it looks like |
|---|---|
| `naming-generic-placeholders` | `data`, `result`, `temp`, `value`, `item`, `handleClick2` |
| `naming-over-descriptive` | `theUserWhoIsCurrentlyLoggedIn`, `arrayOfFilteredActiveSubscriptions` |
| `naming-suffix-abuse` | `*Helper`, `*Manager`, `*Util`, `*Wrapper`, `*Service` on things that are none of those |
| `naming-type-in-name` | `userObject`, `resultArray`, `isActiveBoolean`. TypeScript already knows |

`data` is defensible in exactly one place: a generic boundary that genuinely does not know what it holds. Everywhere else it means the author did not decide what the thing was.

### Over-engineering (high)

| Rule | What it looks like |
|---|---|
| `over-eng-premature-interface` | An interface with one implementation and no second one on the horizon |
| `over-eng-single-method-class` | A class whose only job is to hold one function |
| `over-eng-useless-wrapper` | A function called once that only forwards its arguments |
| `over-eng-dependency-creep` | A new package for something the existing dependencies already do |

This category is the one to check against the repo, not against taste. `codebase-design`'s deletion test settles most of it: if deleting this layer and inlining it makes the codebase smaller and no harder to read, the layer is slop. `over-eng-dependency-creep` needs the actual `package.json` open, since "the project already has this" is a fact, not an opinion.

### Defensive overdose (high)

| Rule | What it looks like |
|---|---|
| `defensive-generic-catch` | `catch (e) { console.error(e) }` around code that has no recovery path |
| `defensive-impossible-null` | A null check on a value the type system already guarantees |
| `defensive-missing-real` | Guards in the safe places and none where it matters: no timeout on a fetch, no rate limit on a public endpoint, no idempotency on a job |

The third one is why this category is worth a pass of its own. Defensive slop is not merely useless; it *relocates* caution away from where it was needed, and the result reads as careful code.

A `try/catch` earns its place when the catch does something a caller could not: retry, fall back, translate an error into a domain result. Swallowing and logging is not one of those.

### Test slop (high)

| Rule | What it looks like |
|---|---|
| `test-mock-everything` | Every dependency mocked, so the test exercises the mocks |
| `test-doesnt-throw` | The assertion is that nothing was thrown |
| `test-mirror-implementation` | The test recomputes the expected value the same way the code does |
| `test-snapshot-abuse` | A snapshot standing in for an assertion about behaviour |

Keep this category whole, and weight it. A suite full of these is worse than no suite: it is red when you refactor and green when you break the product, so it trains everyone to distrust it. The `tdd` skill has the long version, including why a real seam beats a mock.

### Style fingerprints (medium)

| Rule | What it looks like |
|---|---|
| `style-as-any-escape` | `as any`, `@ts-ignore`, `@ts-expect-error` scattered without a stated reason |
| `style-trivial-boilerplate` | `if (x) return true; else return false;` |
| `style-debug-artifacts` | `console.log`, `debugger`, a commented-out block |
| `style-hyper-consistent` | Machine-perfect uniformity where the rest of the repo drifts |
| `style-no-hack-scars` | Not a single `// HACK:` or `// XXX:` anywhere in a large change |

The last two are signals, not defects. Report them as context for the verdict; never ask anyone to "fix" them. A file where every function is exactly the same shape, in a repo where nothing else is, tells you where to look harder. It does not tell you anything is wrong.

Note that `style-as-any-escape` overlaps `anti-slop/require-safety-comment-for-type-assertion` in the lint preset. If the project runs that config, the escapes are already errors and this rule has nothing to add — say so and move on rather than reporting it twice.

## Verdict

Count flagged lines against lines changed.

| Verdict | Flagged | What it means |
|---|---|---|
| **CLEAN** | under 5% | Ship it |
| **SUSPICIOUS** | 5–15% | One more read before merge |
| **INFLATED** | 15–30% | Strip the slop first; consider splitting the commit |
| **CRITICAL** | over 30% | Rewrite before merge |

The bands are a communication device, not a gate. A single `test-mock-everything` in a suite of four tests matters more than twenty narrated comments, and the verdict should say so.

## Procedure

1. **Get the diff and read around it.** `git diff main...HEAD`, then open the files the hunks live in. Read `AGENTS.md` if there is one: it defines what "consistent with this repo" means, which is the standard half these rules are measured against.
2. **Check what the linter already covers.** If `oxlint.config.ts` is present, the evidence rules are already errors. Do not re-report what a failing build would have caught.
3. **Walk the six categories.** For each rule, one of: absent, or a list of hits with file, line, and what to do.
4. **Build the ledger.** One table: file, verdict, the top findings, the suggested action.
5. **Apply the fixes** if asked. Minimal, focused edits. Behaviour stays identical unless you are fixing a clear bug, and if you find one, say so separately instead of folding it into a cleanup.
6. **Report in one to three sentences.** The ledger is the detail; the summary is what gets read.

## Guardrails

**Consistency with the repo beats consistency with these rules.** If a codebase genuinely documents every public function, its docblocks are convention, not slop. These rules describe a default, and the repo overrides the default.

**Do not launder the code to pass.** Removing a comment that was the only explanation of a non-obvious decision makes the file worse. Deleting a defensive check that was load-bearing makes it break. When a finding is arguable, report it and leave it.

**Do not expand scope.** Adjacent code that is old and ugly is not this branch's problem. Mention it in one line; do not touch it.

**One pass, not a rewrite.** `thermo-nuclear`-style restructuring is a different job and belongs to `/improve-codebase-architecture`. This skill removes what should not be there. It does not redesign what is.
