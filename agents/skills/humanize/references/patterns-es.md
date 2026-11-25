# Patterns (Spanish)

Catalogue of AI writing tells in Spanish, for any text: academic, technical, messages and posts.
A pattern justifies an edit on a single sighting, except those marked *weak alone*, which need
other tells in the same paragraph. Sources for each block are in [`evidence.md`](evidence.md).

The search strings and the before/after examples stay in Spanish: they are what to look for in a
Spanish text and what the fix reads like.

Every fix keeps the claim: if removing the tell leaves nothing to say, cut the sentence.

## A. Staging instead of stating

### 1. Not X but Y

*Look for:* "no X, sino Y"; "no solo X, sino también Y"; "no se trata de X, se trata de Y"; "X;
lo que falta es Y"; "más que X, Y"; "Y en lugar de X"; the contrast split into two sentences
("Esto no significa X. Significa Y."); the clipped negative tail ("…, sin adivinar"); the row of
negations ("No es un plan. No es una promesa.").

The negative half names something nobody claimed so the positive one looks bigger. Make the point
directly. Keep the contrast when the negative half corrects a real belief of the reader or when
both halves inform.

> *Before:* El Estado colombiano logró abrir los datos; lo que falta es mantenerlos al día.
> *After:* El Estado colombiano ya publica sus datos, pero no los mantiene al día.

### 2. One-line closers and fragments

*Look for:* a final sentence that repeats the paragraph; "Y eso lo cambia todo."; "Ahí está la
clave."; a sentence after a figure that says what the figure showed ("Esto evidencia la
importancia de…"); rows of fragments ("Sin licencia. Sin descripción. Sin actualizar."); the
closing summary of a message that repeats what the message already said.

Cut the closer that repeats. Keep it if it adds a consequence the figure doesn't show.

### 3. Sayings that sound deep

*Look for:* "la verdadera pregunta es", "en el fondo", "en esencia", "lo que realmente importa",
"el corazón del asunto", "X es el lenguaje de Y", "más que una herramienta, un espejo", aphorisms
("medir es decidir").

Replace the saying with the concrete claim it hides.

### 4. Openings that announce

*Look for:* "Cabe destacar que", "Es importante señalar que", "Vale la pena mencionar que", "Cabe
resaltar", "Es menester", "A continuación se presenta", "En esta sección se abordará", "Dicho
esto,", "La clave está en", "Lo interesante es que", "Aquí viene lo importante".

Delete the announcement and start with the point.

> *Before:* Cabe destacar que solo el 17,8 % cumple su frecuencia declarada.
> *After:* Solo el 17,8 % cumple su frecuencia declarada.

### 5. Arguing with no one

*Look for:* "Esto no quiere decir que", "No se trata de afirmar que", "Si bien podría pensarse
que", "Una opción tentadora sería", the question the text itself answers in the next sentence
("¿El resultado? Un sistema más rápido.").

It answers an objection the text never raises. Delete it; if it holds a claim, state the claim.
Keep the alternative the reader really would weigh (the one the rubric asks for, the one they saw
in class).

### 6. Performed hedging

*Look for:* hedges that point at no specific doubt ("en cierta medida", "de alguna manera",
"podría decirse que", "parece sugerir"), spread evenly across the text. Models add twice as many
hedges as people, but not where the evidence is weak.

Remove the hedge where the text knows; leave one, with its reason, where the doubt is real and the
source backs it ("Hasta donde revisamos", "Por ahora son asociaciones", "con solo 12 casos").

## B. Rhythm by rule

### 7. Forced triads

Ideas in threes to sound complete: "eficiente, transparente y sostenible"; three parallel
examples; three facts and a moral. Models produce triads at almost twice an expert's rate. Check
that each item brings a distinct idea; merge them or develop the strongest. Use the number the
content has: two, four or one.

### 8. A connector at the start of every sentence

*Look for:* "Asimismo", "Además", "Por otro lado", "En este sentido", "En este contexto", "De
igual manera", "Por consiguiente", "En consecuencia", "Por ende", "En definitiva", "En
conclusión", "Finalmente".

One connector per sentence, in a chain, is the tell; each one alone is normal Spanish. Remove those
that express no real logical relation and let the order of the sentences show it. *Weak alone.*

### 9. Sentences of the same length and shape

A paragraph diagnosis, not a sentence one. Models vary sentence length and structure less than
people, within a text and across texts; GPT models in Spanish also write more sentences and more
periods than humans in the same genre. If a paragraph is a row of 12-to-20-word sentences, or
sentence after sentence built as "X, y Y", break the regularity: join the ones that share a subject
or a cause, lengthen one with a subordinate clause, leave another at five words. *Weak alone.*

### 10. Repeated openings

Paragraphs or bullets that start the same way ("Este enfoque…", "Esta herramienta…", "El
sistema…"), or a row of sentences that open with "Y". Change the subject or the order of at least
half. *Weak alone.*

### 11. Devices spread evenly

Every paragraph with its triad, its contrast and its closer: models distribute rhetorical devices
evenly, people concentrate them where they want to persuade. Leave the devices in the paragraph
that needs them and write the rest plainly.

## C. Punctuation

### 12. The em dash as a universal connector

The em dash (—) is legitimate in Spanish for asides, but the model uses it to avoid deciding how
two clauses relate, and keeps it even when asked not to use formatting. Without a sample of the
author using it, change each em dash into a comma, period, colon or parentheses. In technical
texts, messages and posts, don't use it. A single one in an academic text is *weak alone*; a text
full of them is not.

### 13. The reveal colon

*Look for:* a short noun, a colon and the reveal ("La clave: la constancia.", "El resultado: un
40 % menos de errores.", "Mi conclusión: vale la pena."); a colon joining two clauses to build
suspense ("Hay un problema: nadie lo usa").

The tell is the dramatic effect, not the sign. Write the full sentence ("Lo que más ayudó fue la
constancia"). A colon before a list, a quote, an example or an explanation the reader expects
stays: people use colons more than models do.

### 14. Distancing and coining quotes

*Look for:* quotes around a common word to give it the air of a concept ("la 'deuda' técnica", "un
enfoque 'humano'"), or to invent a label the text never defines. Remove them; if the term is the
author's, define it once. Quotes for citations, titles and words mentioned as words stay.

### 15. Inconsistent quotes

A mix of Latin quotes (« »), curly English quotes (" ") and straight ones in the same text. Pick
the ones the document or the submission's norm uses and make them uniform. ChatGPT and DeepSeek
tend to use curly quotes; Claude and Gemini, straight ones. *Weak alone.*

### 16. Arrows, symbols and formatting signs in prose

*Look for:* "→", "⇒", "·" or "•" between words; "+" or "/" instead of "y" or "o"; Markdown
asterisks or hashes pasted into a text that isn't Markdown (an email, a Doc, a form). Write the
word.

## D. Inflation

### 17. AI vocabulary in Spanish

*Look for:* crucial, fundamental, clave (adjective), esencial, robusto (figurative), integral,
holístico, sinergia, panorama, ámbito, entramado, abordar, profundizar, ahondar, destacar /
resaltar / subrayar (verbs), fomentar, potenciar, propiciar, optimizar (figurative), impulsar,
enriquecer, garantizar, multifacético, "en el marco de", "a nivel de", "de cara a", "un abanico
de", "en la era digital", "en constante evolución".

Change it for the plain word or for the figure. Density counts more than the single word: one or
two can be chance. A formal word outside the list is not a tell.

### 18. Inflated significance

*Look for:* "juega un papel crucial", "desempeña un papel fundamental", "marca un antes y un
después", "sienta las bases", "pone de manifiesto", "reviste especial importancia", "un paso
decisivo", "el panorama actual", "en un mundo cada vez más…", "un testimonio de".

Keep the fact, remove the significance. End on the last concrete figure.

### 19. The closing gerund

*Look for:* "…, evidenciando…", "…, reflejando…", "…, permitiendo…", "…, contribuyendo a…",
"…, lo que demuestra la importancia de…". The gerund stuck to the end of a sentence adds an
interpretation with no subject or source; in Spanish it's also a gerund of posteriority, which the
norm discourages. Make it its own sentence with a subject, or delete it if nothing backs it.

> *Before:* Martinez-Gil (2025) automatiza la evaluación de catálogos midiendo exactitud…
> *After:* Martinez-Gil (2025) automatiza la evaluación de catálogos y mide la exactitud…

### 20. Chained nominalization

*Look for:* abstract nouns chained with "de": "la implementación de la evaluación del
cumplimiento de los lineamientos". Models prefer the noun to the verb and write with more
nominalizations than people. Give back the verb with its subject, tense and mood: "evaluamos si
las entidades cumplen los lineamientos". Research objectives are nominal by genre; leave them.

### 21. An inanimate subject that acts

*Look for:* things or ideas doing what a person does: "el informe sostiene", "los datos nos
dicen", "la herramienta entiende", "el proyecto busca", "esta sección explora", "la conversación
se come su propia cola". 2025-26 models do this far more than people. Make the actor the subject
("sostenemos", "en los datos vemos", "con el proyecto queremos").

### 22. Odd collocations and stacked nouns

*Look for:* collocations no person says ("el presupuesto de paciencia del lector", "una higiene
de decisiones", "la superficie de la API") and stacked nouns ("generador de bandas sonoras de
películas de terror"). They are information density at the reader's expense. Use the common word
and split the information into two sentences if needed.

### 23. Verbs that avoid "ser" and "tener"

*Look for:* "se erige como", "constituye", "sirve como", "funge como", "se configura como",
"radica en", "cuenta con", "presenta" (for "tiene"), "se posiciona como", "ofrece" (for "tiene").
Use *es*, *son*, *tiene*.

### 24. Borrowed authority and false attribution

*Look for:* "diversos autores", "la literatura señala", "los expertos coinciden", "numerosos
estudios", "se ha demostrado"; and the citation that doesn't say what the sentence attributes to
it ("igual que en Europa (Quarati, 2023)" when the text itself says Quarati didn't measure that).
Name the source and what it said, or cut. False attribution is a content error: fix it even with
no other tell.

### 25. Inflated novelty and brochure tone

*Look for:* "pionero", "sin precedentes", "por primera vez", "innovador", "revolucionario", "de
vanguardia", "llena un vacío" without the scope of the search; in messages and reviews, the ad
tone ("una experiencia increíble", "sin duda lo recomiendo al cien por ciento"). Keep the claim
with its limit ("Hasta donde revisamos, esta sería la primera medición…") or with the detail that
backs it.

### 26. Rotating synonyms and false ranges

Calling the same thing four ways to avoid repeating ("la plataforma", "la herramienta", "la
solución", "el sistema") confuses the reader, who thinks they are different things. Pick a name
and repeat it. The same with "desde X hasta Y" when X and Y aren't on a scale ("desde la salud
hasta la educación"): name the topics.

## E. Formatting by rule

### 27. Decorative bold and labeled lists

Bold on loose concepts; lists where each item is "**Etiqueta:** a sentence that repeats the
label". Remove the bold; turn into prose the list whose labels don't inform. Labels the rubric
asks for, and a bold label that ends in a period and is followed by new information, stay.

### 28. Title-case headings and decoration

"Revisión De Literatura Y Estado Del Arte" is a calque of English; in Spanish only the first word
and proper names are capitalized. Remove emojis from headings and bullets, headings that only hold
subheadings, and small tables that would be better as a sentence.

### 29. Lists where prose belongs

A message, an email or a review written as bullets with headings. People write those genres in
paragraphs. Turn into prose everything that isn't a real list (steps, options, requirements).

## F. Chat and draft leftovers

### 30. Chatbot residue

"¡Claro!", "¡Excelente pregunta!", "Espero que esto te sea útil", "Si deseas, puedo…", "Aquí
tienes…", "No dudes en…", "Espero que este mensaje te encuentre bien". Delete them and keep the
content.

### 31. Knowledge limits and guesses

"Según la información disponible", "aunque no se dispone de datos específicos, es probable
que…". Say what the sources don't show, or delete the sentence.

### 32. The text talking about itself

"En este apartado se presentará…", "La tabla siguiente compara…", "Como se mencionó
anteriormente", a heading repeated in the first sentence. Talk about the topic, not the document.
A cross-reference the reader needs to find something ("Tabla 1") stays.

### 33. Writing for the wrong reader

Explaining what the reader already knows (to the teacher, what a survey is; to the team, what
their own system does), or defining a common term. Cut the explanation; keep the one the reader
needs.

### 34. Compressed prose

Fragments with no verb, dropped articles, arrows and abbreviations the reader has to decode
("Parser rechaza fecha → código 2, sin escritura"). Write full sentences with their articles and
their verbs.

## Human traits worth keeping

Models cut complex punctuation to a fraction of what people use. In the corpus of Alonso Simón et
al. (2025), human texts in Spanish use more adverbs, pronouns, quotes, parentheses, semicolons and
colons, and fewer adjectives, than GPT's. When rewriting with a model, function words,
first-person pronouns and contractions also go down, and word length and lexical variety go up.
So:

- Keep the parentheses, semicolons, colons and quotes the author already uses; they are part of
  their voice. Use them where the author would, without meeting a quota.
- Prefer the short, common word to the long, rare one.
- Give back the verb with tense and mood: what happened, what would happen, what we did.
- Keep the specific detail, the author's own opinion, the real doubt, the genuine question and the
  aside in parentheses.

When the text already implies a stance of the author (which measure they take up, which work is
closest to theirs, what surprised them, what bothered them about a product), say it in their
person: "es la medida que retomamos", "lo que más me sirvió fue…". It's what most separates a
post-edited text from the model's style, and it adds no fact.
