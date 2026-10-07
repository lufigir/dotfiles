---
name: research
description: >
  Research of any kind: picks the source for the question, from the open web and library
  behaviour to scholarly literature through the UNAL library subscriptions (Scopus, Web of
  Science, IEEE Xplore, ScienceDirect and ~170 more) in the user's own Brave. Use whenever a
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

The user works across university, a job and personal projects, and research serves all three.
You choose the sources yourself: the user sees the plan, not a menu. Research runs in three steps.

## 1. Plan

1. **Find the work's corpus.** A project, course or thesis often already holds sources: a
   NotebookLM notebook named in its `README` or notes, a `referencias.md`, docs, ADRs, earlier
   research notes. Read or query it first, because what was decided or said in class for that
   work outranks the general literature, and it tells you what is already known so the search
   adds rather than repeats.
2. **Split the question into angles** (the options, their failure modes, the evidence, the local
   context…) and give each angle the source that answers it, from the routing table below.
3. **Set the depth by stakes**, from the depth table.
4. **Announce the plan** in two or three lines (angle → source, and the rows left out with the
   reason) and start at once; the user corrects course while you work.

**Done:** every angle has a source, the corpus was checked or found absent, and the plan names
what it leaves out.

### Routing

| The angle | Go to |
|---|---|
| How a library, API or framework is used, in the installed version | Context7, through Executor |
| Whether it actually works: bugs, regressions, what people found | `firecrawl_developer_search` |
| Anything on the open web: products, pricing, news, docs, comparisons | `firecrawl_search`, then `firecrawl_scrape` on the pages that matter |
| A synthesis across many sites that can wait minutes | `firecrawl_agent` |
| What a PDF or document says | `firecrawl_parse` (open or user-supplied files only) |
| Open scientific literature (arXiv, PubMed, bioRxiv) | `firecrawl_research_*` |
| Indexed literature: journals, conferences, citation counts, quartiles | Scopus in Brave, then **follow the venues** (below) |
| Computing papers (ACM, IEEE conferences and journals) | ACM Digital Library (open access since 2026-01-01) and IEEE Xplore through the proxy |
| Latin American or Spanish-language literature, a contextual gap | SciELO, Redalyc, Dialnet, LA Referencia |
| Theses, patents, standards, Colombian data and regulation | The matching base in [`references/bases-unal.md`](references/bases-unal.md) |
| What a known set of sources says | NotebookLM `notebook_query` on the notebook that holds them |
| A quick first map of a topic, to import as sources | NotebookLM `research_start` (`fast` ~10 sources, `deep` ~40), then `research_import` |

Firecrawl and Context7 run through Executor (`mcp__executor__execute`); the `mcp-integrations`
skill says which account to use. NotebookLM is its own MCP (`mcp__notebooklm-mcp__*`); when its
tools are missing, ask the user to enable it with `/mcp`.

**Follow the venues.** An index answers "what exists"; the venues answer "where this field
talks". After the first Scopus run, open the *Source title* filter: the conferences and journals
that dominate are the field's venues. Search each one's own library (ACM DL, IEEE Xplore,
Springer, the society's site), because a venue's library holds work the index misses and the
full text the index lacks. Add SciELO or Redalyc whenever the claim is about Latin America,
Colombia, or work published in Spanish or Portuguese.

### Depth

| Stakes | Coverage |
|---|---|
| A quick answer, for the user alone | One source per angle: the one that answers it |
| A decision: a tool, an architecture, a purchase, a plan at work | The web for the options, `developer_search` for their failure modes, scholarly work when the choice has been studied; two independent sources behind every decisive claim |
| A deliverable others judge: thesis, paper, proposal, report, a document for the team | The corpus first; an index plus the field's venue libraries, plus the regional bases when the context matters; the full text of every work the argument rests on; [`references/literature-review.md`](references/literature-review.md) |

## 2. Search and read

The three surfaces are complements, each best at one job:

- **UNAL library** (Brave): *finding and vouching*. It decides which scholarly works exist, how
  cited they are and whether their journal counts, and it opens paywalled full text.
- **Firecrawl**: *reading and reaching the open world*. Web pages, open papers, PDFs, developer
  reality, long syntheses. Its scholarly index stops at arXiv and PubMed.
- **NotebookLM**: *holding a corpus and answering from it*, with citations. Its own discovery
  (`research_start`) is a web search, so a scholarly claim found there is still verified in the
  index.

For substantial work they chain: **discover** in the index and the venue libraries, **read**
open works with Firecrawl and paywalled ones in Brave, **hold** the corpus in NotebookLM when it
will be queried again over weeks (open-access papers by URL, the user's documents, the review
matrix as text). Licensed PDFs stay out of NotebookLM and every other service: they are licensed
for reading, and their abstract and matrix row carry what the notebook needs.

A finding rests on what you read. An abstract supports "this work exists and studies X"; a claim
about a work's method or result needs its full text.

**Done:** every angle in the plan was searched at its depth, and every work the answer leans on
was read at the level its claim needs.

## 3. Report

Name the sources used per angle, the rows left out and why, and what remains open (unread full
texts, unsearched bases). When the work has a notes or references file, the findings and the
search log go there, so the next session starts from them.

## The UNAL library in Brave

The user is a UNAL student, and the `brave` MCP (`mcp__brave__*`) drives their real Brave, where
they are already signed in.

### Access

- Start with `list_pages`, then work in a tab you open with `new_page`; the user's tabs stay as
  they are.
- Subscribed bases live behind the proxy: the original host plus `.unalproxy.elogim.com`, dots
  kept (`scopus.unalproxy.elogim.com`, `ieeexplore.unalproxy.elogim.com`,
  `webofscience.unalproxy.elogim.com`), and any path on the original site works on the proxied
  host. The catalog `https://bases.unal.edu.co` lists each base's entry link; read it there when
  a host is unknown. The `ezproxy.unal.edu.co/login?url=` form returns 404.
- How to drive each base (URLs, result selectors, quirks) is in
  [`references/bases-unal.md`](references/bases-unal.md#driving-the-bases).
- A login page means the session expired: the proxy's own (`unalproxy.elogim.com/auth-meta/login.php`)
  or a publisher's, as Scopus sending to Elsevier's sign-in (a personal Elsevier ID, which the user
  has had since 2026-10-06; it mails a one-time code). Ask the user to sign in in Brave, and
  meanwhile keep going on the open indexes (OpenAlex for discovery), saying which base is pending.
  Credentials stay with the user.
- No `mcp__brave__*` tools means Remote Debugging is off: tell the user to switch it on at
  `brave://inspect/#remote-debugging` and restart Claude Code. Until then, research with
  Firecrawl and the open libraries (ACM DL, SciELO, OpenAlex), and say which indexes that leaves
  out.

### Licensed use

Elsevier and the other publishers reserve text and data mining and AI training. Work the way a
person at the keyboard does: run a search, read the result list and the records the task needs,
open the papers you will actually read. When a task needs hundreds of records (a systematic
review, a bibliometric map), the user runs the base's **Export** (CSV or RIS) and hands you the
file.

### Scopus

Advanced search takes field codes, which make a search reproducible:

```
TITLE-ABS-KEY(("technical debt" OR "code smell*") AND ("large language model*" OR LLM))
AND PUBYEAR > 2020 AND (LIMIT-TO(DOCTYPE, "ar") OR LIMIT-TO(DOCTYPE, "cp"))
```

- Aim for a set you can screen (50–250). Widen with synonyms joined by `OR` inside a concept;
  narrow with another concept, a year range, a subject area or `AFFILCOUNTRY(...)`.
- Sort by citations for the foundations, by date for the current work.
- Record authors, year, title, source, DOI and citation count from the record itself.

Driving it from Brave:

- `https://scopus.unalproxy.elogim.com/results/results.uri?sort=cp-f&src=s&sot=a&s=<URL-encoded query>`
  runs an advanced search directly (`sort=cp-f` by citations, `plf-f` newest first).
- The list renders after navigation: wait until `table tbody tr` has rows. Each result is a row of
  six cells (number, title, authors, source, year, citations).
- The page offset persists across searches in a session. After paging, go back with the `1`
  button inside the pagination control; `offset` in the URL is ignored.
- The **Show all abstracts** button expands every abstract on the page, which is how to screen ten
  results in one read.
