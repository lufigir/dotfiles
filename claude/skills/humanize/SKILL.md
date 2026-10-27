---
name: humanize
description: >
  Humanize any text a person will read, in Spanish or English, so it reads as its author wrote it:
  university deliverables, docs, READMEs, skills, reports, PR and commit bodies, messages, emails,
  reviews and posts. Cuts AI tells while every claim, figure and citation survives, in a pasted
  text, a local file or a Google Doc through Brave, and checks the result against AI detectors
  when asked. Use when writing or editing any of them, and for a pass over a draft. Spanish
  triggers: "humaniza", "suena a IA", "quítale lo de IA", "pule la redacción", "revisa la
  redacción", "que no lo detecten".
---

# Humanize

A model writes the most probable next word, so its prose makes the choice that fits every reader
and every subject. A person writes for one reader about one thing, so their choices are uneven and
specific. Editing toward the second is the whole job: the text ends up clearer, more precise and
recognisably the author's.

Detectors and readers both catch the same thing: instruction-tuned prose is *flat*. Its sentences
have the same length and shape, its punctuation is reduced to periods and commas, its words are
long and abstract, its nouns outnumber its verbs, and its rhetoric (triads, staged contrasts,
performed hedging) is spread evenly over every paragraph. Swapping words leaves all of that in
place. Humanizing is restructuring: change where sentences break, what they subordinate, who acts
in them, and put the author's own stance back.

## Steps

1. **Read the frame.** Read the whole text once. Settle three things: the language, the genre
   (academic deliverable, technical doc, message or post) and the voice. The voice comes from the
   author's own writing when there is any: earlier texts, the parts of this one they wrote, how
   they write to you in this conversation. For a university deliverable, also read the assignment
   (the rubric, class notes or guide in the course folder: `<curso>/evaluaciones/`, `parciales/`,
   a `README`); any section, label or order the rubric asks for is structure, never a tell.
   *Done:* you can name the language, the genre, the reader, and the voice (person, register,
   punctuation habits, how they cite).
2. **Mark the tells.** Walk the catalogue for the language top to bottom against the text:
   [`references/patrones.md`](references/patrones.md) for Spanish,
   [`references/patterns.md`](references/patterns.md) for English. Mark each sighting with its
   section and a one-line reason. A pattern marked *weak alone* / *débil sola* needs company in
   the same paragraph; every other pattern justifies an edit on a single sighting. Then measure
   the rhythm: sentence lengths per paragraph, and how many paragraphs open the same way.
   *Done:* every section of the catalogue was checked against every paragraph of the text.
3. **Check the claims.** For each sentence that leans on a citation, a figure or a name, compare
   it with what the text says elsewhere about the same source or number: "igual que en Europa
   (Quarati, 2023)" contradicts a gap section that says Quarati never measured that. A mismatch
   is a content error and outranks every style tell. If a sentence needs a fact the text lacks (a
   name, a number, a date), ask; never invent it.
   *Done:* every comparative or attributive sentence ("como en", "igual que", "confirma",
   "according to", "shows that") checked against its source in the text.
4. **Rewrite.** Rebuild each marked sentence; a clean paragraph stays untouched.
   - Keep every fact, number, date, citation and reference entry exactly as written; add none.
   - Restructure, don't reword: move the break, merge two short sentences that share a subject,
     split a long one, turn a noun back into a verb with its subject, give an inanimate subject
     back to the person who acts.
   - Vary on purpose: one long sentence beside two short ones; a parenthesis, a semicolon or a
     colon where the author would use one; a question when the author would ask it. The
     catalogue's last section says which marks people use more than models.
   - Put the author back: their person, their asides, their real doubts, their opinion where the
     genre allows it. In messages and posts, the register the author actually uses (contractions
     in English, informal Spanish, short replies).
   *Done:* no marked tell survives, and no two neighbouring paragraphs share the same sentence
   rhythm.
5. **Apply.** By where the text lives:
   - *Pasted text:* return the final text.
   - *Local file:* edit only prose; leave tables, code, frontmatter, link targets, citations and
     the reference list as they are.
   - *Google Doc:* follow [Google Docs through Brave](#google-docs-through-brave).
6. **Check against detectors** when the user asks whether it will pass, or when the text goes
   somewhere that runs one (a course with Turnitin, a platform that screens posts). Follow
   [`references/detectores.md`](references/detectores.md).
   *Done:* the score of every detector run is reported, and every flagged passage was rewritten
   once more or explained.
7. **Report.** One entry per change: where, before, after, the pattern. Then what you left on
   purpose and why (rubric structure, a contrast that corrects a real alternative, a quotation),
   and the detector scores if step 6 ran.

## Genre

The catalogue applies to every text; the genre decides what the author's voice allows.

| Genre | Voice to rebuild | Keep |
|---|---|---|
| Academic deliverable (Spanish, usually *nosotros*) | Their asides, their stated doubts, the position they take on each source | The structure the rubric asks for; nominal objectives; citations as written |
| Technical doc, README, skill, PR, commit | Neutral and exact: name the mechanism, the command, the number | Headings, lists and code blocks that organise reference material |
| Message, email, review, post | The author's own register: contractions, short sentences, first person, opinion, a concrete detail only they would know | Greetings and sign-offs the author uses |

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

## Where the text stays as it is

- A pattern inside a quotation, a title, a proper name, code, or a passage that discusses the
  pattern.
- Structure the rubric or the genre requires: labelled dimensions (*Social. Técnica.
  Científica.*), the objective formula (*Evaluar… mediante… para…*), numbered hypotheses, a
  README's install steps.
- A contrast whose negative half corrects an option the reader actually weighs ("seguimos el
  método hipotético-deductivo y no el enfoque de la complejidad, porque…").
- Text the user wrote before November 30, 2022.

Several tells together are the signal; one tell is usually a person.

The edits stay in the writing: inserted typos, swapped or invisible characters and paraphrasing
tools degrade the text for its reader, and [`references/detectores.md`](references/detectores.md)
says why they don't buy what they promise.
