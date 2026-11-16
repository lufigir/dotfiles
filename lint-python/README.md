# The Python preset

The executable part of the architecture for a Python project: the same layers and the
same structure caps as the TypeScript preset in `lint/`, with the tools of this ecosystem.
The reasoning lives in `project-architecture`'s `stacks/python.md` reference.

| Job | Tool | Answers |
|---|---|---|
| Boundaries | [import-linter](https://github.com/seddonym/import-linter) | May this module import that one? |
| Structure | [ls-lint](https://ls-lint.org) | Where may a file live, and is it named in snake_case? |
| Lint and format | [ruff](https://docs.astral.sh/ruff/) | Bugs, bandit security checks, import order, formatting |
| Types | pyright | Does the code prove what it claims? |

## What is here

```
lint-python/
├── pyproject.toml          the [tool.*] sections to copy: ruff and the import contracts
├── .ls-lint.yml            structure: loose files per layer and per module, snake_case
├── .pre-commit-config.yaml format on commit; lint, structure and boundaries on push
├── ci.yml                  the workflow: parallel jobs, a time cap per job, merge_group
└── rule-tests/
    ├── check.py            do the contracts and the caps still bite?
    └── fixtures/           a package whose BROKEN lines must fail and CLEAN lines must not
```

## Installing into a project

**1. Copy.**

```bash
cp -r <dotfiles>/lint-python/rule-tests          <project>/tools/lint-python/rule-tests
cp    <dotfiles>/lint-python/.ls-lint.yml        <project>/
cp    <dotfiles>/lint-python/.pre-commit-config.yaml <project>/
cp    <dotfiles>/lint-python/ci.yml              <project>/.github/workflows/ci.yml
```

Merge the `[tool.ruff]` and `[tool.importlinter]` sections of `pyproject.toml` into the
project's own.

**2. Dependencies.** Look up current versions rather than trusting these.

```bash
uv add --dev ruff import-linter pyright pytest pre-commit
uv run pre-commit install --hook-type pre-commit --hook-type pre-push
```

ls-lint runs through `npx`, which every GitHub runner has; on a machine without Node,
download its binary from the releases page.

**3. Adapt the layers, the only step that thinks.** The preset ships the profile from
`architecture.md` under a package named `app`: `app.api` (transport: HTTP routes, the
CLI, a LangGraph graph), `app.data` (one package per module), `app.capabilities` (the
database client, the model, mail, storage) and `app.domain` (pure). Rename the package
and the layers in `pyproject.toml`, `.ls-lint.yml` **and the fixtures** at the same time,
then run the bench: a contract written against names that no longer exist checks nothing
and reports nothing.

## Verifying that the rules bite

```bash
uv run python tools/lint-python/rule-tests/check.py
```

The checker stages the fixtures beside the real `pyproject.toml` in a temp directory,
runs import-linter, and requires every `# BROKEN:` line to be the first hop of a broken
contract and no `# CLEAN:` line to be one. Then it crowds a layer past its cap and
requires ls-lint to refuse it. Run it after bumping import-linter and after adapting
the layers.

## Decisions, and why

**import-linter over tach.** Its `layers` contract is the dependency rule written down,
one line per layer. tach models a modular monolith with declared dependencies and public
interfaces per module; reach for it when the modules, not the layers, are what drift.

**`allow_indirect_imports` on the transport contract.** import-linter follows indirect
imports by default, so forbidding `app.api` from importing `app.capabilities` also
forbids `app.api → app.data → app.capabilities`, which is the legal path. Measured on
import-linter 2.16 against the fixtures, not assumed.

**Literal layer paths in `.ls-lint.yml`.** When two wildcard patterns match the same
folder (`src/app/*` and `src/app/*/**`), ls-lint 2.3.2 picks one at random on each run:
measured at 5 failures in 8 identical runs. A literal path always wins over a wildcard.

**Caps one higher than TypeScript's.** Every package carries an `__init__.py`, and it
counts.

**snake_case, not kebab-case.** A hyphen cannot be imported.
