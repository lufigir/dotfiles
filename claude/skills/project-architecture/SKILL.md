---
name: project-architecture
description: Senior-level architecture for a product, in two modes. **Bootstrap** starts a project from zero (discovery, ERD, layered folders, data access layer, design tokens, agent guardrails) instead of shipping whatever the framework CLI left behind. **Convention** answers architecture questions mid-build so the rules set in week one still hold in week six: where does this file go, may this layer import that one, how do I model this table, does this query stay inside the tenant, is this endpoint safe, why is this route slow. Use when starting/creating/bootstrapping/scaffolding a project, and whenever work touches folder structure, layer boundaries, data access, schema design, migrations, multi-tenancy, API contracts, background jobs, file uploads, security, performance or observability. Spanish triggers: "proyecto nuevo", "crea la estructura", "monta el proyecto", "dónde va este archivo", "en qué capa", "cómo modelo esta tabla", "esto rompe la arquitectura", "está bien así".
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

`references/` holds distilled architecture knowledge: layering, the dependency rule, DAL/DTO/policy, ERD design and migrations, tenant isolation, API contracts, async work, uploads, security, performance, operations and design tokens. Those **principles** hold across versions.

**Every concrete API, file name, flag, and command in them is a moving target.** The reference files mark those with `VERIFY:` blocks stating exactly what to look up. Resolve them against the live docs before writing code, in **both** modes, not just at bootstrap. Context7 goes through Executor; see the `mcp-integrations` skill for the tool path and the two-step flow. Read the version attached to whatever comes back: it is the difference between "the docs say X" and "the docs for the version installed here say X".

Never write code from what a reference file, or your training data, *implies* the current API is. Live example: Next.js renamed `middleware` to `proxy`, and now ships its own docs inside `node_modules/next/docs`. Anything that hardcoded those is already wrong.

When the live docs contradict a reference file, **the docs win** and you say so out loud. If a reference file's *principle* no longer has a mechanism in the current version, say that too rather than inventing one.

## The non-negotiables

The compressed form of the rules, for recall. Each one expands in the reference file named; that file is the authority.

1. **The dependency rule.** UI → Transport → Domain → Capabilities → Vendors, each layer reaching only the one below it. Shared contracts and the database client flow upward to everyone. (`architecture.md`)
2. **The DAL is the only path to the database.** No ORM call in a page, a component, a route handler, or an action. (`data-layer.md`)
3. **In a multi-tenant product, the tenant is a required argument.** Never optional, never inherited, never taken from a client-controlled value. This covers jobs, caches and storage keys, not just queries. (`multi-tenancy.md`)
4. **Authorization before data, next to the data.** Upstream gates are an optimization, not the security model. (`data-layer.md`)
5. **Validate in and out.** Inputs because users lie; outputs because the database returns more than the client should see. (`data-layer.md`)
6. **Server-only is a build error, not a convention.** Sensitive modules import the server-only marker so a client import fails loudly. (`security.md`)
7. **Every entry point is public.** A server action compiles to a POST endpoint; arriving through your form is not a fact you get to assume. (`security.md`)
8. **Server Components by default.** `"use client"` lives on the leaves, only where there is interactivity. (`performance.md`)
9. **One contract, both directions.** The schema is the single source of truth for input, output, types and docs. (`api-design.md`)
10. **Semantic tokens, never literal colors.** `bg-primary`, not `bg-blue-500`. (`design-system.md`)
11. **One naming format.** kebab-case for source files, snake_case in the database. (`architecture.md`, `database.md`)

## Bootstrap

Create a todo per phase. Do not skip phase 3's checkpoint.

### 1. Discovery

Understand the product before touching the stack. Ask only what you cannot infer, and ask it through the `AskUserQuestion` selector per the global `CLAUDE.md` rules: tenancy, profile and everything already decided are enumerable, so they are tabs. Only the mini-PRD paragraph is genuinely open, so that one goes in prose after the selector.

- **What is it?** One paragraph. This becomes the mini-PRD.
- **Features in scope.** A list. Every noun in it is a candidate entity.
- **Who are the users, and does it have tenancy?** Single-user, multi-user, or multi-tenant (organizations/workspaces). This one decision reshapes the whole schema, and if the answer is multi-tenant, `references/multi-tenancy.md` governs the model before anything else does.
- **What is already decided?** Deployment target, database, auth provider, payments, anything the user already pays for or knows they want.
- **Does anything run outside a request?** Uploads, scheduled work, emails, exports, anything slow. These need a home in the blueprint rather than an improvised one later. Per `references/async-work.md` and `references/file-uploads.md`.

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

1. **Mini-PRD**: the paragraph and the feature list.
2. **Entities and ERD**: tables, fields, keys, relationship types. Per `references/database.md`. Present as a diagram or a clear list; this is the piece most worth getting right before any code exists.
3. **Folder tree**: the actual tree you will create, per `references/architecture.md` and the chosen profile.
4. **Stack and exact versions**: resolved in phase 2, plus anything the live docs corrected.
5. **What you will not do**: explicitly out of scope for this scaffold.

**Then stop and wait for approval**, asked through the selector (approve as-is / revise the entities / revise the stack). Do not scaffold before the user approves. If they change the entities or the stack, revise and present again.

### 4. Scaffold

In this order, so the project works end to end at every step:

1. **Run the framework CLI** with the flags verified in phase 2. Let it create what it creates; do not fight it.
2. **Apply the folder structure** from the approved blueprint. Empty directories are fine as placeholders only if something in them is coming in this same scaffold; otherwise leave them out.
3. **Database schema** from the approved ERD, plus the initial migration. Verify it applies.
4. **Design system**: install the component library, set semantic tokens in the global stylesheet, configure dark mode. Per `references/design-system.md`.
5. **One vertical slice.** Pick a single real entity from the ERD and build it all the way through: DTO, policy, DAL, action, and a page that renders it. This is the template every future feature copies, and it is what proves the architecture actually runs. Per `references/data-layer.md`.
6. **Security baseline**: security headers, the server-only markers, environment variable split, locked-down install scripts. Per `references/security.md`.
7. **Configuration and logging**: the environment schema that fails the build when a variable is missing, plus structured logging with a trace id. Per `references/operations.md`.
8. **Guardrails**: lint rules enforcing the layer boundaries, plus `AGENTS.md` at the repo root documenting conventions, the dependency rule, and the resolved versions. A `CLAUDE.md` that points at `AGENTS.md` rather than duplicating it.

### 5. Verify

Run the build and the linter. Both must pass. If the vertical slice has a page, run the dev server and confirm it renders.

Report what was created, the resolved versions, anything the live docs corrected, and what is deliberately left for later. Do not claim it works without the command output.

## Convention

The failure this mode exists to prevent: an agent six weeks in, writing a query straight into a page component because nothing in its context said not to.

### Order of authority

1. **`AGENTS.md` at the repo root**, plus `CONTEXT.md` if the project keeps one. This is the project's own record: resolved versions, layer names, the illegal imports, where a new feature goes. Read it before answering anything architectural.
2. **The code already there.** One existing module of the same kind outranks any general rule. Copy its shape.
3. **`references/`.** The principle behind the rule, and the answer when the repo is silent.

When the repo contradicts a reference file, **the repo wins** and you say so. A project that deliberately diverged is not a project that made a mistake. When the repo is silent, apply the reference and offer to write the decision into `AGENTS.md`.

### The procedure

1. **Read `AGENTS.md`.** If there is none, say so: the project has no written conventions, and writing one is usually the highest-value next move. Per `references/architecture.md`.
2. **Name the layer.** Answer "who should be allowed to know about this?" before "where does this file go?". The layer decides the folder, not the other way around.
3. **Open the one reference for the concern**, not all twelve. The table below maps concern to file.
4. **Resolve the `VERIFY:` blocks that apply** against the live docs before writing any code. A principle that is right and an API that is stale still produces a broken file.
5. **Point at the closest existing example** in the repo and match it: naming, file split, order of operations inside the function.

### Keeping `AGENTS.md` alive

A convention that only lives in this skill is a convention the next session loses. When work establishes something durable (a new layer, a chosen library, a rule you had to explain twice), write it into `AGENTS.md` in the same change. Keep `CLAUDE.md` a pointer at `AGENTS.md`; two copies of the conventions means one of them is stale.

## Reference files

Read the one the work is about. Reading all twelve for a question about a foreign key wastes the context the actual task needs.

| File | Covers | Reach for it when |
|---|---|---|
| `architecture.md` | Layers, dependency rule, folder trees for both profiles, route groups and colocation, naming, boundary enforcement, `AGENTS.md` | Where a file goes, whether an import is legal, how to split packages |
| `routing.md` | Layouts, loading/error/not-found, metadata and SEO | Building out a route's shell, states, or social preview |
| `data-layer.md` | DAL, DTO, policy, multi-layered auth, per-render session caching | Anything that reads or writes the database |
| `database.md` | PRD to entities to ERD, keys, relationships, referential actions, production migrations | Designing the schema, or changing one that already has traffic |
| `multi-tenancy.md` | Isolation models, organizations and memberships, roles, tenant scoping, row-level security, cross-tenant leaks | The product has organizations or workspaces, in any form |
| `api-design.md` | Server actions vs route handlers, contract-first schemas, typed RPC, OpenAPI, error codes, webhooks | Exposing an endpoint or shaping a mutation |
| `async-work.md` | What leaves the request, job tiers, retries and idempotency, cron, job context | Work that is slow, scheduled, or can fail on its own |
| `file-uploads.md` | Presigned URLs, content validation, storage keys, metadata split, orphans | Users send you files |
| `security.md` | server-only, taint, env vars, XSS, security headers, validation, supply chain | Handling secrets, user-supplied content, or public entry points |
| `performance.md` | Waterfalls, streaming and Suspense, PPR, server vs client components, caching directives, images, bundle | Something is slow, or a route turned dynamic |
| `operations.md` | Structured logs, trace ids, redaction, error tracking, environment schema and secrets | Instrumenting the app, or wiring up configuration |
| `design-system.md` | Component ownership, semantic tokens, variants vs. wrappers, theming | Styling anything |
