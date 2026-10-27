# Evidencia

Lo que respalda los catálogos (`patrones.md`, `patterns.md`) y lo que se sabe de los detectores. Leído el 2026-10-13; ampliado el 2026-10-19 y el 2026-10-27.

## Rasgos de los textos generados

- **Alonso Simón, L., Fernández-Pampillón, A. M., Fernández Trinidad, M. y Márquez Cruz, M.
  (2025).** ¿Tienen GPT-3.5 y GPT-4 un estilo de escritura diferente del estilo humano? Un estudio
  exploratorio para el español. *RAEL*, 23(1), 34-54. DOI 10.58859/rael.v23i1.666. Corpus de 180
  textos (artículos científicos, noticias, reseñas). 17 de 41 rasgos separan a los modelos de las
  personas: los modelos usan más adjetivos y más puntos (más oraciones por texto); las personas
  más adverbios, pronombres, comillas, paréntesis, comas, dos puntos, punto y coma y guiones. Los
  artículos científicos son el género con más diferencias de puntuación; GPT-4 se acerca más a lo
  humano que GPT-3.5. Respalda §9 y la sección de rasgos humanos de `patrones.md`.
- **Reinhart, A. et al. (2024).** Do LLMs write like humans? Variation in grammatical and
  rhetorical styles. arXiv 2410.16107. En inglés, con los rasgos de Biber: los modelos ajustados
  con instrucciones usan cláusulas de participio presente 2 a 5 veces más que las personas y
  nominalizaciones 1,5 a 2 veces más; el ajuste los lleva a un estilo denso y nominal. Respalda
  §19 y §20 por analogía; no hay réplica en español.
- **Wikipedia: Signs of AI writing** (WikiProject AI Cleanup) y la skill
  [humanizer](https://github.com/blader/humanizer) (MIT, Siqi Chen), de donde vienen la teoría
  del "elegir para todos los lectores" y la estructura de los dos catálogos.
- La skill [unslop](https://github.com/cursor/plugins/tree/main/pstack/skills/unslop) (MIT,
  Lauren Tan, commit `e43c7ee`), fusionada aquí el 2026-10-27: sus reglas de prosa técnica están
  en las secciones E y F de `patterns.md`.
- Las listas de conectores de §8 ("cabe destacar", "en este sentido") salen de guías docentes y
  blogs; no encontramos un estudio de corpus que las mida. Por eso §8 es *débil sola*.

## Detectores

- **Weber-Wulff, D. et al. (2023).** Testing of detection tools for AI-generated text. arXiv
  2306.15666. Catorce herramientas: ninguna supera el 80 % de exactitud y solo cinco el 70 %. Los
  falsos positivos van del 0 % (Turnitin) al 50 % (GPTZero). Con edición manual o paráfrasis,
  cerca de la mitad del texto generado pasa por humano. Concluyen que un estudiante acusado solo
  con esa salida no tiene cómo defenderse.
- **Liang, W. et al. (2023).** GPT detectors are biased against non-native English writers.
  arXiv 2304.02819. Los detectores marcan como IA el texto de escritores no nativos por su baja
  perplejidad.
- **Shan, Z., Lee, Y. y Hao, S. (2026).** AI Writers Have a Consistent Stylometric Footprint,
  but AI Editors Do Not. arXiv
  2608.27855. Generar con IA deja una huella estilométrica estable (entropía, diversidad
  léxica); editar un texto humano con IA casi no la deja (AUC 0,80 con rasgos de estilo), pero un
  detector entrenado para edición, EditLens, la distingue con AUC 0,97.

Consecuencia práctica: un detector no prueba autoría en ningún sentido. La defensa ante una
acusación es el rastro del trabajo (historial de versiones del Docs, scripts, datos, notas), y un
texto editado con IA puede ser señalado por los detectores de edición aunque las ideas sean
propias. Si la entrega admite apoyo de IA, decláralo como pida el curso.

## Añadido el 2026-10-19

- **Vázquez-Cano, E. (2026).** Assessing AI-generated academic writing in Spanish across ChatGPT,
  Gemini, and Claude. *Language Education & Assessment* (Castledown). 90 textos académicos en
  español: cada modelo deja un perfil sintáctico propio, sobre todo en la coordinación (LDA 91 %
  entre modelos). No compara con textos humanos. Respalda variar coordinación y subordinación en
  vez de encadenar "X y Y". Respalda §9.
- **Análisis comparativo de textos mediáticos humanos y generados (2025).** *Lengua y Habla*
  (ULA). Los textos de ChatGPT, Gemini y BingAI tienen más corrección gramatical, sintaxis
  estandarizada, menos metáfora y menos expresividad; proponen cinco parámetros de "humanidad":
  variabilidad gramatical, riqueza semántica, relevancia pragmática, organización retórica y
  expresión estilística. Respalda la postura propia en la sección de rasgos humanos.
- **Can You Make It Sound Like You? (2026).** arXiv 2604.24444. Estudio preregistrado (n = 81):
  la posedición acerca el texto al estilo propio, pero sigue más cerca del texto del modelo que
  de la escritura sin ayuda, y los autores no notan esa distancia. Cambiar palabras sueltas no
  basta; hay que reestructurar oraciones y poner la postura propia. Respalda el paso 4 de la
  skill.

## Añadido el 2026-10-27

Leídos en el resumen (abstract), salvo donde se dice otra cosa: sostienen lo que el resumen
afirma, no el detalle del método.

### Rasgos

- **From Context Shift to Stylistic Collapse (2026).** arXiv 2605.28826. 17 modelos y 24 sondas
  lingüísticas: los modelos ajustados con instrucciones reducen la puntuación compleja al 3–23 %
  de la frecuencia base y colapsan la entropía del discurso. Respalda la sección de rasgos
  humanos (conservar paréntesis, punto y coma, dos puntos) y el "texto plano" de `detectores.md`.
- **The Last Fingerprint: How Markdown Training Shapes LLM Prose (2026).** arXiv 2603.27006.
  Doce modelos de cinco proveedores: la raya es Markdown que se filtra a la prosa; persiste cuando
  se pide no usar formato y, en algunos modelos, aun cuando se prohíbe. Llama no la usa (0 por
  1.000 palabras); GPT-4.1 llega a 9,1. Respalda §12 de los dos catálogos.
- **Em-ergence of the em-dash (2026).** arXiv 2606.29540, preregistrado. En 69.632 preprints de
  medRxiv, las Discusiones con al menos una raya pasan del 4,2 % antes de ChatGPT al 20,3 % en
  2025. Es un indicador de población, no de un texto. Respalda §12.
- **Saying More Than They Know (2026).** arXiv 2604.19768. 225 textos argumentativos: los modelos
  hacen tríadas casi al doble de la tasa de un experto, ponen el doble de marcas de vacilación y
  reparten los recursos retóricos de forma más pareja; las personas hacen el doble de preguntas
  retóricas. Respalda §6, §7 y §11 de `patrones.md` (§6, §7 y §10 de `patterns.md`).
- **Why is AI-generated language so hard to understand? (2026).** arXiv 2610.29162. Nueve modelos
  de frontera: más sujetos inanimados con verbos de persona, más n-gramas raros, dependencias más
  largas, más sustantivos apilados y más relativas reducidas que el texto humano; lo atribuyen a
  la presión por densidad de información del entrenamiento en código y razonamiento. Es el
  estudio de NYU y UT Austin que la prensa reseñó como "seis hábitos". Respalda §21 y §22.
- **Voice Under Revision (2026).** arXiv 2604.22142. 300 narraciones personales reescritas por
  tres modelos: bajan las palabras función, las contracciones y los pronombres de primera persona;
  suben la variedad léxica, el largo de las palabras y la puntuación elaborada. Los prompts que
  piden conservar la voz reducen el cambio pero no lo invierten. Respalda la sección de rasgos
  humanos y el paso 4 de la skill.
- **Novels generated by language models show compressed formal variation (2026).** arXiv
  2608.12630, y **Linguistic and Embedding-Based Profiling (2025)**, arXiv 2507.13614. La
  variación en estructura y largo de oración es menor en el texto generado que en el humano, y
  los modelos nuevos se parecen cada vez más entre sí. Respalda §9 (§8 en `patterns.md`).
- **ChatGPT-generated texts show authorship traits that identify them as non-human (2025).**
  arXiv 2508.16385. El modelo prefiere sustantivos a verbos; las personas anclan el texto en
  tiempo, aspecto y modo. Respalda §20.
- **Wikipedia: Signs of AI writing**, revisada el 2026-10-27. Vocabulario por época (de mediados
  de 2024 a mediados de 2026: emphasizing, enhance, highlighting, showcasing; desde mediados de
  2026: challenge, clearer, dependable, foster, leverage, multifaceted, prioritize, quietly,
  steady, universally); comillas curvas típicas de ChatGPT y DeepSeek, no de Claude ni de Gemini;
  la raya, como señal histórica hasta septiembre de 2026; y la advertencia de que arreglar marcas
  superficiales solo dificulta la detección sin resolver el problema del texto.
- **stopslop** ([mgiovani/stopslop](https://github.com/mgiovani/stopslop), `docs/rules.md`). Su
  regla de dos puntos marca solo el patrón de revelación; su regla de comillas curvas está apagada
  porque en su corpus etiquetado salía en texto humano tan a menudo como en el de IA. Respalda
  §13 y el *débil sola* de §15.

### Detectores

- **Base Models Look Human To AI Detectors (2026).** arXiv 2605.19516. GPTZero y Pangram juzgan
  casi siempre humano el texto de modelos base y no el de sus versiones ajustadas: los detectores
  siguen artefactos del ajuste por instrucciones.
- **Ontological Instability and Statistical Amplification (2026).** arXiv 2610.03110. Al pedirle
  a Mistral-7B-Instruct que sonara más humano, subió la diversidad de verbos y el texto se volvió
  más fácil de detectar; el detector RoBERTa dio 76,3 % de falsos positivos en escritura humana
  formal.
- **Why AI Detection Fails for Academic Integrity (2026).** arXiv 2608.11256. Ediciones ligeras
  con IA ("refina solo el resumen") marcadas entre 38 y 80 %; originales de 2023–2025 sin tocar,
  9 a 15 %; tras Undetectable AI, menos del 4 % sigue marcado. Los puntajes siguen la densidad de
  palabras largas y del Academic Word List.
- **Team DArgk, ELOQUENT 2026.** arXiv 2609.22221. La evasión lograda con aprendizaje por refuerzo
  produce textos más cortos, más simples y menos variados: evadir no es sonar más humano.
- **Pangram.** Precios y cuota leídos en pangram.com el 2026-10-27: 5 análisis gratis al día con
  cuenta, API a US$0,05 por 100 palabras, soporte de español. Su propia prueba de agosto de 2025
  da 97 % en texto humanizado frente a 46 % de GPTZero y 7 % de Binoculars; la hizo el fabricante.
  La evaluación de Jabarian e Imas (Chicago Booth), citada por terceros, la pone primera en
  falsos positivos y negativos.
- **GPTZero.** Plan gratis de 10.000 palabras al mes, sin API (gptzero.me/pricing y reseñas de
  2026).
