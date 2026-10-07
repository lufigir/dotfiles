# UNAL bases by question

A working subset of the 177 resources at `https://bases.unal.edu.co` (count of 2026-10-06): the ones
worth knowing first for software, information systems, engineering, business and product work. The
catalog covers every other field too (health, law, agriculture, arts, sciences). Each entry opens from
that catalog through the proxy. The catalog is the source of truth: when a question falls outside these
lists, look there before concluding the library has nothing.

The catalog is a filterable directory (area, access type, format, resource type, and sede → facultad →
programa). The page loads the whole directory as one JSON file, `…/BasesUnal/Data/resources.json`,
whose path carries a build hash: read it from the page's network entries
(`performance.getEntriesByType('resource')` in Brave), then fetch it. Each record has `title`, `url`
(the proxied entry link), `access` and `tags`, so a whole-catalog question is one fetch instead of
paging through cards.

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
| **OpenAlex**, **Lens**, **Semantic Scholar**, **BASE**, **CORE** | Open indexes: a second opinion on coverage, policy documents, and open-access copies of paywalled papers. OpenAlex is also the fallback index when Scopus is unreachable (see [Driving the bases](#driving-the-bases)) |
| **Dimensions** | Grants, patents and policy documents linked to papers; subscribed, through the proxy |
| **Aluna** | The portal's single search point (Primo VE): the library's own catalog, print books and theses included, plus its subscriptions. The only place many UNAL theses appear |
| **Descubridor (EDS)** | One search across the EBSCO-hosted subscriptions |

## Full text by field

| Field | Bases |
|---|---|
| Computing, engineering | **IEEE Xplore** (also its Publication Recommender), **ScienceDirect**, **Springer Nature Link**, **SPIE**, **IET** |
| Information systems, management, business | **Emerald Insight**, **Taylor & Francis**, **Wiley Online Library**, **Sage Journals**, **Business Source Complete**, **EconLit** |
| Information science, open data, libraries | **Library, Information Science & Technology Abstracts (LISTA)** |
| Broad or cross-field | **Academic Search Ultimate**, **Annual Reviews** (reviews that map a field fast), **JSTOR**, **Cambridge**, **Oxford Academic**, **Nature** |
| Education, computing education | **ERIC** (open index of education research) |
| Research design and methods | **Sage Research Methods**: guides to designs, sampling, instruments and analysis, quantitative and qualitative |

The **ACM Digital Library** is not in the catalog and needs no proxy: since 2026-01-01 its whole
corpus is open access (`https://dl.acm.org`), so its papers read with Firecrawl.

## Latin America and Colombia

For the local context and the contextual gap: **SciELO**, **Redalyc**, **Dialnet**, **REDIB**,
**Latindex** (journal directory), **CEPAL repository** (policy and economic reports),
**Repositorio Institucional UNAL** and **Portal de Revistas UNAL**.

## Theses

**Open Dissertations (EBSCO)** for worldwide theses, **LA Referencia** for Latin American ones,
**Repositorio Institucional UNAL** for UNAL's own. The repository holds what was deposited
digitally, mostly postgraduate work; undergraduate theses often sit only in **Aluna** as print
records (in 2026-10 the repository's ASI undergraduate collection was empty while Aluna listed its
2004–2007 theses). Search both before saying a program has no theses on a topic.

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
Legal de Bogotá**, **Tirant Prime** (Latin American legal doctrine and case law). Open-data catalogs
such as `datos.gov.co` sit outside the library and are read through their own APIs.

## A paper the library does not have

**Obtención de documentos** gets an article or chapter from another sede or institution: email the
sede's address (Manizales: `conmuta_man@unal.edu.co`) with name, ID number, program, sede and the
full reference with DOI. The user sends it; draft the email for them. Interlibrary loan agreements
for print (Uniandes, Javeriana, Externado and others) are listed under *Convenios y redes* on
`bibliotecas.unal.edu.co`.

## Tools

- **Tree of Science (ToS)**: builds a tree of a field (roots are the classics, the trunk the
  structural works, the leaves the current ones) from a **Web of Science** export. Useful to pick
  foundational and recent references at once.
- **Zotero**, **Mendeley**, **EndNote Online**: reference managers. They take the RIS export
  straight from Scopus or WoS.
- **Journal Finder (Elsevier, DOAJ)**, **JCR**: choosing where to publish.
- **APC agreements finder** (`https://bibliotecas.unal.edu.co/APC/index.php`): the 7,008 journals
  (2026) of the eight publishers whose article processing charge UNAL covers in part or in full,
  filterable by quartile, Publindex, access type and 100 % coverage. Check it before recommending
  an open-access venue to a UNAL author.

## Driving the bases

Scopus is in `SKILL.md`. For the others, what worked on 2026-09-27 (2026-10-06 where marked):

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
- **Aluna** (Brave, open; 2026-10-06): `aluna.unal.edu.co` redirects to the Primo NDE interface,
  `https://aluna.unal.edu.co/nde/search?vid=57UNDC_INST:57UNDC_INST_V1&tab=LibraryCatalog&search_scope=MyInstitution&sortby=date_d&query=<words>`.
  The page renders slowly; its JSON API is faster from inside the Aluna tab: get a guest token from
  `/primaws/rest/pub/institution/57UNDC_INST/guestJwt?isGuest=true&lang=es&viewId=57UNDC_INST:57UNDC_INST_V1`,
  then call `/primaws/rest/pub/pnxs?inst=57UNDC_INST&vid=57UNDC_INST:57UNDC_INST_V1&tab=LibraryCatalog&scope=MyInstitution&q=any,contains,<words>&qInclude=facet_rtype,exact,dissertations&sort=date_d&limit=50&offset=0`
  with `Authorization: Bearer <token>`. Each `docs[].pnx.display` carries title, creationdate,
  contributor (director included) and format (pages). `qInclude` filters by resource type
  (`dissertations` for theses) and by year (`facet_searchcreationdate,exact,[2015 TO 2026]`,
  several joined with `|,|`).
- **Repositorio Institucional UNAL** (open; 2026-10-06): the UI host serves only the Angular app;
  the DSpace 7 REST API lives at `https://bffrepositorio.unal.edu.co/server/api` and answers
  `curl` with JSON. Search with
  `/discover/search/objects?query=<words>&dsoType=ITEM&size=100&sort=dc.date.issued,DESC`; restrict to one
  program with `scope=<collection uuid>` (find the uuid with `dsoType=COLLECTION&query=<sede or program>`).
  Each item's `metadata` carries `dc.title`, `dc.date.issued`, `dc.type` (*Trabajo de grado -
  Pregrado / Maestría*), `dc.contributor.advisor`, `dc.description.abstract` and
  `dc.format.extent` (pages).
- **OpenAlex** (open API, no key; 2026-10-06): boolean queries go in the filter
  `title_and_abstract.search:(<A> OR <B>) AND <C>`, not in `search=`, which ignores operators.
  Combine with `publication_year:>2022` and `sort=cited_by_count:desc`; add `mailto=<user email>`.
  Abstracts come as `abstract_inverted_index`, rebuilt by sorting words by position. Running the
  script with `python -I` ignores `PYTHONUTF8`, so pass `-X utf8` alongside `-I`.
- **Other universities' repositories** (Uniandes and similar): a bot challenge blocks Firecrawl
  and `curl`; open them in Brave, which passes it.
