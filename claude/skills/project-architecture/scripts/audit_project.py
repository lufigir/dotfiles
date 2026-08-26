#!/usr/bin/env python3
"""Audita un proyecto contra los no-negociables de la skill.

`check_skill.py` revisa la salud de la skill. Este revisa la salud del
*proyecto*: cuáles de los quince no-negociables de SKILL.md están puestos,
cuáles faltan, y cuáles esta herramienta no puede decidir.

El problema que resuelve no es de tamaño sino de seguimiento. El bootstrap
tiene nueve fases y diecinueve referencias, y el contexto de una sesión se
pierde antes de llegar al final. Una lista que alguien marca a mano dice
"hecho" de cosas que no lo están; esto mira el repo.

Tres resultados, y la diferencia entre los dos últimos es la que importa:

    OK        la comprobación pasó
    MISSING   el repo dice que no está, con certeza suficiente para actuar
    BY HAND   tiene firma semántica, no sintáctica: lo decide una persona

Un no-negociable en BY HAND no es un aprobado. Es la lista de lo que queda por
mirar, que es justo lo que se pierde cuando el contexto rueda.

Uso:
    python audit_project.py --path /ruta/al/proyecto
    python audit_project.py                    # el directorio actual

Sale 0 cuando no falta nada comprobable; 1 cuando falta algo.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

# Extensiones que cuentan como código fuente del producto.
SOURCE = (".ts", ".tsx", ".js", ".jsx")

# Directorios que nunca son fuente del producto, aunque contengan `.ts`.
NOT_SOURCE = {
    "node_modules", ".next", ".git", "dist", "build", "out",
    "tools", ".claude", ".codex", ".agents",
}

# Paquetes que hablan con la base de datos. Un import de estos fuera del DAL
# rompe el no-negociable 2. La lista es corta a propósito: cubrir todos los ORM
# del mundo daría falsos negativos silenciosos, así que lo que no reconoce lo
# reporta como BY HAND en vez de callarse.
DB_PACKAGES = (
    "@supabase/supabase-js", "@supabase/ssr", "@prisma/client",
    "drizzle-orm", "kysely", "mongoose", "typeorm", "pg",
)

LITERAL_PALETTE = re.compile(
    r"\b(?:bg|text|border|ring|fill|stroke|from|via|to|divide|placeholder)"
    r"-(?:red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo"
    r"|violet|purple|fuchsia|pink|rose|slate|gray|zinc|neutral|stone)-\d{2,3}\b"
)

KEBAB = re.compile(r"^[a-z0-9]+(?:[-.][a-z0-9]+)*$")


@dataclass
class Report:
    ok: list[str] = field(default_factory=list)
    missing: list[str] = field(default_factory=list)
    manual: list[str] = field(default_factory=list)

    def passed(self, rule: str, msg: str) -> None:
        self.ok.append(f"{rule}  {msg}")

    def fails(self, rule: str, msg: str) -> None:
        self.missing.append(f"{rule}  {msg}")

    def by_hand(self, rule: str, msg: str) -> None:
        self.manual.append(f"{rule}  {msg}")


def source_files(root: Path) -> list[Path]:
    return [
        p for p in root.rglob("*")
        if p.suffix in SOURCE
        and p.is_file()
        and not any(part in NOT_SOURCE for part in p.relative_to(root).parts)
    ]


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def load_package_json(root: Path) -> dict:
    raw = read(root / "package.json")
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def audit(root: Path) -> Report:
    r = Report()
    pkg = load_package_json(root)
    deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
    files = source_files(root)
    has_eslint = any((root / n).exists() for n in ("eslint.config.mjs", "eslint.config.js"))
    oxlint_config = next(
        (root / name for name in ("oxlint.config.ts", ".oxlintrc.json")
         if (root / name).exists()),
        None,
    )
    oxlint_text = read(oxlint_config) if oxlint_config else ""

    # --- 15. Un solo formato de nombres --------------------------------------
    # Primero porque es la comprobación más barata y la que más se rompe sin
    # que nadie mire.
    bad_names = [
        p.relative_to(root).as_posix() for p in files
        if not KEBAB.match(p.stem.lower()) or p.stem != p.stem.lower()
    ]
    if not files:
        r.by_hand("15 naming", "found no source files; is the path right?")
    elif bad_names:
        r.fails("15 naming", f"{len(bad_names)} files are not kebab-case: {sample(bad_names)}")
    else:
        r.passed("15 naming", f"all {len(files)} source files are kebab-case")

    # --- 11. Una frontera sin lintear es una preferencia ----------------------
    if oxlint_config is None:
        r.fails("11 lint", "no oxlint config; the dependency rule is not executable")
    else:
        if "no-restricted-imports" in oxlint_text:
            negations = oxlint_text.count('"!')
            detail = (
                f"with {negations} negation(s) reopening legal imports" if negations
                else "with no negations: check it is not denying more than intended"
            )
            r.passed("11 lint", f"boundary rules present, {detail}")
        elif has_eslint:
            r.fails("11 lint", f"boundaries still live in ESLint, not {oxlint_config.name}; oxlint has no-restricted-imports, so the move is mechanical")
        else:
            r.fails("11 lint", f"{oxlint_config.name} has no no-restricted-imports: no linted boundaries")

        for plugin, what in (("anti-slop", "evidence rules"), ("house", "house rules")):
            if plugin in oxlint_text:
                r.passed("11 lint", f"{what} ({plugin}) are registered")
            else:
                r.fails("11 lint", f"plugin {plugin} missing: {what} do not run")

        if "typeAware" in oxlint_text or "type-aware" in oxlint_text:
            r.passed("11 lint", "type-aware rules are on")
        else:
            r.fails("11 lint", "no typeAware: no-floating-promises does not run, and that is the one that catches the write that never happened")

        if '"warn"' in oxlint_text:
            r.fails("11 lint", "rules set to warn; a warn rule is a rule violated forever")

    if (root / "tools" / "oxlint" / "rule-tests" / "check.mjs").exists():
        r.passed("11 lint", "rule verifier is in place; run node tools/oxlint/rule-tests/check.mjs")
    else:
        r.fails("11 lint", "no rule-tests/check.mjs: nothing proves the boundaries still bite")

    for legacy, tool in (
        ("eslint.config.mjs", "ESLint"),
        ("eslint.config.js", "ESLint"),
        (".prettierrc", "Prettier"),
        ("prettier.config.js", "Prettier"),
    ):
        if (root / legacy).exists():
            r.fails("11 lint", f"{legacy} remains: the preset is one vendor (oxc), not a half migration alongside {tool}")

    if pkg and pkg.get("type") != "module":
        r.fails("11 lint", 'package.json lacks "type": "module": the .ts oxlint config will not load, and the error does not say why')

    if "oxlint" in deps and "oxlint-tsgolint" not in deps:
        r.fails("11 lint", "oxlint-tsgolint missing: --type-aware will not start")

    ox, plugins = deps.get("oxlint", ""), deps.get("@oxlint/plugins", "")
    if ox and plugins and ox.lstrip("^~") != plugins.lstrip("^~"):
        r.fails("11 lint", f"oxlint ({ox}) and @oxlint/plugins ({plugins}) differ; they must match")

    # --- 2. El DAL es el único camino a la base de datos ----------------------
    offenders, edge_cases = [], []
    found_orm = False
    for f in files:
        if not any(package in read(f) for package in DB_PACKAGES):
            continue
        found_orm = True
        rel = f.relative_to(root).as_posix()
        if rel.endswith(".dal.ts") or "/dal/" in rel:
            continue
        # `lib/` es donde vive el wrapper del cliente: esos archivos SON la
        # puerta, no alguien saltándosela. Que solo el DAL los llame lo
        # comprueba la regla de fronteras, no esto.
        if rel.startswith("lib/"):
            continue
        # El proxy o middleware refresca la sesión en cada petición, así que
        # sostiene un cliente por necesidad. Excepción legítima, y también el
        # sitio donde se cuela una consulta: se mira, no se falla.
        if Path(rel).stem in ("proxy", "middleware"):
            edge_cases.append(rel)
            continue
        offenders.append(rel)

    for case in edge_cases:
        r.by_hand("2 DAL", f"{case} holds a client: correct for refreshing the session, wrong if it also queries")
    if not found_orm:
        r.by_hand("2 DAL", "recognised no database client; if the project has one, check by hand that only the DAL imports it")
    elif offenders:
        r.fails("2 DAL", f"{len(offenders)} files outside the DAL import the database: {sample(offenders)}")
    else:
        r.passed("2 DAL", "only the DAL imports the database")

    # --- 6. server-only es un error de build, no una convención --------------
    if "server-only" in deps:
        marked = sum(1 for f in files if "server-only" in read(f))
        if marked:
            r.passed("6 server-only", f"the marker is imported in {marked} file(s)")
        else:
            r.fails("6 server-only", "server-only is installed but no module imports it: a client import does not fail")
    else:
        r.fails("6 server-only", "no server-only: nothing turns a client import into a build error")

    # --- 14. Tokens semánticos, nunca colores literales -----------------------
    literals = [
        f.relative_to(root).as_posix() for f in files
        if "components/ui/" not in f.relative_to(root).as_posix()
        and LITERAL_PALETTE.search(read(f))
    ]
    if literals:
        r.fails("14 tokens", f"{len(literals)} files use literal colours: {sample(literals)}")
    else:
        r.passed("14 tokens", "no literal colours outside the design system")

    # --- Fase 9. AGENTS.md, y el CLAUDE.md que apunta a él -------------------
    agents = root / "AGENTS.md"
    if agents.exists():
        r.passed("p9 AGENTS", f"AGENTS.md exists ({len(read(agents).splitlines())} lines)")
        claude = root / "CLAUDE.md"
        if claude.exists() and "AGENTS.md" not in read(claude):
            r.fails("p9 AGENTS", "CLAUDE.md does not point at AGENTS.md: two copies of the conventions, one of them stale")
    else:
        r.fails("p9 AGENTS", "no AGENTS.md: the next session starts without the conventions you decided")

    # --- Fase 6. La vertical slice trae test --------------------------------
    tests = [
        f for f in files
        if ".test." in f.name or ".spec." in f.name
        or "__tests__" in f.relative_to(root).parts
    ]
    if tests:
        r.passed("p6 tests", f"{len(tests)} test file(s)")
    else:
        r.fails("p6 tests", "no tests: the linter never sees a missing tenant filter or a job that is not idempotent")

    # --- CI. Las reglas solo son reales si algo bloquea el merge -------------
    workflow_dir = root / ".github" / "workflows"
    workflows = list(workflow_dir.glob("*.yml")) if workflow_dir.exists() else []
    if not workflows:
        r.fails("CI", "no workflow: the rules run when somebody remembers, which is the same as advisory")
    else:
        ci = "\n".join(read(w) for w in workflows)
        for needle, what in (
            ("oxlint", "the linter"),
            ("rule-tests/check.mjs", "the rule verifier"),
            ("tsc", "the type check"),
        ):
            if needle in ci:
                r.passed("CI", f"{what} runs in CI")
            else:
                r.fails("CI", f"{what} does not run in CI")

    # --- Lo que ninguna herramienta puede decidir ---------------------------
    # Firma semántica, no sintáctica. `lint-guardrails.md` explica por qué: una
    # herramienta revisa la forma del código, nunca su significado. Salen
    # siempre, precisamente para que no se pierdan.
    for rule, question in (
        ("1 layers", "does each layer import only the one below it? The boundary table declares it; whether it is the right table is your call"),
        ("3 tenant", "is the tenant a required argument in queries, jobs, caches and storage keys?"),
        ("4 authz", "does authorization run before the data is fetched, and next to the data?"),
        ("5 validate", "is there validation in and out? Users lie, and the database returns more than the client should see"),
        ("7 entrypoints", "does every server action assume the request may not have come from your form?"),
        ("8 RSC", 'does "use client" live only on leaves with interactivity?'),
        ("9 contract", "is the schema the single source of truth for input, output, types and docs?"),
        ("10 URL", "do filters, sort, search and page live in the URL?"),
        ("12 URLs", "does any route encode a relationship that can move? A shared link is a contract"),
        ("13 a11y", "native element before any ARIA? Is focus owned rather than assumed?"),
    ):
        r.by_hand(rule, question)

    return r


def sample(items: list[str], limit: int = 4) -> str:
    shown = ", ".join(items[:limit])
    return shown + (f" (+{len(items) - limit})" if len(items) > limit else "")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--path", type=Path, default=Path.cwd(), help="project root to audit")
    args = parser.parse_args()

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    root = args.path.resolve()
    if not root.is_dir():
        print(f"Not a directory: {root}")
        return 1

    r = audit(root)
    print(f"\n{root}\n")

    for line in r.ok:
        print(f"OK       {line}")
    if r.ok:
        print()
    for line in r.missing:
        print(f"MISSING  {line}")
    if r.missing:
        print()
    for line in r.manual:
        print(f"BY HAND  {line}")

    print()
    if r.missing:
        print(f"{len(r.missing)} missing, {len(r.manual)} to check by hand, {len(r.ok)} in place.")
        return 1
    print(f"Nothing checkable is missing. {len(r.manual)} still need a human; that is not a pass, that is the list.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
