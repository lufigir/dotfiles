---
name: redaccion-academica
description: >
  Academic writing in Spanish: edit a university deliverable (informe, evaluación, propuesta,
  ensayo, artículo, ponencia, tesis) so it reads as its authors wrote it, cutting AI tells while
  every claim, figure and citation survives, in a pasted text, a local file or a Google Doc
  through Brave. Use when drafting or revising any course or thesis text in Spanish. Spanish
  triggers: "humaniza", "suena a IA", "quítale lo de IA", "pule la redacción", "revisa la
  redacción".
---

# Redacción académica

A model writes the most probable next word, so its prose makes the choice that fits every reader
and every subject. A student writes for one teacher about one dataset, so their choices are uneven
and specific. Editing toward the second is the whole job: the text ends up clearer, more precise
and recognisably the authors', and its authorship rests on the trail they already have (the Docs
version history, their scripts, their data).

Docs, READMEs, PRs and messages go to `unslop`; this skill owns university deliverables in Spanish.

## Steps

1. **Read the frame.** Read the whole text once, then the assignment: the rubric, the class notes
   or the guide in the course folder (`<curso>/evaluaciones/`, `parciales/`, a `README`). Any
   section, label or order the rubric asks for is structure, never a tell.
   *Done:* you can name what the rubric requires and the voice the authors use (person, register,
   how they cite).
2. **Mark the tells.** Walk [`references/patrones.md`](references/patrones.md) top to bottom
   against the text. Mark each sighting with its section and a one-line reason; §1 to §5 justify
   an edit on their own, a pattern marked *débil sola* needs company in the same paragraph.
   *Done:* every section of the catalogue was checked against every section of the text.
3. **Check the claims.** For each sentence that leans on a citation or a figure, compare it with
   what the text says elsewhere about the same source or number: "igual que en Europa (Quarati,
   2023)" contradicts a gap section that says Quarati never measured that. A mismatch is a content
   error and outranks every style tell.
   *Done:* every comparative or attributive sentence ("como en", "igual que", "confirma",
   "demuestra") checked against its source in the text.
4. **Rewrite.** State each point plainly. Keep every fact, number, date, citation and reference
   entry exactly as written; add none. Keep the authors' voice: their person (usually *nosotros*),
   their asides ("Lo que más nos llamó la atención"), their hedges that carry real doubt ("Hasta
   donde revisamos"). Change only the sentences you marked; a clean paragraph stays untouched.
5. **Apply.** By where the text lives:
   - *Pasted text:* return the changes and the final text.
   - *Local file:* edit only prose; leave tables, code, citations and the reference list as they are.
   - *Google Doc:* follow [Google Docs through Brave](#google-docs-through-brave).
6. **Report.** One entry per change: section, before, after, the pattern. Then what you left on
   purpose and why (rubric structure, a contrast that corrects a real alternative, a title).

## Google Docs through Brave

The doc is open in the user's Brave (`mcp__brave__list_pages`, then `select_page` on the
`docs.google.com/document` tab). Google Docs draws text on a canvas, so the DOM does not hold the
body and an in-page `fetch` of `/export?format=txt` fails; work through **Find and replace**.

1. Press `Control+h`, take a snapshot, note the uids of `Find`, `Replace with`, `Replace all`
   and `Close`.
2. Per change: `fill` Find with the exact old sentence, read the match counter in the dialog
   (`[role=dialog]` text, "1 of 1"), `fill` Replace with, click Replace all. A counter of "0 of 0"
   means the doc differs from your copy: ask for the current text before guessing.
3. Verify at the end: search each new sentence (expect one match) and each old one (expect none),
   then close the dialog. Every replacement is in the doc's undo history, so the user can revert
   one with Control+z.

Replace whole sentences or clauses, unique enough to match once. A replacement keeps the formatting
of the first matched character, so leave italics, links and citations outside the replaced span.

## When not to act

- A pattern inside a quotation, a title, a proper name or a passage that discusses the pattern.
- Structure the rubric or the genre requires: labelled dimensions (*Social. Técnica.
  Científica.*), the objective formula (*Evaluar… mediante… para…*), numbered hypotheses,
  nominal style in objectives.
- A contrast whose negative half corrects an option the reader actually weighs ("seguimos el
  método hipotético-deductivo y no el enfoque de la complejidad, porque…").
- Text the user wrote before November 30, 2022.

Several tells together are the signal; one tell is usually a person.

## Detectors

When the user asks whether a detector will flag the text, answer from
[`references/evidencia.md`](references/evidencia.md): what the published evaluations measured, and
that the answer to a false accusation is the authorship trail. Edits stay at the level of the
writing; tricks aimed at the detector (inserted typos, swapped characters, invisible spaces,
paraphrasing tools) degrade the text and are out of scope.
