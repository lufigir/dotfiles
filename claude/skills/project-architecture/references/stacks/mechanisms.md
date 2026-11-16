# Mechanisms

Every reference in `core/` states a concept: layers that only reach downward, one path to the data, contracts at every edge, structure that tells you where a file goes. A concept holds in any language. What changes is the **mechanism**, the thing that makes a violation fail instead of merely being discouraged. This file maps concept to mechanism for each ecosystem, and says how to find the mechanism for a stack it does not list.

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
| Preset | `lint/` (`lint-guardrails.md`) | `lint-python/` (`python.md`) | none yet | none yet | none yet |

A stack with a preset has a stack file that explains it. A stack without one uses this table, and the first project in that stack is where its preset is born.

> **VERIFY:** every tool named in the table before adopting it: that it is maintained, its current major version, and that it runs in this project's CI. Konsist is in beta at 1.0.0-beta.1 and Harmonize ships a 2.0 beta beside 1.x as of November 2026; ls-lint 2.3.2 and import-linter 2.16 were measured against fixtures for the presets.

## A stack this file does not list

Work through the six jobs in order. **Done** when each one has a mechanism in the repo, or a line in `AGENTS.md` saying the stack has none and what replaces it:

1. **Find the module system's boundary.** Does the language let a module refuse to be imported (packages, targets, visibility modifiers, workspaces)? If the compiler can hold the layers, use it and stop looking for a linter for this job.
2. **Find an import-graph checker** for what the compiler cannot hold. Search the ecosystem for "architecture test" and "import linter"; prefer one that runs in CI with a non-zero exit.
3. **Use ls-lint for structure.** It reads names and folders, not code, so it works in any language.
4. **Take the ecosystem's standard linter, formatter and type checker**, all at error level.
5. **Write a fixture that must fail** for each boundary: one illegal import per contract, kept in the repo, with a check that the build goes red on it. A boundary nobody saw fail is a boundary that may not exist.
6. **Wire the gates**: the checks in CI, each job with a time cap, and a pre-push hook for the fast ones.

## Common mistakes

| Mistake | Consequence |
|---|---|
| Copying the TypeScript folder tree into another language | The tree arrives without its enforcement, so it is decoration from the first commit |
| An architecture test where the module system would have done it | A rule someone can skip or delete, where a compile error could not be |
| A checker configured and never seen failing | It reports zero errors, which is also what a checker matching nothing reports |
| Adopting a beta architecture-test library with no fixture | The first breaking release silently stops the checks |
