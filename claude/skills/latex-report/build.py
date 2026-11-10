"""Compila un .tex con Tectonic y deja hojas de vista previa para revisarlo.

Uso: python build.py <archivo.tex> [--preview <carpeta>]

- Busca tectonic en el PATH y en %LOCALAPPDATA%/Programs/tectonic; si no está, baja el
  último release oficial de GitHub ahí (Windows; en otro sistema, instálalo a mano).
- Imprime los errores y los Overfull \\hbox (texto que se sale del margen).
- Renderiza las páginas en hojas de 4 (preview-1.png, ...) con PyMuPDF, para mirarlas.
"""

import argparse
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

LOCAL = Path(os.environ.get("LOCALAPPDATA", Path.home())) / "Programs" / "tectonic"


def find_tectonic() -> str:
    found = shutil.which("tectonic")
    if found:
        return found
    exe = LOCAL / ("tectonic.exe" if os.name == "nt" else "tectonic")
    if exe.exists():
        return str(exe)
    if os.name != "nt":
        sys.exit("tectonic no está instalado: https://tectonic-typesetting.github.io")
    print("Instalando Tectonic en", LOCAL, file=sys.stderr)
    api = "https://api.github.com/repos/tectonic-typesetting/tectonic/releases/latest"
    with urllib.request.urlopen(api) as r:
        release = json.load(r)
    asset = next(a for a in release["assets"] if a["name"].endswith("x86_64-pc-windows-msvc.zip"))
    with urllib.request.urlopen(asset["browser_download_url"]) as r:
        zipfile.ZipFile(io.BytesIO(r.read())).extractall(LOCAL)
    return str(exe)


def compile_tex(tex: Path) -> Path:
    run = subprocess.run(
        [find_tectonic(), tex.name],
        cwd=tex.parent,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    out = run.stdout + run.stderr
    issues = [l for l in out.splitlines() if "error" in l.lower() and "Fontconfig" not in l]
    issues += sorted({l for l in out.splitlines() if "Overfull" in l})
    for line in issues:
        print(line)
    if run.returncode != 0:
        sys.exit(f"Falló la compilación (código {run.returncode}).")
    print("OK sin errores ni desbordes." if not issues else f"{len(issues)} avisos arriba.")
    return tex.with_suffix(".pdf")


def preview(pdf: Path, folder: Path) -> None:
    try:
        import pymupdf
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "-q", "pymupdf"], check=True)
        import pymupdf
    folder.mkdir(parents=True, exist_ok=True)
    doc = pymupdf.open(pdf)
    w, h = 595, 842
    for n, start in enumerate(range(0, doc.page_count, 4), 1):
        sheet = pymupdf.open()
        page = sheet.new_page(width=2 * w, height=2 * h)
        for k, i in enumerate(range(start, min(start + 4, doc.page_count))):
            rect = pymupdf.Rect((k % 2) * w, (k // 2) * h, (k % 2 + 1) * w, (k // 2 + 1) * h)
            page.show_pdf_page(rect, doc, i)
        target = folder / f"preview-{n}.png"
        page.get_pixmap(dpi=60).save(target)
        print(target)
    print(f"{doc.page_count} páginas.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("tex", type=Path)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    tex = args.tex.resolve()
    pdf = compile_tex(tex)
    folder = args.preview or Path(tempfile.gettempdir()) / f"latex-preview-{tex.stem}"
    preview(pdf, folder)


if __name__ == "__main__":
    main()
