---
name: research
description: >
  Research of any kind: picks the source for the question, from the open web and library
  behaviour to scholarly literature through the UNAL library subscriptions (Scopus, Web of
  Science, IEEE Xplore, ScienceDirect and ~130 more) in the user's own Brave. Use whenever a
  task needs finding something out before answering or building: comparing tools or options,
  checking a claim, a state of the art or literature review, references for a paper, thesis or
  course deliverable, recent studies, prior art and patents, technical standards, market or
  industry evidence, Colombian data or regulation, or what a notebook of sources says (Firecrawl,
  NotebookLM and the library, and when each fits). Spanish triggers: "investiga", "investigar",
  "averigua", "busca información", "compara", "estado del arte", "revisión de literatura",
  "antecedentes", "busca artículos", "busca papers", "referencias", "Scopus", "biblioteca",
  "patentes", "normas técnicas".
---

# Research

Research starts by naming what kind of question it is, because each kind has a source that
answers it and others that only look like they do.

| The question | Go to |
|---|---|
| How a library, API or framework is used, in the installed version | Context7, through Executor |
| Whether it actually works: bugs, regressions, what people found | `firecrawl_developer_search` |
| Anything on the open web: products, pricing, news, docs, comparisons | `firecrawl_search`, then `firecrawl_scrape` on the pages that matter |
| A synthesis across many sites that can wait minutes | `firecrawl_agent` |
| What a PDF or document says | `firecrawl_parse` (open or user-supplied files only) |
| Open scientific literature (arXiv, PubMed, bioRxiv) | `firecrawl_research_*` |
| Indexed literature: journals, conferences, citation counts, quartiles | **Scopus in Brave** (below) |
| Theses, Latin American journals, patents, standards, Colombian data and regulation | The matching UNAL base, from [`references/bases-unal.md`](references/bases-unal.md) |
| What a known set of sources says: a course's notes and recordings, a project's documents, the papers already chosen | NotebookLM `notebook_query` on the notebook that holds them |
| A quick first map of a topic, to import as sources | NotebookLM `research_start` (`fast` ~10 sources, `deep` ~40), then `research_import` |

A question often spans several rows: a technology choice for a project wants the web for the
options, `developer_search` for their failure modes, and Scopus when the choice has been studied.
The answer names its sources and says which rows were not searched.

## Three tools, three jobs

The three research surfaces are complements, and each is best at one job:

- **UNAL library** (Brave): *finding and vouching*. It decides which scholarly works exist on a
  question, how cited they are and whether their journal counts, and it opens paywalled full
  text. What it finds is authoritative; reaching it costs a live session and human-scale use.
- **Firecrawl**: *reading and reaching the open world*. Web pages, open papers, PDFs, developer
  reality, long syntheses. Fast and scriptable, but its scholarly index stops at arXiv and PubMed.
- **NotebookLM**: *holding a corpus and answering from it*. Once the sources are chosen, a
  notebook answers questions grounded in exactly those sources, with citations, and turns them
  into study material (audio, slides). Its own discovery (`research_start`) is a web search, so
  a scholarly claim found there is still verified in Scopus.

They chain in that order when the work is substantial:

1. **Discover** in Scopus (and the base that fits), screen, and keep the list in the review
   matrix.
2. **Read** open works with Firecrawl and paywalled ones in Brave; fill the matrix from what
   the sources say.
3. **Hold** the corpus in NotebookLM when it will be queried again over weeks (a thesis, a
   course, a long project): add the open-access papers by URL, the user's own documents and
   notes, and the matrix itself as text. Licensed PDFs stay out of it, because they are licensed
   for reading, not for feeding to another AI service; their abstract and your matrix row carry
   what the notebook needs.

A notebook already made for the work comes first: for a course or a project with one (its
`README` or the repo's docs name it), query it before searching outward, because what was said in
class or decided in the project outranks the general literature for that work. The NotebookLM
MCP is off by default (`/mcp` to switch it on), so ask the user to enable it when a step needs
it.

## Scholarly sources through the UNAL library

The user is a UNAL student, so the library's subscriptions are theirs to use, and the `brave`
MCP (`mcp__brave__*`) drives their real Brave, where they are already signed in. In information
systems, management and government, `firecrawl_research_*` misses most journals, while Scopus
finds them. Scholarly work is three moves:

| Move | Tool | Why |
|---|---|---|
| **Discover** | Scopus in Brave; Web of Science when Scopus is thin | Widest indexed coverage, citation counts, filters by year, type and area |
| **Read** | Open access: Firecrawl (`research_read_paper`, `scrape`, `parse`). Paywalled: the article page in Brave through the proxy | Licensed full text stays inside the licensed session |
| **Verify** | The Scopus record, the DOI, and Scimago or JCR for the journal's quartile | A reference is real, indexed and says what you cite it for |

### Access

- Start with `list_pages`: it shows the user's tabs and whether a proxied base is already
  open. Work in a tab you open with `new_page`, and leave the user's tabs as they are.
- Subscribed bases live behind the proxy, rewritten under `*.unalproxy.elogim.com`
  (Scopus is `https://scopus.unalproxy.elogim.com`). The catalog with each base's entry link is
  `https://bases.unal.edu.co`; a single article opens through
  `http://ezproxy.unal.edu.co/login?url=<article URL>`.
- A login page means the session expired: ask the user to sign in in Brave, then continue.
  Credentials stay with the user.
- No `mcp__brave__*` tools means Remote Debugging is off: tell the user to switch it on at
  `brave://inspect/#remote-debugging` and restart Claude Code. Until then, research with
  Firecrawl only and say which indexes that leaves out.

### Licensed use

Elsevier and the other publishers reserve text and data mining and AI training. Work the way a
person at the keyboard does: run a search, read the result list and the records the task
needs, open the papers you will actually read. When a task needs hundreds of records (a
systematic review, a bibliometric map), the user runs Scopus's **Export** (CSV or RIS) and hands
you the file. Licensed PDFs are read in Brave, never uploaded to Firecrawl, NotebookLM or any
other service.

### Discover in Scopus

Advanced search takes field codes, which make a search reproducible:

```
TITLE-ABS-KEY(("technical debt" OR "code smell*") AND ("large language model*" OR LLM))
AND PUBYEAR > 2020 AND (LIMIT-TO(DOCTYPE, "ar") OR LIMIT-TO(DOCTYPE, "cp"))
```

- Aim for a result set you can screen (50–250). Widen with synonyms joined by `OR` inside a
  concept; narrow with another concept joined by `AND`, a year range or a subject area.
- Sort by **Cited by** to find the foundations, by **Date** to find the current work.
- For each keeper, record authors, year, title, source, DOI and citation count straight from
  the record, so the reference list is built from what the index says.

## Literature reviews

When the output is a state of the art or a reference list (a paper, a thesis, a project
proposal, a report, a decision document), follow [`references/literature-review.md`](references/literature-review.md): search
equations, the recency window, the review matrix, how to state a knowledge gap, and the checks
every citation passes.
