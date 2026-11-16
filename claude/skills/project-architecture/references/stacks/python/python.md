# Python

The stack file for a Python product: a service, a CLI, a data pipeline or an agent built on LangGraph. The principles in `core/` hold unchanged; this file says how each one is built and enforced in Python. The working preset lives in `lint-python/` in the dotfiles repo, and it is the artifact you copy, the same way `lint/` is for TypeScript.

## The layers as packages

The dependency rule from `architecture.md` maps onto subpackages of one root package, with a `src/` layout so tests import the installed package and never the working directory by accident.

| Layer | Package | Holds | Imports |
|---|---|---|---|
| Transport | `app.api` | HTTP routes, the CLI, webhooks, the LangGraph graph | `app.data`, `app.domain` |
| Data | `app.data.<module>` | `dto.py`, `policy.py`, `dal.py` per module | `app.capabilities`, `app.domain` |
| Capabilities | `app.capabilities` | The database client, the model client, mail, storage: every vendor behind a seam | `app.domain` |
| Domain | `app.domain` | Pure functions and types: no network, no disk, no clock | nothing above it |

Transport reaches data, never a capability directly, because the data layer is where authorization lives (`data-layer.md`). A route that opens a database session skipped the policy.

Modules exist in every layer, with the same name: `app.data.orders`, `app.domain.orders`. Three modules sharing a prefix in one layer's root are a package that does not exist yet.

## The data layer in Python

The DTO, the policy and the DAL keep their jobs from `data-layer.md`:

- **`dto.py`** holds the schemas for what enters and what leaves. Validation runs at the edge of the data layer, in both directions, and a raw row never leaves the DAL.
- **`policy.py`** holds pure predicates over the actor and the record: who may read, who may change which state. Pure means testable without a database.
- **`dal.py`** is the only module that holds a session. Every public function takes the actor, checks the policy, then touches the data.

In a multi-tenant product the tenant is a required parameter of every DAL function, never a default and never read from a global (`multi-tenancy.md`).

> **VERIFY:** the current validation library and its major version (Pydantic is the common choice), and how the ORM or driver in use scopes a session per request.

## An agent on LangGraph

`llm-agents.md` holds the principles; this is where the pieces of a LangGraph app sit in the layers.

| Piece | Layer | Why |
|---|---|---|
| The graph, and the entry `langgraph.json` points at | Transport | It is an entry point: it receives a request and decides the order of the work |
| Node functions | Transport, calling data and domain | A node is a step of the control flow. Code owns it; the model fills in values |
| The state schema | Domain | It is the contract between nodes, typed and validated like any DTO |
| Tools the model may call | Data or capabilities, behind a narrow function | A tool is an entry point the model reaches. A tool that writes goes through the DAL and its policy, like a route |
| The model client, the checkpointer, the vector store | Capabilities | Vendors behind a seam, swappable without touching a node |

The official layout puts `tools.py`, `nodes.py` and `state.py` side by side in one `utils/` folder. That is fine for a demo and is the flat layer this file exists to prevent: a tool in `utils/` imports the database client and the boundary is gone.

> **VERIFY:** the current `langgraph.json` keys (`graphs`, `dependencies`, `env`) and the path syntax for a graph inside a `src/` package.

## The pieces

| Job | Tool | Config |
|---|---|---|
| Boundaries | import-linter | `[tool.importlinter]` in `pyproject.toml`: one `layers` contract, one `forbidden` contract for transport to capabilities |
| Structure | ls-lint | `.ls-lint.yml`: loose files per layer and per module, snake_case |
| Lint and format | ruff | `[tool.ruff]`: bugs, bandit security rules, naming, import order |
| Types | pyright | Strict on new code |
| Tests | pytest | Integration tests against a real database, per `testing.md` |
| Environment | uv | `uv sync --locked` in CI, a committed lockfile |

Two findings that the docs do not announce, both measured against the preset's fixtures:

- **import-linter follows indirect imports by default.** A `forbidden` contract from `app.api` to `app.capabilities` also rejects `app.api → app.data → app.capabilities`, the legal path. The transport contract sets `allow_indirect_imports = true`.
- **ls-lint picks at random between two wildcards** that match the same folder (`src/app/*` and `src/app/*/**`). Each layer root is written as a literal path.

> **VERIFY:** the current versions of import-linter, ruff, pyright and uv, and whether ruff has absorbed a check this table assigns to another tool.

## Guardrails

Copy `lint-python/` per its README: the `pyproject.toml` sections, `.ls-lint.yml`, the pre-commit hooks and `ci.yml`. Rename the package and the layers in the config **and in the fixtures** at the same time, then run the bench:

```bash
uv run python tools/lint-python/rule-tests/check.py
```

It requires every `# BROKEN:` import in the fixtures to break a contract and no `# CLEAN:` import to, and it crowds a layer past its cap. A contract written against package names that no longer exist checks nothing and reports nothing, which is exactly what a passing contract looks like.

## Naming

snake_case for modules and packages, because a hyphen cannot be imported; PascalCase for classes. This is the stack's answer to the one-naming-format rule in `architecture.md`. ruff's `N` rules and ls-lint enforce it.

## Common mistakes

| Mistake | Consequence |
|---|---|
| A flat package: `utils.py`, `helpers.py`, `services.py` at the root | No layer to enforce, so import-linter has nothing to say and every module can reach every vendor |
| A route or a graph node that opens a database session | The policy never ran; authorization is whatever the caller remembered |
| A LangGraph tool that writes straight to the database | The model reached a write without the DAL; one injected instruction is one unauthorised change |
| `forbidden` contract without `allow_indirect_imports` on a layered path | The legal chain fails, the contract gets deleted, and the real boundary goes with it |
| Running the app from the repo root without a `src/` layout | Tests import the working directory, not the package, and pass against code that will not ship |
