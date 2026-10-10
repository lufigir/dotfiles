# Testing

The other references describe how the code should be built. This one is about how anyone, a reviewer, a teammate or the agent that wrote it, finds out whether it was.

That question is harder with agents. An agent produces a feature in minutes and a reviewer reads it in the same minutes, so the review is no longer the bottleneck that used to catch what the author missed. The 2025 DORA report puts the effect in one line: AI raises throughput and lowers stability, and the teams that keep stability are the ones with "robust control systems, like strong automated testing". A large study of AI-authored commits in public repositories (Liu et al., 2026) found that more than 15% of every assistant's commits introduce an issue and that 22.7% of those issues are still in the code at the latest revision.

Tests are the executable half of the specification, the same way `lint-guardrails.md` is the executable half of the architecture. Lint checks the shape of the code; tests check what it does.

## The shape: mostly integration

The layers of this architecture decide what each kind of test is for, and the answer is not a pyramid with unit tests at the base.

| Kind | Runs | Here it covers |
|---|---|---|
| **Static** | Types and lint, on every save | Everything with a syntactic signature. Already in place; see `lint-guardrails.md` |
| **Unit** | A pure function, no I/O | Policies, parsers, formatters, any function whose inputs fully decide its output |
| **Integration** | Real code against a real database | The DAL and the actions: the layer where the bugs that cost money live |
| **End to end** | The deployed app in a browser | The one or two flows the product exists for, and nothing else |

Most of the suite is integration, because most of what can go wrong in this stack goes wrong between layers: a query that ignores the tenant, an action that skips the session, a DTO that leaks a column. A unit test with the database mocked passes in all three cases, since the mock returns what the test told it to.

## Per layer

**Policies are unit tests, and they are the cheapest tests in the repo.** A policy is pure by construction (`data-layer.md`, enforced by the boundary rule), so it takes a table: every role against every state that matters, with the expected boolean. A table makes the missing row visible, and the missing row is the permission bug.

**Test the DAL against a real database.** Postgres, the same major version as production, with the migrations applied. Not SQLite, not an in-memory fake. Row-level security, constraints, collation and `ON CONFLICT` behave differently there or not at all, and the DAL relies on all four. Each test gets its own data and leaves nothing behind, either inside a transaction that rolls back or in a schema or branch thrown away after the run. Two tests are not optional in a multi-tenant product:

- **The cross-tenant test.** A user of tenant A asks, by id, for a record of tenant B, and gets nothing. Per `multi-tenancy.md`. It is the one test that proves the tenant really is a required argument.
- **The DTO test.** A read returns exactly the fields the DTO declares, so a column added to the table later does not quietly travel to the client.

**Test actions as the public endpoints they are.** Call the action directly, not through the form. Three cases each: no session is rejected, invalid input is rejected with field errors, and the valid call writes what it says. The first case is the runtime twin of the `action-asserts-identity` lint rule: the rule checks that identity is reached, the test checks that reaching it actually stops an anonymous caller.

**Components get a test only when they hold logic.** A component that renders props needs none; the type checker and the end-to-end flow cover it. One with real behaviour (a multi-step form, a keyboard-driven list, an optimistic update that rolls back) gets a test that drives it the way a user does: by role and label, never by class name or test id when a role exists. Per `accessibility.md`, a control a test cannot find by its role is a control a screen reader cannot find either.

**End to end covers the reason the product exists.** Sign up, do the one thing, see the result. Add an accessibility scan on the pages it visits, since it is nearly free there. Keep this layer small: every end-to-end test is slow, and every flaky one teaches the team to rerun CI until it passes.

## Mocks belong at the capability boundary

The layering already says where the seams are. Vendors sit behind capabilities (`architecture.md`), so a test replaces the capability, the email sender or the payment gateway, with a fake that records what it was asked to do. Mock nothing above that line, not the DAL, not the database client, not a sibling module.

Mocking a module you own is the test saying "assume this works", which is the claim the test was supposed to check. anti-slop ships `no-module-mocking` for this reason; it sits commented in the preset until the project has tests, and turning it on is the right move once it does.

## The slice sets the habit

Bootstrap phase 4 builds one vertical slice and writes its tests in the same change. That is the point where the project's testing habit is decided, because the agent copies whatever the slice did. The slice ships with:

- the policy table,
- the DAL integration tests, including cross-tenant if the product has tenants,
- the three action cases,
- one end-to-end test of the slice's flow,
- the query-count assertion from `resource-budget.md`.

After that, a feature that arrives without tests is a feature that does not match the template, and the reviewer can point at the slice to say so.

## When a bug is found

The bug gets a failing test before it gets a fix. The test reproduces the report, fails for the reason the report describes, and passes after the fix. Without it, the fix is a claim; with it, the same bug cannot come back silently. The `diagnosing-bugs` skill starts from the same reproduction, so both start from the same test.

## In CI

The preset's `ci.yml` runs `npm test` after the type check. Integration tests need a database in CI: a service container with the production major version, or a database branch created for the run and deleted after it. A test suite that only runs on a laptop is advisory, the same way lint is advisory until CI runs it.

> **VERIFY:** the current test runner and its support for async Server Components (React Testing Library has not rendered them directly; check whether that changed), the end-to-end runner and its accessibility integration, and how the database provider creates disposable branches or how to run Postgres as a CI service container. These change faster than anything else in this file.

## Coverage is not the target

A coverage number counts lines executed, not behaviour checked. A test with no assertions raises it; so does a test that mocks the thing it tests. Use coverage to find untested files, never as a gate. If a gate is wanted, mutation testing measures what coverage pretends to: whether the tests fail when the code is wrong.

## Common mistakes

| Mistake | Consequence |
|---|---|
| The database mocked in DAL tests | Tenant leaks, RLS gaps and leaked columns all pass |
| SQLite or an in-memory fake standing in for Postgres | The constraint or policy the DAL relies on is not there to test |
| No cross-tenant test | Isolation is assumed, and the first proof is a customer's report |
| Actions tested only through the form | The anonymous direct call, the one an attacker makes, is never tried |
| Mocking modules the project owns | The test asserts its own assumption |
| Many end-to-end tests, few integration tests | Slow, flaky CI that gets rerun until green |
| Selecting elements by class or test id | Tests break on restyles and miss unlabelled controls |
| Fixing a bug without a failing test first | The fix is a claim and the bug can return |
| Coverage percentage as the merge gate | Tests get written to touch lines, not to check behaviour |
| A slice shipped without tests | Every later feature copies that, too |
