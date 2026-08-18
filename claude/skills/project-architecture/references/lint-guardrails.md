# Lint guardrails

Every other reference in this folder describes a rule someone has to remember. This one is about the rules a machine remembers for you.

The dependency rule in `architecture.md` is the clearest case. "The UI may not import a vendor" is true, agreed on, written in `AGENTS.md` — and entirely unenforced until something fails the build when it happens. Until then it is a preference, and preferences lose to deadlines. An agent that cannot find the DAL function it needs will reach one layer deeper, the import will work, the build will pass, and the boundary is gone. Nobody decided that. It just happened, in a file nobody reviewed closely.

So the linter is not a style tool here. It is the only part of the architecture that is **executable**. Everything else is prose.

## Three families, three different jobs

Keep them separate in your head, because they fail differently and they are configured differently.

| Family | Answers | Failure it prevents |
|---|---|---|
| **Boundaries** | May this file import that file? | Layer erosion: the page that calls the ORM, the component that imports Stripe |
| **Evidence** | Does this code prove what it claims? | Types that look safe and are not: `as` chains, `unknown` in signatures, dictionaries of `any` |
| **Framework correctness** | Am I using the framework as it works? | The rules the framework's own plugin already ships, left at "warn" and ignored |

A project with only the third family — which is what the framework CLI leaves you — has a linter that formats and nothing that defends the architecture.

## Oxlint as the base

Use Oxlint. Two reasons that matter for this skill specifically: it is fast enough to run on every save rather than only in CI, which is the difference between catching a boundary violation as it is written and catching it after twenty files copied the mistake; and the plugin ecosystem this reference depends on targets it.

One config file at the root, `oxlint.config.ts`, with four things in it:

```ts
import { defineConfig } from "oxlint"

export default defineConfig({
  plugins: ["import", "typescript"],
  categories: { correctness: "error" },
  rules: { "import/no-cycle": "error" },
  overrides: [/* the boundary rules, below */],
})
```

- **`categories`** turn on whole groups at once. Correctness is the floor.
- **`plugins`** enable rule namespaces. `import` gives you cycle detection; `typescript` gives you the type-aware rules.
- **`overrides`** apply rules to a file glob, which is the mechanism the whole boundary section depends on.

### Type-aware rules earn their cost

The `typescript` plugin runs rules that need the type checker, not just the syntax tree. Slower, and worth it for a few that catch bugs nothing else does. `typescript/no-floating-promises` is the one to enable first in this stack: a server action that calls the DAL without awaiting it returns a success the write never made, and `async-work.md` explains why on serverless that promise is discarded entirely rather than merely late. That failure is invisible in review and obvious to the type checker.

> **VERIFY:** the current Oxlint major, whether `defineConfig`, `categories` and `overrides` are still the config shape, how type-aware rules are enabled today and whether they still need a separate binary, and what the framework's own lint plugin is called. Also check whether the framework CLI still scaffolds ESLint: if the project already has one, the supported path is running both, with the plugin that disables the ESLint rules Oxlint already covers, rather than a big-bang migration.

### Everything set to error

A rule at `"warn"` is a rule that will be violated forever. Warnings accumulate, the output becomes noise, and then nobody reads any of it — including the agent, which sees a wall of pre-existing warnings and reasonably concludes its own new one is normal.

Set architectural rules to `"error"`. If a rule is too noisy to be an error, it is either the wrong rule or the code genuinely needs fixing; those are the only two cases, and "leave it as a warning" resolves neither.

## Boundary rules

This is the family the architecture actually depends on, and it is the one no package will hand you configured, because only your repo knows its layer names.

Express the dependency rule from `architecture.md` as **allowed imports per directory**, denying everything else:

| Layer | May import | Denied |
|---|---|---|
| UI | transport, shared, design system | domain, capabilities, vendors, database |
| Transport | domain, shared, database | vendors, UI |
| Domain | capabilities, shared, database | transport, UI, vendors |
| Capabilities | vendors, shared | transport, UI, domain |
| Vendors | shared | everything else |

Two details decide whether this works in practice:

**Deny by default, not by list.** A rule that forbids the four illegal imports you thought of is silent about the fifth directory added next month. A rule that permits only what the table allows fails loudly the moment a new layer appears, which is exactly when you want to be asked.

**The database client is the interesting exception.** `shared` and the database client flow upward to everyone, per the dependency rule — but the whole point of `data-layer.md` is that only the DAL may *call* the ORM. So the boundary rule needs to keep the ORM import restricted to the DAL directory even though the client itself is a foundation. Get this one wrong and non-negotiable #2 is unenforced while looking enforced.

In the monorepo profile the package graph does part of this for you: a package cannot import what it does not depend on. It does not do all of it — nothing stops a package from adding the dependency — so keep the lint rules in both profiles and let the package boundaries be the second layer.

> **VERIFY:** the current rule and plugin for import restrictions by path in Oxlint, and its option shape for allow/deny lists. Also check whether the framework ships a rule for server-only imports reaching client components, which overlaps with the server-only marker in `security.md`.

## Evidence rules: anti-slop

The second family targets a specific failure mode, and it is worth naming precisely because it is the one agents produce most: **code that fabricates evidence**. Not wrong code — code that tells the compiler it has checked something it never checked.

```ts
const user = input as object as User   // two assertions, zero verification
function handle(input: unknown) {}     // the caller's contract is "anything"
type Metadata = Record<string, unknown> // a dictionary that promises nothing
```

Each of these compiles, passes review at a glance, and moves a runtime failure to somewhere far from its cause. They are what `security.md` and `api-design.md` are trying to prevent structurally, appearing as a local shortcut instead.

The `anti-slop` plugin is fifteen rules against exactly this shape. Copy it into the repo — the author's own instruction, and the right call independently: at the time of writing it has no releases and a handful of commits, so pinning a version means pinning to something that will move under you. Vendored, the rules are yours to read and to disagree with.

```ts
// oxlint.config.ts
jsPlugins: [{ name: "anti-slop", specifier: "./tools/oxlint/anti-slop/index.ts" }],
rules: {
  "anti-slop/no-chained-type-assertions": "error",
  "anti-slop/no-unknown-parameters": "error",
  "anti-slop/no-unknown-returns": "error",
  "anti-slop/no-unsafe-dictionary-type": "error",
  "anti-slop/no-runtime-typeof": "error",
  "anti-slop/require-safety-comment-for-type-assertion": "error",
  // ...the rest of the generic set
}
```

The three worth understanding rather than just enabling:

**`no-runtime-typeof`** rejects ad hoc `typeof` narrowing and asks for parsing at the boundary instead. That is the same principle as "validate in and out" from `data-layer.md`: a schema at the edge means the inside of the function does not have to guess. If a project has no schema library, the rule takes `{ allowInTypeGuards: true }` so checks are at least confined to real type predicates.

**`require-safety-comment-for-type-assertion`** does not ban assertions. It requires each one to state the invariant that was checked, on a `// SAFETY:` line. Sometimes you genuinely know more than the compiler; the rule only asks you to write down why, which is what makes the next reader able to tell a justified assertion from a hopeful one.

**`no-known-value-widening`** rejects annotating a value with a type broader than what it demonstrably is — `const handlers: Record<string, Handler> = { start: startHandler }` throws away the fact that `start` exists. Use `satisfies` or let inference do its job.

Add the plugin directory and the agent tooling directories to `ignorePatterns`, so the linter does not lint itself.

> **VERIFY:** the current rule list and install path for the plugin, since it is new and actively changing, and whether the bundled agent skill is the recommended install route.

## What the linter cannot do

Worth stating plainly, because the temptation after configuring all this is to trust it further than it goes.

A linter checks the shape of code, not its meaning. It will never tell you that a query is missing its tenant filter, that a policy check runs after the data was already fetched, or that a job is not idempotent. Those are the failures in `multi-tenancy.md`, `data-layer.md` and `async-work.md`, and they are caught by tests and review.

The split is: **the linter owns the rules with a syntactic signature; the DAL, the policy layer and the type system own the rest.** A rule you cannot express syntactically is a rule that belongs in `AGENTS.md` and in a test, not in a regex someone will fight.

## Where this fits

- **Bootstrap**: the guardrails step. Install the config, the boundary rules and the vendored plugin *before* the vertical slice, so the slice is the first thing the rules are checked against. A boundary rule added after twenty files exist is a boundary rule you will weaken to make the build pass.
- **Convention**: when a rule you had to explain twice keeps coming back, it wants to become a lint rule rather than another paragraph in `AGENTS.md`. Explaining a convention repeatedly is the signal that prose is not the right medium for it.

Both modes: the rules are only real if CI runs them. Lint failures block the merge, at the same status as a failed build.

## The pieces

Four, and they are not equally solid — which matters, because one of them is alpha and the config will not tell you:

| Piece | Job | Maturity |
|---|---|---|
| `oxlint` with `categories: { correctness: "error" }` | The floor | Stable |
| The `import` plugin | Cycles, plus the boundary rules through `no-restricted-imports` in `overrides` | Stable |
| The `typescript` plugin | Type-aware rules; enable the floating-promise one first | Stable, slower — it needs the type checker |
| `anti-slop` through `jsPlugins` | The evidence rules | **Alpha, and outside semver** |

That last row is the reason the plugin gets vendored rather than depended on, and it is worth being explicit: custom JS plugins are a young part of the toolchain. The native Rust rules are not — do not let one alpha surface make you distrust the other three rows.

**If the project already has ESLint**, which is what the framework CLI still tends to leave, there is a supported middle state: run both, with the plugin that switches off the ESLint rules Oxlint already covers so the same problem is not reported twice. That is a better first move than a migration nobody scheduled. The formatter is a separate question from all of this — formatting is not architecture, and this reference has no opinion on it.

## Common mistakes

| Mistake | Consequence |
|---|---|
| The dependency rule documented but never linted | It is a preference, and it decays silently one import at a time |
| Boundary rules that list what is denied | Any directory added later is unconstrained by default |
| ORM import allowed anywhere the database client is allowed | The DAL boundary looks enforced and is not |
| Architectural rules left at `"warn"` | Warnings pile up, nobody reads them, new violations look normal |
| Linter runs only in CI | The violation is found after twenty files copied it |
| `anti-slop` installed as a pinned dependency | Coupled to a young package instead of owning the rules |
| Assertions allowed with no stated invariant | No way to tell a checked assertion from a hopeful one |
| Expecting lint to catch missing tenant filters | Semantic bugs need tests; the linter never sees them |
| Lint failures that do not block the merge | The rules are advisory, which is the same as absent |
