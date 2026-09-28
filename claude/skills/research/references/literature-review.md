# Literature review

For a state of the art or a reference list that others will read, review or build on: a paper,
a thesis, a proposal, a technical report, a decision document. Each step
ends when its criterion holds.

## 1. Concepts

Split the research question into its two or three concepts, and give each its synonyms in English
(indexed journals) and in Spanish (Latin American bases). **Done:** every concept has a synonym
list and a reason it belongs to the question.

## 2. Search equations

One equation per angle of the question, in the base's own syntax (the Scopus form is in
`SKILL.md`): synonyms joined by `OR` inside a concept, concepts joined by `AND`, phrases in quotes,
`*` for word endings. Keep the **recency window** to the last five years unless the question is
historical. Log each run as base, equation, date and result count, because that log is what makes
the search reproducible and what a knowledge-gap claim rests on. **Done:** each equation returns a
set you can screen (50–250) and is logged.

## 3. Screening

Read titles and abstracts against inclusion criteria written before reading (topic, population or
context, study type, window). Works older than the window stay only when they are foundational
(the paper that defined a metric or a concept) and the text says so. **Done:** every result is
kept or dropped, with the criterion that decided it.

## 4. The matrix

Each kept work becomes a row of the review matrix, kept in the repo of the work it serves, one file
per document (for example `referencias.md` beside it):

| Autor/año | Contexto | Problema | Método | Resultados | Limitaciones | Aporte a este trabajo |
|---|---|---|---|---|---|---|

Add the DOI or identifier and where it was verified. **Done:** every work cited in the deliverable
has a row, and every row is either cited or marked as background.

## 5. The gap

State the knowledge gap by type (empirical, theoretical, methodological, contextual, population,
explanatory) and anchor it to the search log: "in Scopus and SciELO, 2021–2026, we found no study
that…". That wording survives a reviewer who knows one counterexample; an absolute claim that
nobody has studied the topic does not. **Done:** each gap names its type and the searches behind
it.

## 6. Citation checks

Every citation passes three checks before the deliverable ships:

- **Faithful**: the source says what the sentence attributes to it. Read at least the abstract,
  and the relevant passage when the claim is specific. A source cited as holding the view your
  finding refutes may turn out to report that same finding, and a reviewer who knows it reads
  the misquote as not having read the paper.
- **Complete**: every in-text citation has a reference entry and every entry is cited. Check this
  again after any cut made to fit a page limit.
- **Styled**: the format the venue asks for (a journal's style, APA, IEEE, or ICONTEC NTC 1486
  in many Colombian institutions), and any required ratio, such as a minimum share of references
  in English.

**Done:** all three hold for every reference.
