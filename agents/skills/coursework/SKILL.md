---
name: coursework
description: Work on one university course's assignments from that course's repo, with only that course in context. Reads the repo's README and rubric, pulls from Notion Pendientes just that course's open tasks, plans what is missing, and records the progress back in Notion. Spanish triggers: "avancemos en", "trabajemos en la evaluación", "qué me falta de <materia>", "sigamos con el trabajo de", "/coursework", "tarea".
---

# Coursework

One course, one sitting. The session stays on this course: no mail, no calendar, no other courses, nothing from the `life-os` repo beyond the priority rule cited below.

## 1. The course

The course is the repo the session runs in (a folder under `D:\Code`, such as `metodologia-investigacion`, or a course folder inside `semestre-2026-2`), or the one the user names. Read its README: teacher, evaluations with weights and dates, rubrics, the NotebookLM notebook if it lists one, and the folder of each evaluation.

## 2. Its tasks

Through Executor (skill `mcp-integrations`, Notion account `lufigir`):

1. Read the Universidad view of Pendientes in `view` mode: `https://app.notion.com/p/ce04a18452914a52a311e35741ddc404?v=40f23bce2002813783c7000c970075ef` (open university tasks). Use `view` mode only: `rows` and `sql` share a workspace quota that runs out within a session.
2. `notion_fetch` each distinct `Materia` URL in those rows to get its title, and keep the rows of the course whose title matches.
3. Order them by priority with the rule in `D:\Code\life-os\.claude\skills\life-review\SKILL.md` (section Pendientes): the MCP does not return the `Prioridad` formula, so compute it from `Gravedad` and the days left.

Show the list: name, when it is due, priority, state. If the user already named a task, confirm it is on the list; if it is not there, offer to create it (step 5).

## 3. What is missing

For the chosen task, compare what the rubric asks with what the repo already holds (its evaluation folder, drafts, `referencias.md`, data). When the README lists a NotebookLM notebook, query it for what was said in class about this evaluation before the general literature (skill `research`). Report the gap as a short ordered plan, each step with what it produces, and agree on it with the user.

**Done when** every rubric criterion maps to a step or to something already in the repo.

## 4. Work

Deliverables live in the course repo, in the evaluation's folder; a new one follows the existing names (`evaluacion-3-cualitativa/`). Prose that will be handed in goes through the `humanize` skill before it ships.

## 5. Close

Propose, and apply once approved:

- the task's `Estado` in Pendientes (`En progreso`, `Terminado` when ready but not handed in, `Hecho` once handed in);
- new pendientes for steps that came up and have their own date, with `Materia`, `Área` = Universidad, `Tipo`, `Gravedad` and `Fecha`. A step that waits on someone else (a teammate, the teacher) gets its own earlier date.

Offer a commit of the course repo when files changed.
