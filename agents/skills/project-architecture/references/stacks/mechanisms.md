# Mechanisms

Every reference in `core/` states a concept: layers that only reach downward, one path to the data, contracts at every edge, structure that tells you where a file goes. A concept holds in any language. What changes is the **mechanism**, the thing that makes a violation fail instead of merely being discouraged.

This skill keeps no configuration to copy. Tools release faster than a stored config can follow, so each project's guardrails are **researched and built for that project** at bootstrap, at the versions current that day, and recorded in its own `AGENTS.md`. This file holds what research does not return: the jobs, the order of strength, where to start looking, and the traps that only showed up when a config was run.

## What every stack must provide

A project is only as architectural as the checks that fail its build. For each concept, find the strongest mechanism the stack offers, in this order:

1. **The compiler or the module system.** A Gradle module, a Swift package target, a Go `internal/` directory: the illegal import does not compile. Nothing to configure, nothing to forget.
2. **A checker of the import graph, in CI.** import-linter, oxlint's import restrictions: the illegal import compiles and the pipeline goes red.
3. **An architecture test.** Konsist, Harmonize, ArchUnit-style suites: the rule is a unit test over the code's structure, for what the import graph cannot express (naming, annotations, where a class of thing lives).
4. **Prose in `AGENTS.md`.** Only for what needs judgement. A rule that could have been one of the three above and is prose instead is a rule an agent will skip.

The six jobs, and what each one answers:

| Job | Answers | Concept it enforces |
|---|---|---|
| Boundaries | May this module import that one? | The dependency rule (`architecture.md`), the DAL as the only path (`data-layer.md`) |
| Structure | Where may a file live, how is it named, how many may sit loose in a folder? | Modules in every layer (`architecture.md`) |
| Lint and format | Does the code avoid the known bug classes, and read one way? | Evidence over assertion, one naming format |
| Types | Does the code prove what it claims? | Contracts at every edge (`api-design.md`) |
| Tests | Does the behaviour hold against real dependencies? | Testing by risk (`testing.md`) |
| Gates | Does any of the above run without someone remembering? | CI with a time cap per job, a merge queue, hooks before push |

## By ecosystem

| Job | TypeScript (web, Expo) | Python (FastAPI, LangGraph, CLIs) | Kotlin (Android, server) | Swift (iOS, macOS) | Go |
|---|---|---|---|---|---|
| Boundaries | oxlint import restrictions | import-linter contracts | One Gradle module per layer; the module graph is the rule | One SPM target per layer; dependencies declared per target | `internal/` packages; one package per layer |
| Architecture tests | anti-slop and house rules in oxlint | import-linter `forbidden` and `independence` contracts | Konsist | Harmonize | A test that walks `go list` output |
| Structure | ls-lint | ls-lint | ls-lint | ls-lint | ls-lint |
| Lint and format | oxlint, oxfmt | ruff | detekt, ktlint | SwiftLint, swift-format | `go vet`, staticcheck, gofmt |
| Types | tsc | pyright | the compiler | the compiler | the compiler |

The table is a starting point for the research, not its answer: a tool named here may have been superseded, and the research step below is what decides.

> **VERIFY:** every tool named in the table before adopting it: that it is maintained, its current major version, and that it runs in this project's CI. As of November 2026 Konsist was in beta (1.0.0-beta.1) and Harmonize shipped a 2.0 beta beside 1.x.

## Building the guardrails for a project

Run this at bootstrap, phase 5, for any stack. **Done** when every job has a mechanism that was seen failing on a fixture, or a line in `AGENTS.md` saying the stack has none and what replaces it.

1. **Research the current tools, one job at a time.** Per the `research` skill: Context7 for how a tool is configured in its current version, Firecrawl's developer search for whether it actually works (open issues, regressions, what the docs leave out). Prefer, in order, the module system's own boundary, then a maintained checker that exits non-zero in CI. Record the version you chose and why.
2. **Write the config for this project's layers**, with its real package and folder names, never a generic profile renamed later.
3. **Write a fixture that must fail** for every rule: one illegal import per boundary, one crowded folder per structure cap, each line tagged with what must be reported, plus lines tagged clean that must not be. Keep them in the repo with a small check that runs the tool on them and compares.
4. **Run it until it bites, and run it more than once.** A rule nobody saw fail may match nothing; a result that changes between identical runs is a bug in the config.
5. **Wire the gates**: each check in CI, each job with a time cap, the fast ones in a pre-push hook.
6. **Write it into `AGENTS.md`**: the tools, their versions, the command that proves the rules bite. The next session reads that, not this file.

The dotfiles repo keeps one worked example of the result for TypeScript, in `lint/` (explained in `lint-guardrails.md`). Read it to see the shape (config, fixtures, the check that compares them); do not copy it as the configuration of a new project.

## Known traps

Found by running configs against fixtures, and absent from the docs at the time. Check each one still holds before relying on it:

- **ls-lint picks at random between two wildcards** that match the same folder (`src/app/*` and `src/app/*/**`): 5 failures in 8 identical runs on 2.3.2. A literal path (`lib`) always wins over a wildcard, so write each layer root literally.
- **ls-lint's `.*` stops counting an extension that has its own rule.** `.ts: kebab-case` beside `.*: exists:0-8` takes `.ts` files out of the count. Put the naming rule and the cap on the same line (`.*: kebab-case | exists:0-8`). Braces in an extension (`.{ts,tsx}`) do not fail; they match nothing.
- **ls-lint counts multi-dot extensions apart**: `.test.ts` and `.dal.ts` are not `.ts`, so tests do not spend a folder's cap.
- **import-linter follows indirect imports by default.** A `forbidden` contract from the transport layer to capabilities also rejects transport → data → capabilities, the legal path. Set `allow_indirect_imports = true` on that contract (measured on 2.16).
- **A boundary checker that resolves nothing reports nothing.** Renamed packages, a wrong root, a glob that no longer matches: all exit zero. Only the fixture distinguishes that from a clean codebase.

## Common mistakes

| Mistake | Consequence |
|---|---|
| Copying the TypeScript folder tree into another language | The tree arrives without its enforcement, so it is decoration from the first commit |
| An architecture test where the module system would have done it | A rule someone can skip or delete, where a compile error could not be |
| A checker configured and never seen failing | It reports zero errors, which is also what a checker matching nothing reports |
| Adopting a beta architecture-test library with no fixture | The first breaking release silently stops the checks |
| Copying another project's config instead of researching this one's | Its versions and its layer names arrive with it; the rules check a project that is not this one |
