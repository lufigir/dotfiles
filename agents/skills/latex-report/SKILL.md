---
name: latex-report
description: Write a new document as a LaTeX PDF in the house grayscale style (the Auditorita guide), in one of three tones (institucional, ejecutivo, académico): reports, proposals, architecture or formal documents for an institution, guides for a meeting, briefs for a professor or a team. Spanish triggers: "en latex", "pdf en latex", "hazme un pdf", "informe en pdf", "documento formal", "guía en pdf", "con el estilo de los otros pdf".
---

The house style is Pagella for the text, Heros in the diagrams, black ink with neutral grays,
numbered sections, booktabs tables and TikZ diagrams with gray boxes. Two templates carry it:
[`template.tex`](template.tex) (header block and «En resumen» box) and
[`template-formal.tex`](template-formal.tex) (title page and indices). [`build.py`](build.py)
compiles and renders previews.

1. **Frame.** Settle who reads it, what they must take away and what they are asked to decide or
   answer, and the sources the content comes from (repo docs, data, a conversation). Then ask the
   **tone** with the question selector, every time, offering the three from [`tonos.md`](tonos.md)
   (institucional, ejecutivo, académico) with your pick first, and read that tone's section.
   *Done:* you can name the reader, the ask, every source and the tone the user chose.
2. **Copy the tone's template.** Put it where the document belongs: `docs/<slug>/<slug>.tex` in a
   repo, the process folder in life-os, the scratchpad otherwise, or where the user says. Fill the
   title page or header block and the running header.
   *Done:* `grep -n '<' <file>.tex` finds no placeholder left.
3. **Write.** Follow the tone and the conventions below, and run the prose through the `humanize`
   skill before building.
4. **Build and look.** Run `PYTHONUTF8=1 python "<skill dir>/build.py" <file>.tex --preview <scratchpad>`.
   Fix every error and Overfull it prints, then Read every page and fix what you see: a heading
   alone at the foot of a page (raise its `\needspace`), a title hyphenated mid-word (break the
   line with `\\`), a number split across lines (`\mbox{2043 08-10-2026}`), diagram labels over the
   boxes (widen `node distance`) or under a `\paso` circle (drop the circles when the arrows carry
   labels), a word hyphenated inside a diagram box (widen its `text width`), an empty box where a
   character should be (the font lacks that glyph: write it out), a figure far from the text that
   cites it. For more than six pages, paste the pages into contact sheets of six and
   read those.
   *Done:* the build prints `OK` and every page was inspected after the last build.
5. **Review what it says.** Read the body once more as its reader, against the Voice and Limits
   rules: every claim the sources support, nothing that hurts the document's purpose.
   *Done:* every sentence passes both rules.
6. **Deliver.** Give the PDF's full path. When the user asks for a copy on the Desktop, copy it
   to `[Environment]::GetFolderPath('Desktop')`. Leave the files uncommitted unless asked.

## Conventions

- **Voice.** Impersonal narrative with the Spanish *se* (pasiva refleja): «se construyó», «se
  midió», «se propone». The register is neutral and formal: each sentence states a fact, a
  figure or a proposal, and the reader draws the judgement. The document tells where the work
  stands to a reader who saw none of the steps: each result appears once, as it stands, and each
  heading names what its section holds («Elección del modelo»). Run-to-run comparisons, «Lo
  nuevo» and question headings belong to a log.
- **Limits.** Everything that falls short is reported, as a risk, a pending measurement or a
  practice to adopt, each with its treatment. A gap reads as a plain fact («Sin base de datos
  independiente»), and a third party's terms are described by what they offer («sin respaldos ni
  garantías de disponibilidad»).
- **Tables** carry booktabs rules, bold headers and `@{}` at both ends; the first column bold and
  ragged when it names the row; `tabularx` with `Y` columns for text that wraps. In `template.tex`
  they sit in a `center` block; in `template-formal.tex` in a `table` float with a `\caption`.
- **Figures** are TikZ with the template's styles (`caja`, `clave`, `persona`, `externo`, `datos`,
  `flecha`, `nota`) and a caption that says what to see. Scale a wide diagram with
  `\resizebox{\linewidth}{!}{...}`.
- **Page breaks.** Put `\needspace{N\baselineskip}` before a section that opens with a table or
  a figure, with N about the height of that block; in the formal template floats go `[H]`.
- **Spanish typesetting.** Numbers as `1.474`, `82\,\%`, `0,4~h`; quotes «»; dates written out.
- **Gray only.** Every color comes from the tokens `tinta`, `marino`, `gris`, `linea`, `fondo`
  (shades like `gris!55` included). The `\recuadro{title}{body}` box is for the summary or a
  decision the reader must not miss.
