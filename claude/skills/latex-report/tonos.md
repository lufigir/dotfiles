# Tones

Every document takes one tone, chosen by the user in step 1. Each tone fixes the template, the
structure and the register. The register rules in `SKILL.md` (Voice, Limits) hold for all three;
this file adds what is specific to each.

## Institucional

**Reader:** a dependency or an entity that receives the document and may file it: OTIC, a
Vicerrectoría, a Gerencia, a security office. Example: an architecture document of an app.

**Template:** [`template-formal.tex`](template-formal.tex), Pagella and Heros. Title page with the
institution's shield (the UNAL one is [`assets/escudo-unal.pdf`](assets/escudo-unal.pdf), copied
next to the `.tex`), sede, document type, title, subtitle, authors, city and month, and nothing
else: no metadata table, no version control, no signature box, no bands or rules across the
title. Then table of contents, list of figures and list of tables, and every
table and figure numbered with a `\caption` (short form in brackets when the caption runs past
one sentence, so the lists stay one line).

**Structure** for describing a system, after the DNP *Guía para la elaboración del diseño de
arquitectura para sistemas de información* (v2.1, 2026), ISO/IEC/IEEE 42010 and C4: introduction
(objeto, alcance, fuentes y fecha de corte, definiciones), antecedentes, interesados,
requerimientos and quality attributes, architecture decisions, views (contexto, lógica, datos,
desarrollo, procesos, física, escenarios), ambientes; then the evaluation of what exists: results,
security and personal data, normas y buenas prácticas, risks; then the proposal: target
architecture, with the plan for evaluating it; Referencias last. The order runs from what is, to
how it fares, to what is proposed. Other document kinds keep introduction, the sections the
content needs and Referencias. No technical annex: code-level detail lives in the repository,
which «Fuentes y fecha de corte» names.

**Register:**

- **Periods, one cut date.** Events go by period («segundo trimestre de 2026», «desde mediados de
  2026»); the measurements carry a single cut date stated once in «Fuentes y fecha de corte».
  Monthly data tables keep their month columns: they are data, not events.
- **General terms.** The text says «la regla de cobertura de riesgos laborales», «tareas
  programadas», «notificaciones de Gmail»; file paths, rule ids, routes and config keys stay in
  the repository. Nicknames of cases or people («caso sofia», «el caso de un compañero») never
  appear: the reader has no context for them.
- **The widest owner.** Name the institution as the owner of what the document proposes («las
  aplicaciones de la Universidad»), not the unit that commissioned it, unless the scope is that
  unit alone.
- **Decisions attributed to the body that took them**, paraphrased: «la Vicerrectoría definió que
  toda aprobación queda sujeta a decisión humana», without the meeting, its date or a verbatim
  quote.
- **Plain statements of fact.** A sentence reports what is, without grading it: «La aplicación no
  tiene base de datos, por lo que su traslado no requiere migrar datos», «El 92,5 % de las
  sugerencias de aprobar coincidió con la decisión». Bold labels name the item («Remitir.»), not a
  verdict about it.
- **The system as it runs.** The architecture describes what operates in production. A capability
  the code has but production does not use (a fallback chain, a disabled provider) stays out of
  the architecture and appears only where it was measured, such as a model comparison. Ask the
  user when the code and production may differ.
- **Standards as a reference frame.** Name the norms and guides that oriented the design in a
  short «Marco de referencia» list, each with the area it guided. Compliance verdicts («Cumple»,
  «Parcial») are an auditor's to give; what is missing goes in «Prácticas por incorporar» and
  in the risks.
- **Scope of what is said.** Each figure serves the document's purpose; amounts of a person,
  schedules of a person and the budget of a different project stay out.

## Ejecutivo

**Reader:** someone who decides and has little time. Example: the summary of a contract plan for a
supervisor.

**Template:** [`template.tex`](template.tex), header block instead of a title page.

**Structure:** two pages at most, ordered as «En resumen» box, findings, proposal, and the
questions the reader must answer. Each finding is a bold claim plus its figure. Tables, sources and
method go into a separate `<slug>-completo.tex` the brief points to, only when the user wants that
detail kept.

**Register:** the claim leads each paragraph; one number per claim; the last bullet of the summary
says what is asked of the reader.

## Académico

**Reader:** a professor or a jury. Example: a thesis proposal or a course report.

**Template:** [`template-formal.tex`](template-formal.tex) when the course asks for a title page,
[`template.tex`](template.tex) otherwise. The course's own rubric or format overrides both.

**Structure:** the one the course or the venue asks for (proposal, report, article); otherwise
introducción, marco teórico, método, resultados, discusión, conclusiones, referencias.

**Register:** in-text citations (Autor, año) with a reference list in the format the course asks
for, APA 7 by default; every claim about a work rests on a source in the list. The `research`
skill supplies and vouches for the sources.
