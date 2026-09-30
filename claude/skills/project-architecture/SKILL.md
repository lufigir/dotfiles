---
name: project-architecture
description: >
  Senior-level architecture for a product. **Bootstrap** starts a project from zero (discovery, ERD,
  layered folders, data access layer, lint guardrails, design tokens); **Convention** keeps those
  rules holding mid-build. Use when starting or scaffolding a project, framing its problem and
  scope, and whenever work touches: where a file goes or what a layer may import; schema design and
  migrations; multi-tenancy; data access, including managed backends where the browser queries the
  database; API contracts, background jobs, uploads; security, performance, observability; URL and
  route design; list screens (filters, sort, search, pagination) and forms (validation, pending and
  optimistic state); lint rules that enforce boundaries; accessibility of tables, forms and custom
  controls; product analytics, feature flags and experiments; personal data, consent and deletion;
  choosing the architecture style or the database. Spanish triggers: "proyecto nuevo",
  "planteamiento del problema", "alcance", "dónde va este archivo", "en qué capa", "cómo modelo esta
  tabla", "migración", "tabla con filtros", "paginación", "formulario", "server action", "reglas de
  lint", "estructura de urls", "accesibilidad", "supabase", "rls", "analítica", "métricas de uso",
  "feature flag", "a/b test", "datos personales", "habeas data", "microservicios", "qué base de
  datos".
---

# Project architecture

The first hour of a project decides whether it scales. Folders are the easy part; the hard part is **ownership**: who is allowed to know about what. A codebase where the UI can reach Stripe, or where `page.tsx` calls the ORM directly, does not get better with time. It gets bigger.

This matters more with coding agents than without them. An agent reads the conventions already in the repo and builds on top of them. Bad structure does not stay bad at constant size; it compounds. Set the boundaries first and the agent's shortcuts become impossible rather than merely discouraged.

Which is why this skill has a second job. Conventions decided in week one are forgotten by week six, by the agent whose context has rolled over and by the human who moved on. **Bootstrap** builds the architecture. **Convention** keeps it.

## Pick the mode

| Situation | Mode |
|---|---|
| Nothing exists yet, or only bare framework CLI output | [Bootstrap](#bootstrap) |
| A project already exists and work is happening inside it | [Convention](#convention) |

## Everything version-specific is a moving target

`references/` holds distilled architecture knowledge: layering, the dependency rule, DAL/DTO/policy, ERD design and migrations, tenant isolation, API contracts, list views, mutations, accessibility, async work, uploads, security, performance, operations, product analytics, privacy, lint guardrails and design tokens. Those **principles** hold across versions.

**Every concrete API, file name, flag, and command in them is a moving target.** The reference files mark those with `VERIFY:` blocks stating exactly what to look up. Resolve them against the live docs before writing code, in **both** modes, not just at bootstrap. Context7 goes through Executor; see the `mcp-integrations` skill for the tool path and the two-step flow. Read the version attached to whatever comes back: it is the difference between "the docs say X" and "the docs for the version installed here say X".

Never write code from what a reference file, or your training data, *implies* the current API is. Live example: Next.js renamed `middleware` to `proxy`, and now ships its own docs inside `node_modules/next/docs`. Anything that hardcoded those is already wrong.

When the live docs contradict a reference file, **the docs win** and you say so out loud. If a reference file's *principle* no longer has a mechanism in the current version, say that too rather than inventing one.

## The non-negotiables

The compressed form of the rules, for recall. Each one expands in the reference file named; that file is the authority.

Three are conditional and say so: 3, 10 and 16 hold only when their concern is in the project's scope (`problem-framing.md`). The rest hold in every project, because they are how the code is built rather than what it builds.

1. **The dependency rule.** UI → Transport → Domain → Capabilities → Vendors, each layer reaching only the one below it. Shared contracts and the database client flow upward to everyone. (`architecture.md`)
2. **The DAL is the only path to the database.** No ORM call in a page, a component, a route handler, or an action. (`data-layer.md`)
3. **In a multi-tenant product, the tenant is a required argument.** Never optional, never inherited, never taken from a client-controlled value. This covers jobs, caches and storage keys, not just queries. (`multi-tenancy.md`)
4. **Authorization before data, next to the data.** Upstream gates are an optimization, not the security model. (`data-layer.md`)
5. **Validate in and out.** Inputs because users lie; outputs because the database returns more than the client should see. (`data-layer.md`)
6. **Server-only is a build error, not a convention.** Sensitive modules import the server-only marker so a client import fails loudly. (`security.md`)
7. **Every entry point is public.** A server action compiles to a POST endpoint; arriving through your form is not a fact you get to assume. (`security.md`)
8. **Server Components by default.** `"use client"` lives on the leaves, only where there is interactivity. (`performance.md`)
9. **One contract, both directions.** The schema is the single source of truth for input, output, types and docs. (`api-design.md`)
10. **In a list view, the state lives in the URL.** Filters, sort, search and page are query params, parsed against a schema. State trapped in a component is a view nobody can share, bookmark or restore. (`list-views.md`)
11. **A boundary that is not linted is a preference.** The dependency rule is only real once an illegal import fails the build. (`lint-guardrails.md`)
12. **A URL that has been shared is a contract.** Do not encode a movable relationship in a path, and never let a rename silently kill existing links. (`url-design.md`)
13. **The right element before any ARIA.** Native elements carry role, focus and keyboard behavior; a div reimplementing them is a permanent debt. Focus and announcements are owned, not assumed. (`accessibility.md`)
14. **Semantic tokens, never literal colors.** `bg-primary`, not `bg-blue-500`. (`design-system.md`)
15. **One naming format.** kebab-case for source files, snake_case in the database. (`architecture.md`, `database.md`)
16. **When the product measures usage, events are a contract.** Declared once in a typed catalog, never named from a variable; business events captured on the server after the write commits; the analytics vendor behind a capability like any other. (`product-analytics.md`)

## Bootstrap

Create a todo per phase. Do not skip phase 3's checkpoint.

### 1. Discovery

Two steps, in order, both per `references/problem-framing.md`. Ask only what you cannot infer, and ask it through the `AskUserQuestion` selector per the global `CLAUDE.md` rules: stakes, appetite, tenancy and every scope status are enumerable, so they are tabs. Only the problem statement is genuinely open, so that one goes in prose.

**Frame the problem.** Before any feature list: who the user is and in what circumstance, where their current way breaks, the outcome that would mean it worked, the appetite, goals and non-goals, and the riskiest assumption. Also what is already decided (deployment target, database, auth provider, anything the user already pays for). The feature list is derived from the framing, and every noun in it is a candidate entity.

**Study the scope.** Give each concern in the reference's table a status (applies, later, no) with one line of reason tied to the framing and the stakes. Present it as one selector round, recommending the defaults the stakes imply. Only the concerns marked **applies** are built in this scaffold; **later** leaves a seam and nothing more. Two answers reshape everything after them, so settle them first: whether `multi-tenancy` applies (if it does, `references/multi-tenancy.md` governs the model before anything else does), and whether any access pattern outgrows a relational database (`references/database.md`; the default is no). The scope is what every later phase reads: phase 2 verifies only the stack those concerns use, the blueprint designs only them, and the audit skips the rest.

Then pick the **profile**, and say which one you picked and why:

| Profile | When | Shape |
|---|---|---|
| **Single app** (default) | Most projects. One deployable, one team, one product surface. | One app, layering enforced by folders and lint rules inside it. |
| **Monorepo** | Multiple deployables (web + docs + marketing), or capabilities that genuinely need to be swappable behind stable APIs (payments, storage, email across products). | Workspaces, one package per layer. |

Do not default to the monorepo. It is the right end state for a product with real scale, and premature weight for anything smaller. The layering principles are identical in both; only the enforcement mechanism differs (folders + lint vs. package boundaries).

### 2. Version verification

Resolve, at minimum:

- **The framework.** Current major, what the CLI creates today, which conventions were renamed or removed, which config flags the planned features need.
- **The ORM / database client.** Current schema syntax, id generation, migration commands.
- **The auth provider**, if any. Current session API and its server-side entry point.
- **The component library.** Current CLI command and init flow.
- **The transport layer**, if the project exposes an external API. Current setup for the typed-RPC library and its OpenAPI handler.

Then walk `references/` and resolve every `VERIFY:` block that applies to the chosen stack. Record the resolved versions: they go in the blueprint and in `AGENTS.md`.

### 3. Blueprint, then stop

Present, compactly:

1. **Framing and scope**: the problem statement, outcome, appetite, goals and non-goals, the scope table, and the feature list derived from them.
2. **Entities and ERD**: tables, fields, keys, relationship types. Per `references/database.md`. Present as a diagram or a clear list; this is the piece most worth getting right before any code exists.
3. **The route space**: the URLs the product will have, where the tenant sits in them, and what identifies a resource. Per `references/url-design.md`. It belongs in the blueprint rather than emerging from the folder tree, because URLs become a public contract the moment anyone shares one.
4. **Folder tree**: the actual tree you will create, per `references/architecture.md` and the chosen profile.
5. **Stack and exact versions**: resolved in phase 2, plus anything the live docs corrected.
6. **Measurement and data**, for the concerns in scope: the core events of the tracking plan if `product-analytics` applies; the personal fields, their purpose and the hosting region of every vendor that receives them if `privacy` applies. Per `references/product-analytics.md` and `references/privacy.md`.
7. **Decisions you cannot cheaply reverse**: database, tenancy model, auth provider, URL scheme, each with the one-line reason. They become the first ADRs. Per `references/architecture.md`.
8. **What you will not do**: explicitly out of scope for this scaffold.

**Then stop and wait for approval**, asked through the selector (approve as-is / revise the entities / revise the stack). Do not scaffold before the user approves. If they change the entities or the stack, revise and present again.

### 4. Scaffold

In this order, so the project works end to end at every step:

1. **Run the framework CLI** with the flags verified in phase 2. Let it create what it creates; do not fight it.
2. **Apply the folder structure** from the approved blueprint. Empty directories are fine as placeholders only if something in them is coming in this same scaffold; otherwise leave them out.
3. **Database schema** from the approved ERD, plus the initial migration. Verify it applies.
4. **Design system**: install the component library, set semantic tokens in the global stylesheet, configure dark mode. Per `references/design-system.md`.
5. **Guardrails, before the slice.** Copy the preset from `lint/` in the dotfiles repo: `oxlint.config.ts`, `.oxfmtrc.json`, `tools/oxlint/` and `rule-tests/`, plus `ci.yml` into `.github/workflows/`. Its `README.md` has the five install steps; `references/lint-guardrails.md` has the reasoning. Adapt the boundaries block **and its fixtures** to this project's layer names, then run `node tools/oxlint/rule-tests/check.mjs` — a boundary table nobody verified is a boundary table that may be denying everything or nothing. Guardrails go in first so the vertical slice is the first thing checked against them; boundary rules added after twenty files exist are boundary rules you weaken to make the build pass.
6. **One vertical slice.** Pick a single real entity from the ERD and build it all the way through: DTO, policy, DAL, action, and a page that renders it. This is the template every future feature copies, and it is what proves the architecture actually runs. Per `references/data-layer.md`. If the entity has a list — and most do — build the list the way `references/list-views.md` describes and the write the way `references/mutations.md` does, because whatever this slice does is what every later feature will copy. The URL-state dependency enters here and only here: install it when the slice actually has filters to put in the URL, not as part of the baseline, so a project without a list never carries it. **Write its tests here.** The slice is the template every later feature copies, so whatever testing habit it establishes is the one the project keeps: a slice shipped without a test teaches the agent that features do not come with tests.
7. **Security baseline**: security headers, the server-only markers, environment variable split, locked-down install scripts. Per `references/security.md`.
8. **Configuration and logging**: the environment schema that fails the build when a variable is missing, plus structured logging with a trace id. Per `references/operations.md`. If `product-analytics` applies, its capability goes in here too, with the core events typed in the catalog and the vertical slice emitting its business event. Per `references/product-analytics.md`.
9. **`AGENTS.md`** at the repo root: the framing and the Scope table at the top, then the conventions, the dependency rule, the resolved versions, and every vendor that receives personal data. A `CLAUDE.md` that points at `AGENTS.md` rather than duplicating it. Next to it, `docs/adr/` with one record per decision from blueprint item 7.

### 5. Verify

Run the build, the linter, `node tools/oxlint/rule-tests/check.mjs`, and the slice's tests. The four must pass. If the vertical slice has a page, run the dev server and confirm it renders.

Then audit the repo against the non-negotiables:

```bash
python <skill>/scripts/audit_project.py --path .
```

It reports three things, and the last two are different. `MISSING` is something the repo says is absent. `BY HAND` is a non-negotiable with a semantic signature that no tool can decide, which is exactly the kind that gets quietly dropped when a session's context rolls over. **A `BY HAND` line is not a pass, it is the list of what still needs a person.** Walk it before reporting the bootstrap done.

Report what was created, the resolved versions, anything the live docs corrected, and what is deliberately left for later. Do not claim it works without the command output.

## Convention

The failure this mode exists to prevent: an agent six weeks in, writing a query straight into a page component because nothing in its context said not to.

### Order of authority

1. **`AGENTS.md` at the repo root.** This is the project's own record: resolved versions, layer names, the illegal imports, the domain vocabulary, where a new feature goes. Read it before answering anything architectural.
2. **The code already there.** One existing module of the same kind outranks any general rule. Copy its shape.
3. **`references/`.** The principle behind the rule, and the answer when the repo is silent.

When the repo contradicts a reference file, **the repo wins** and you say so. A project that deliberately diverged is not a project that made a mistake. When the repo is silent, apply the reference and offer to write the decision into `AGENTS.md`.

### The procedure

0. **Audit first when you are new to the repo.** `python <skill>/scripts/audit_project.py --path .` gives you, in one pass, which non-negotiables are in place and which are not. Cheaper than reading twenty-two references to find out the project never had lint boundaries.
1. **Read `AGENTS.md`, the Scope first.** If there is none, say so: the project has no written conventions, and writing one is usually the highest-value next move. Per `references/architecture.md`. If there is no Scope section, run the scope study from `references/problem-framing.md` before recommending any concern the project may never have chosen.
2. **Check the concern against the scope.** Work that would build a concern marked **later** or **no** is a scope change: stop, say so, and update the Scope row with the user before applying that reference.
3. **Name the layer.** Answer "who should be allowed to know about this?" before "where does this file go?". The layer decides the folder, not the other way around.
4. **Open the one reference for the concern**, not all twenty-two. The table below maps concern to file.
5. **Resolve the `VERIFY:` blocks that apply** against the live docs before writing any code. A principle that is right and an API that is stale still produces a broken file.
6. **Point at the closest existing example** in the repo and match it: naming, file split, order of operations inside the function.

### When the question is not this skill's

One question arrives dressed as an architecture question and is answered better elsewhere. Hand it over instead of improvising:

| The question actually is | Skill | Why not here |
|---|---|---|
| "This is broken", "this got slow", a failing behaviour with no obvious cause | `diagnosing-bugs` | An architecture answer to a bug report is a guess. That skill starts from a reproduction and does not stop at the first plausible story |

### Keeping `AGENTS.md` alive

A convention that only lives in this skill is a convention the next session loses. When work establishes something durable (a new layer, a chosen library, a rule you had to explain twice), write it into `AGENTS.md` in the same change. Keep `CLAUDE.md` a pointer at `AGENTS.md`; two copies of the conventions means one of them is stale.

## Reference files

Read the one the work is about. Reading all twenty-two for a question about a foreign key wastes the context the actual task needs.

| File | Covers | Reach for it when |
|---|---|---|
| `problem-framing.md` | The problem statement, outcome, appetite, goals and non-goals, the riskiest assumption, the scope study (applies, later, no) and how scope changes | Starting a project, deciding what a project needs, or work that would add a concern the scope excluded |
| `architecture.md` | Layers, dependency rule, the modular monolith and when to leave it, ADRs for irreversible decisions, folder trees for both profiles, route groups and colocation, naming, boundary enforcement, `AGENTS.md` | Where a file goes, whether an import is legal, how to split packages, monolith vs services |
| `url-design.md` | Where the tenant lives in the URL, nesting vs flattening, ids and slugs, redirects and slug history, canonical forms, modals with their own URL | Designing the route space, or restructuring one that already has shared links |
| `routing.md` | Layouts, loading/error/not-found, metadata and SEO | Building out a route's shell, states, or social preview |
| `data-layer.md` | DAL, DTO, policy, multi-layered auth, per-render session caching | Anything that reads or writes the database |
| `list-views.md` | URL as state, query param schemas, keyset pagination and tiebreakers, sort allowlists, search, empty vs no-results, cached filter combinations, exports | Any screen that lists records with filters, sorting, search or pages |
| `mutations.md` | Action results, field-level errors, pending and optimistic states, cache invalidation after a write, double submission | A form, or anything the user submits |
| `database.md` | Which kind of database, PRD to entities to ERD, keys, relationships, referential actions, production migrations | Choosing the data store, designing the schema, or changing one that already has traffic |
| `multi-tenancy.md` | Isolation models, organizations and memberships, roles, tenant scoping, row-level security, cross-tenant leaks | The product has organizations or workspaces, in any form |
| `direct-data-access.md` | Managed backends where the browser can reach the database, the three postures, RLS as the whole security model, realtime channels, staying portable | Using Supabase or any platform that exposes the database to the client |
| `api-design.md` | Server actions vs route handlers, contract-first schemas, typed RPC, OpenAPI, error codes, webhooks | Exposing an endpoint or shaping a mutation |
| `async-work.md` | What leaves the request, job tiers, retries and idempotency, cron, job context | Work that is slow, scheduled, or can fail on its own |
| `file-uploads.md` | Presigned URLs, content validation, storage keys, metadata split, orphans | Users send you files |
| `security.md` | server-only, taint, env vars, XSS, security headers, validation, supply chain | Handling secrets, user-supplied content, or public entry points |
| `performance.md` | Waterfalls, streaming and Suspense, PPR, server vs client components, caching directives, images, bundle | Something is slow, or a route turned dynamic |
| `operations.md` | Structured logs, trace ids, redaction, error tracking, SLOs and error budgets, real-user performance, backups and restores, environment schema and secrets | Instrumenting the app, setting reliability targets, planning recovery, or wiring up configuration |
| `product-analytics.md` | Tracking plan, typed event catalog, server vs client capture, identity and tenant groups, route templates, feature flags and experiments | Measuring how users use the product, adding an event, a flag or an A/B test |
| `privacy.md` | Data inventory, purpose and minimisation, recorded consent, deletion and export, hosting regions and transfers, retention, Ley 1581 | The product stores personal data, adds a vendor that receives it, or a user asks to see or delete theirs |
| `lint-guardrails.md` | Layer boundary rules, type-evidence rules, anti-slop, design-system rules (`@shadcn/lint`), house rules, verifying the rules still bite, what lint cannot catch | Setting up lint, or turning a repeated convention into an enforced one. The working preset lives in `lint/` in dotfiles |
| `design-system.md` | Component ownership, semantic tokens, variants vs. wrappers, theming | Styling anything |
| `accessibility.md` | Semantic markup, table and sort semantics, focus lifecycle, live regions, form errors, what tooling misses | Building a table, a form, a modal or any custom interactive control |
| `maintenance.md` | How this skill is refreshed, what belongs in a `VERIFY` block, signals a reference went stale, what survives a change of stack | Updating these references after a major release, or evaluating a different framework, ORM or database |
