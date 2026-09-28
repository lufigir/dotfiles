# UNAL bases by question

A working subset of the ~130 resources at `https://bases.unal.edu.co`: the ones worth knowing first
for software, information systems, engineering, business and product work. The catalog covers every
other field too (health, law, agriculture, arts, sciences). Each entry opens from that catalog through the
proxy. The catalog is the source of truth: when a question falls outside these lists, look there
before concluding the library has nothing.

Access verified 2026-09-27: Scopus and IEEE Xplore through the proxy; ACM DL, SciELO and Redalyc
open. The rest are listed by the catalog and have not been opened yet; note in
[Driving the bases](#driving-the-bases) any that turns out to need something different.

## Discover and measure

| Base | Reach for it to |
|---|---|
| **Scopus** | Discover: the default index, with citations, filters and Export (CSV/RIS) |
| **Web of Science** | Discover where Scopus is thin; its export is what Tree of Science reads |
| **Journal Citation Reports (JCR)** / **InCites** | Journal impact and quartile (JCR); an institution's output (InCites) |
| **Scimago Journal & Country Rank** | Journal quartile from Scopus data; open, no proxy |
| **Dimensions**, **Lens**, **OpenAlex**, **Semantic Scholar**, **BASE** | Open indexes: a second opinion on coverage, grants, policy documents, and open-access copies of paywalled papers |
| **Descubridor (EDS)** | One search across the library's own subscriptions, books included |

## Full text by field

| Field | Bases |
|---|---|
| Computing, engineering | **IEEE Xplore** (also its Publication Recommender), **ScienceDirect**, **Springer Nature Link**, **SPIE**, **IET** |
| Information systems, management, business | **Emerald Insight**, **Taylor & Francis**, **Wiley Online Library**, **Sage Journals**, **Business Source Complete**, **EconLit** |
| Information science, open data, libraries | **Library, Information Science & Technology Abstracts (LISTA)** |
| Broad or cross-field | **Academic Search Ultimate**, **Annual Reviews** (reviews that map a field fast), **JSTOR**, **Cambridge**, **Oxford Academic**, **Nature** |
| Research design and methods | **Sage Research Methods**: guides to designs, sampling, instruments and analysis, quantitative and qualitative |

The **ACM Digital Library** is not in the catalog and needs no proxy: since 2026-01-01 its whole
corpus is open access (`https://dl.acm.org`), so its papers read with Firecrawl.

## Latin America and Colombia

For the local context and the contextual gap: **SciELO**, **Redalyc**, **Dialnet**, **REDIB**,
**Latindex** (journal directory), **CEPAL repository** (policy and economic reports),
**Repositorio Institucional UNAL** and **Portal de Revistas UNAL**.

## Theses

**Open Dissertations (EBSCO)** for worldwide theses, **LA Referencia** for Latin American ones,
**Repositorio Institucional UNAL** for UNAL's own.

## Prior art and patents

For a project, a product or an entrepreneurship idea: **Lens** (patents linked to scholarly
literature, open), **Espacenet** (worldwide, since 1836), **Latipat** (Latin America and Spain, in
Spanish and Portuguese), **Patentscope**, **USPTO** and the **SIC**'s industrial property office
(Colombian filings).

## Standards

**ASTM Compass** (full text). **E-Collection ICONTEC**: 2,900+ Colombian technical standards,
reachable only on the campus network and read-only, with no download.

## Colombian data and regulation

**DANE** (official statistics), **Juriscol / SUIN** (national regulation since 1886), **Régimen
Legal de Bogotá**. Open-data catalogs such as `datos.gov.co` sit outside the library and are read
through their own APIs.

## Tools

- **Tree of Science (ToS)**: builds a tree of a field (roots are the classics, the trunk the
  structural works, the leaves the current ones) from a **Web of Science** export. Useful to pick
  foundational and recent references at once.
- **Zotero**, **Mendeley**, **EndNote Online**: reference managers. They take the RIS export
  straight from Scopus or WoS.
- **Journal Finder (Elsevier, DOAJ)**, **JCR**: choosing where to publish.

## Driving the bases

Scopus is in `SKILL.md`. For the others, what worked on 2026-09-27:

- **IEEE Xplore** (Brave, proxy):
  `https://ieeexplore.unalproxy.elogim.com/search/searchresult.jsp?queryText=<query>&ranges=2019_2026_Year&sortType=paper-citations&rowsPerPage=50`.
  Field syntax is `"Abstract":term`, `"Document Title":term`, with `AND`/`OR` and `*`. Results
  render as `xpl-results-item` elements, each appearing twice in the DOM; the count is in the
  "Showing 1-N of M results" line.
- **ACM DL** (open, Firecrawl `firecrawl_scrape` to markdown):
  `https://dl.acm.org/action/doSearch?AllField=<query>&AfterYear=2019&sortBy=cited&pageSize=50`.
  Field syntax is `Title:(…)`, `Abstract:(…)`. Titles come as markdown links to
  `https://dl.acm.org/doi/<DOI>`, so the DOI comes with the hit. The Basic edition greys out the
  filters; recall is lower than Scopus for the same concepts, so it serves to confirm coverage and
  collect DOIs more than to discover.
- **SciELO** (Brave; Firecrawl gets only the facets):
  `https://search.scielo.org/?q=<query>&lang=es&count=50&from=0&output=site&format=summary&page=1`.
  Boolean operators work. Each hit is a `.item` element with the journal in `.source`.
- **Redalyc** (Brave): `https://www.redalyc.org/busquedaArticuloFiltros.oa?q=<words>` searches
  full text with no operators, so a topic query returns hundreds of thousands of hits. It serves
  to find a known title or a Colombian journal, not to screen a topic.
