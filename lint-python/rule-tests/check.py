"""¿Las fronteras siguen mordiendo? El banco del preset de Python.

Igual que `lint/rule-tests/check.mjs`: `fixtures/` es código que DEBE fallar. Cada
línea marcada `BROKEN:` tiene que salir como el primer salto de un contrato roto, y
cada `CLEAN:` no puede salir. Además arma un árbol con demasiados archivos y exige que
`.ls-lint.yml` lo rechace.

    uv run --with import-linter python rule-tests/check.py

Monta un proyecto en un temporal porque import-linter importa el paquete raíz: lo
que prueba es el `pyproject.toml` en la raíz con `src/` al lado, como en un proyecto.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
FIXTURES = HERE / "fixtures"


def find_root() -> Path:
    """La raíz es donde vive el `pyproject.toml` con los contratos, y se busca subiendo.

    Así el mismo archivo funciona dentro del preset en dotfiles y copiado en un proyecto
    bajo `tools/lint-python/rule-tests/`.
    """
    for directory in HERE.parents:
        config = directory / "pyproject.toml"
        if config.is_file() and "[tool.importlinter]" in config.read_text(encoding="utf-8"):
            return directory
    sys.exit(f"No pyproject.toml with [tool.importlinter] above {HERE}.")


ROOT = find_root()

# Primer salto de una cadena: `- app.api.routes -> app.capabilities.llm (l.1)`. Las
# líneas siguientes de una cadena indirecta no empiezan con guion y no cuentan.
FIRST_HOP = re.compile(r"^-\s+(\S+) -> (\S+) \(l\.(\d+)\)", re.MULTILINE)

# [carpeta, archivos que se generan, ¿debe fallar?]
STRUCTURE = [
    ("src/app/domain", [f"rule_{i}.py" for i in range(10)], True),
]


def module_of(path: Path) -> str:
    return ".".join(path.relative_to(FIXTURES / "src").with_suffix("").parts)


def marked(tag: str) -> set[tuple[str, int]]:
    found = set()
    for path in FIXTURES.rglob("*.py"):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if f"# {tag}:" in line:
                found.add((module_of(path), number))
    return found


def run(command: list[str], cwd: Path, env: dict[str, str] | None = None) -> str:
    done = subprocess.run(
        command, cwd=cwd, env=env, capture_output=True, text=True, encoding="utf-8"
    )
    return f"{done.stdout}\n{done.stderr}"


def ls_lint() -> list[str]:
    binary = shutil.which("ls-lint")
    if binary:
        return [binary]
    npx = shutil.which("npx")
    if npx:
        return [npx, "-y", "@ls-lint/ls-lint@2.3.2"]
    sys.exit(
        "ls-lint is not installed and npx is not on PATH: the structure rules were never checked."
    )


def main() -> int:
    linter = shutil.which("lint-imports")
    if linter is None:
        sys.exit(
            "lint-imports is not on PATH. Run:"
            " uv run --with import-linter python rule-tests/check.py"
        )

    failures: list[str] = []
    with tempfile.TemporaryDirectory(prefix="lint-python-") as tmp:
        stage = Path(tmp)
        shutil.copy(ROOT / "pyproject.toml", stage)
        shutil.copy(ROOT / ".ls-lint.yml", stage)
        shutil.copytree(FIXTURES / "src", stage / "src")

        env = {**os.environ, "PYTHONPATH": str(stage / "src"), "PYTHONUTF8": "1"}
        output = run([linter, "--no-cache"], stage, env)
        hops = {(m.group(1), int(m.group(3))) for m in FIRST_HOP.finditer(output)}

        for module, line in sorted(marked("BROKEN") - hops):
            failures.append(f"{module}:{line} is marked BROKEN and no contract reported it.")
        for module, line in sorted(marked("CLEAN") & hops):
            failures.append(f"{module}:{line} is marked CLEAN and a contract reported it.")

        # La estructura: primero el árbol de fixtures tal cual, que debe pasar entero
        # (los `__init__.py` incluidos); después, con las carpetas que deben caer.
        clean = run(ls_lint(), stage)
        if " failed for " in clean:
            failures.append(f"the fixture tree must pass .ls-lint.yml as it is:\n{clean.strip()}")

        for directory, names, _ in STRUCTURE:
            for name in names:
                (stage / directory / name).write_text("", encoding="utf-8")
        crowded = run(ls_lint(), stage)
        for directory, _, must_fail in STRUCTURE:
            reported = f"{directory} failed for" in crowded
            if must_fail and not reported:
                failures.append(
                    f"{directory}: expected an `exists` failure from .ls-lint.yml, got nothing."
                )

    if failures:
        print(f"\nRules stopped biting ({len(failures)}):\n")
        for failure in failures:
            print(f"  - {failure}")
        print("\nDo not edit `fixtures/` to make this pass: fix the contracts or the config.\n")
        return 1

    print(
        f"{len(marked('BROKEN'))} broken imports caught, "
        f"{len(marked('CLEAN'))} clean ones left alone, "
        f"{len(STRUCTURE)} structure case bites."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
