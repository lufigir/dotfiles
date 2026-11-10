---
name: latex-report
description: Write a new document as a LaTeX PDF in the house grayscale style (the Auditorita guide): reports, proposals, guides for a meeting, briefs for a professor or a team. Spanish triggers: "en latex", "pdf en latex", "hazme un pdf", "informe en pdf", "guía en pdf", "con el estilo de los otros pdf".
---

The style lives in [`template.tex`](template.tex): Pagella for the text, Heros in the diagrams,
black ink with neutral grays, a header block instead of a title page, an «En resumen» box, numbered
sections, booktabs tables and TikZ diagrams with gray boxes. [`build.py`](build.py) compiles and
renders previews.

1. **Frame.** Settle who reads it, what they must take away and what they are asked to decide or
   answer, and the sources the content comes from (repo docs, data, a conversation). If the reader
   is unclear, ask with `AskUserQuestion`: the reader decides the register and how much technical
   detail stays in the body.
   A reader who decides gets a **brief**: two pages at most, ordered as summary box, findings,
   proposal, and the questions they must answer, each finding a bold claim plus its figure. The
   tables, sources and method go into a separate `<slug>-completo.tex` the brief points to, only
   when the user wants that detail kept.
   *Done:* you can name the reader, the ask, every source, and whether it is a brief.
2. **Copy the template.** Put it where the document belongs: `docs/<slug>/<slug>.tex` in a repo,
   the scratchpad outside one, or where the user says. Fill the header block and the running
   header.
   *Done:* `grep -n '<' <file>.tex` finds no placeholder left.
3. **Write.** Follow the conventions below, and run the prose through the `humanize` skill
   before building.
4. **Build and look.** Run `PYTHONUTF8=1 python "<skill dir>/build.py" <file>.tex --preview <scratchpad>`.
   Fix every error and Overfull it prints, then Read every preview sheet and fix what you see:
   a heading alone at the foot of a page (raise its `\needspace`), a title hyphenated mid-word
   (break the line with `\\`), a number split across lines (`\mbox{2043 08-10-2026}`), diagram
   labels over the boxes (widen `node distance`) or under a `\paso` circle (drop the circles
   when the arrows carry labels), a figure far from the text that cites it.
   *Done:* the build prints `OK` and every sheet was inspected after the last build.
5. **Deliver.** Give the PDF's full path. When the user asks for a copy on the Desktop, copy it
   to `[Environment]::GetFolderPath('Desktop')`. Leave the files uncommitted unless asked.

## Conventions

- **Order.** Header block, «En resumen» (three or four labeled bullets, the last one says what is
  asked of the reader), the sections, and for a non-technical reader an `\appendix` with the
  technical detail, then a `Referencias` list with full `\url{}`s.
- **Tables** go in a `center` block without a caption, with booktabs rules, bold headers and
  `@{}` at both ends; the first column bold when it names the row. `tabularx` with `Y` columns
  for text that wraps.
- **Figures** are TikZ with the template's styles (`caja`, `clave`, `flecha`, `paso`, `nota`) and
  a caption that says what to see. Scale a wide diagram with `\resizebox{\linewidth}{!}{...}`.
- **Page breaks.** Put `\needspace{N\baselineskip}` before a section that opens with a table or
  a figure, with N about the height of that block.
- **Spanish typesetting.** Numbers as `1.474`, `82\,\%`, `0,4~h`; quotes «»; dates written out.
- **Gray only.** Every color comes from the tokens `tinta`, `marino`, `gris`, `linea`, `fondo`
  (shades like `gris!55` included). The `\recuadro{title}{body}` box is for the summary or a
  decision the reader must not miss.
