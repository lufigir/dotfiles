# The lint preset

The executable part of the architecture. Everything else in
`claude/skills/project-architecture/references/` is prose somebody has to remember; this
is the part a machine remembers.

One vendor: **oxc**. `oxlint` for all four rule families, `oxfmt` for formatting. No
ESLint, no Prettier, and not a half-finished migration: oxlint today has
`no-restricted-imports`, `react/exhaustive-deps`, `react/rules-of-hooks`, the `nextjs`
plugin and type-aware rules, which were the four remaining reasons to keep
`eslint-config-next` alongside.

## Four families, four jobs

Keep them separate, because they fail differently and they are configured differently.

| Family | Answers | Failure it prevents |
|---|---|---|
| **Boundaries** | May this file import that file? | Layer erosion: the page that calls the ORM, the component that imports Stripe |
| **Evidence** | Does this code prove what it claims? | Types that look safe and are not: `as` chains, `unknown` in signatures, dictionaries of `any` |
| **Design system** | Does this UI use the tokens and variants that exist? | `bg-blue-500`, `p-[13px]`, a `<Button className="p-4">` that bypasses its own sizes |
| **Framework** | Am I using the framework as it works? | The rules the framework's own plugin ships, left at `warn` and ignored |

A project with only the last family, which is what the framework CLI leaves you, has a
linter that formats and nothing that defends the architecture.

## What is here

```
lint/
├── oxlint.config.ts            the config; the boundaries block is adapted per project
├── .oxfmtrc.json               formatting, with import and Tailwind class sorting
├── ci.yml                      the workflow that makes the rules bite
├── package.json                tool versions, and the test script
├── tools/oxlint/
│   └── anti-slop/              vendored from dmmulroy. See its VENDORED.md
└── rule-tests/
    ├── check.mjs               do the rules still bite?
    └── fixtures/               code that MUST fail. The fixture is the specification
```

This directory is both the preset and its own test bench. `jsPlugins` specifiers and
`overrides` globs resolve against the config file's directory, so the layout here is
exactly the one a consuming project ends up with.

## Installing into a project

The `project-architecture` skill does this in its guardrails phase and adapts the
boundary table to the repo's real layers. By hand it is five steps.

**1. Copy.**

```bash
cp -r <dotfiles>/lint/tools           <project>/tools
cp -r <dotfiles>/lint/rule-tests      <project>/tools/oxlint/rule-tests
cp    <dotfiles>/lint/oxlint.config.ts <project>/
cp    <dotfiles>/lint/.oxfmtrc.json    <project>/
cp    <dotfiles>/lint/ci.yml           <project>/.github/workflows/ci.yml
```

**2. Dependencies.** Look up current versions rather than trusting these:
`npm view oxlint version`. `oxlint` and `@oxlint/plugins` must be **the same version**.

```bash
npm i -D oxlint @oxlint/plugins oxlint-tsgolint oxfmt @shadcn/lint
```

**3. Two environment requirements that do not announce themselves.** The `.ts` config
does not load without `"type": "module"` in `package.json`, and `--type-aware` does not
start without `oxlint-tsgolint` installed. Both fail with a message that does not name
what is missing.

**4. Scripts.**

```json
"lint": "oxlint --type-aware",
"format": "oxfmt .",
"lint:rules": "node tools/oxlint/rule-tests/check.mjs"
```

**5. Adapt the boundaries, the only step that thinks.** The `overrides` block ships the
single-app profile from `architecture.md` (`app/` → `data/` → `lib/`). Rename the layers
to the repo's, and **adapt the fixtures at the same time**: if the data layer is not
called `data/`, then `fixtures/data/orders.policy.ts` is testing nothing, and
`check.mjs` will say so.

## Verifying that the rules bite

```bash
node tools/oxlint/rule-tests/check.mjs
```

A lint config is the only executable part of the architecture, and also the only part
that can stop working without turning anything red. A rule that disappears from oxlint,
a plugin that fails to load, a negation whose semantics change: the result is always
`oxlint` exiting zero and a boundary that no longer exists. Zero errors is exactly what
you expected to see.

`rule-tests/` inverts the test. The fixtures are code that **must** fail, and every line
tagged `CLEAN:` is code that **must not** report, with the reason written beside it. The
checker stages a real project in a temp directory, runs the actual config against the
fixtures, and compares.

Run it after bumping oxlint, after re-vendoring anti-slop, and after adapting the
boundary table. That last one matters most: it is what distinguishes a negation that
reopens a legal import from one that swallowed the whole rule.

## Decisions, and why

**Everything at `error`.** A rule at `warn` is a rule that will be violated forever.
Warnings accumulate, the output becomes noise, and then nobody reads any of it,
including the agent, which sees a wall of pre-existing warnings and reasonably concludes
its own is normal. If a rule is too noisy to be an error, it is either the wrong rule or
the code needs fixing; there is no third case, and `warn` resolves neither.

**Boundaries that deny by default.** A rule forbidding the four illegal imports you
thought of is silent about the fifth directory added next month. So each block closes a
whole group and reopens the few legal exceptions with `!`.

**Ten of anti-slop's fifteen rules.** The other five sit in the config, commented, with
the reasoning attached. They are strong design positions (banning `object` in inputs,
banning module mocking) worth arguing in real code before inheriting, not oversights.

**anti-slop vendored, not depended on.** The author's instruction and the right call
independently: no releases, outside semver. See `tools/oxlint/anti-slop/VENDORED.md`.

**`@shadcn/lint` depended on, not vendored.** The opposite call for the opposite
reason: it publishes versioned releases. It is 0.x, so `check.mjs` is what notices a
release that changes a rule. The fixture stages a `components.json`, a Tailwind v4
theme and a `cva` Button beside it, because the rules read all three; `tailwindcss`
is a dev dependency here only so `no-unknown-classes` can ask it which classes exist.

**No lockfile here.** Deliberate. `npm install` takes the latest within the range, and
`check.mjs` reports when a new oxlint drops a rule. A frozen lockfile would turn this
test bench into decoration.

## What the linter cannot do

Worth stating, because the temptation after configuring all this is to trust it further
than it goes.

A linter checks the shape of code, not its meaning. It will never tell you a query is
missing its tenant filter, that a policy check runs after the data was fetched, or that
a job is not idempotent. Those are the failures in `multi-tenancy.md`, `data-layer.md`
and `async-work.md`, caught by tests and review.

The split: **the linter owns the rules with a syntactic signature; the DAL, the policy
layer and the type system own the rest.** A rule you cannot express syntactically
belongs in `AGENTS.md` and in a test, not in a regex somebody will fight.

It also cannot tell you the code reads like a tutorial. That is the `deslop` skill's
job, on the diff, before the merge.

## Updating

```bash
cd lint && npm install && node rule-tests/check.mjs
```

If the checker fails after bumping oxlint, do not touch the fixtures. Find out which
rule disappeared.
