# Evidence

What backs the catalogues (`patterns-es.md`, `patterns-en.md`) and what is known about detectors. Read on 2026-10-13; extended on 2026-10-19 and 2026-10-27.

## Traits of generated text

- **Alonso Simón, L., Fernández-Pampillón, A. M., Fernández Trinidad, M. and Márquez Cruz, M.
  (2025).** ¿Tienen GPT-3.5 y GPT-4 un estilo de escritura diferente del estilo humano? Un estudio
  exploratorio para el español. *RAEL*, 23(1), 34-54. DOI 10.58859/rael.v23i1.666. Corpus of 180
  texts (scientific articles, news, reviews). 17 of 41 traits separate the models from people: the
  models use more adjectives and more periods (more sentences per text); people use more adverbs,
  pronouns, quotation marks, parentheses, commas, colons, semicolons and hyphens. Scientific
  articles are the genre with the most punctuation differences; GPT-4 comes closer to human than
  GPT-3.5. Backs §9 and the human-traits section of `patterns-es.md`.
- **Reinhart, A. et al. (2024).** Do LLMs write like humans? Variation in grammatical and
  rhetorical styles. arXiv 2410.16107. In English, with Biber's features: instruction-tuned models
  use present-participle clauses 2 to 5 times more than people and nominalizations 1.5 to 2 times
  more; tuning pushes them toward a dense, nominal style. Backs §19 and §20 by analogy; there is no
  Spanish replication.
- **Wikipedia: Signs of AI writing** (WikiProject AI Cleanup) and the
  [humanizer](https://github.com/blader/humanizer) skill (MIT, Siqi Chen), the source of the
  "choose for every reader" theory and of the structure of both catalogues.
- The [unslop](https://github.com/cursor/plugins/tree/main/pstack/skills/unslop) skill (MIT,
  Lauren Tan, commit `e43c7ee`), merged here on 2026-10-27: its technical-prose rules are in
  sections E and F of `patterns-en.md`.
- The connector lists in §8 ("cabe destacar", "en este sentido") come from teaching guides and
  blogs; we found no corpus study that measures them. That's why §8 is *weak alone*.

## Detectors

- **Weber-Wulff, D. et al. (2023).** Testing of detection tools for AI-generated text. arXiv
  2306.15666. Fourteen tools: none exceeds 80% accuracy and only five exceed 70%. False positives
  range from 0% (Turnitin) to 50% (GPTZero). With manual editing or paraphrasing, about half of the
  generated text passes as human. They conclude that a student accused on that output alone has no
  way to defend themselves.
- **Liang, W. et al. (2023).** GPT detectors are biased against non-native English writers.
  arXiv 2304.02819. Detectors flag non-native writers' text as AI because of its low perplexity.
- **Shan, Z., Lee, Y. and Hao, S. (2026).** AI Writers Have a Consistent Stylometric Footprint,
  but AI Editors Do Not. arXiv 2608.27855. Generating with AI leaves a stable stylometric
  footprint (entropy, lexical diversity); editing human text with AI barely leaves one (AUC 0.80
  with style features), but a detector trained for editing, EditLens, tells it apart with AUC 0.97.

Practical consequence: a detector doesn't prove authorship in any sense. The defense against an
accusation is the trail of the work (Docs version history, scripts, data, notes), and text edited
with AI can be flagged by editing detectors even when the ideas are the author's own. If the
assignment allows AI support, declare it the way the course asks.

## Added on 2026-10-19

- **Vázquez-Cano, E. (2026).** Assessing AI-generated academic writing in Spanish across ChatGPT,
  Gemini, and Claude. *Language Education & Assessment* (Castledown). 90 academic texts in
  Spanish: each model leaves its own syntactic profile, above all in coordination (LDA 91% between
  models). It doesn't compare with human texts. Backs varying coordination and subordination
  instead of chaining "X y Y". Backs §9.
- **Comparative analysis of human and generated media texts (2025).** *Lengua y Habla* (ULA).
  Texts from ChatGPT, Gemini and BingAI show more grammatical correctness, standardized syntax,
  less metaphor and less expressiveness; the authors propose five "humanity" parameters:
  grammatical variability, semantic richness, pragmatic relevance, rhetorical organization and
  stylistic expression. Backs the author's own stance in the human-traits section.
- **Can You Make It Sound Like You? (2026).** arXiv 2604.24444. Preregistered study (n = 81):
  post-editing brings the text closer to the author's style, but it stays closer to the model's
  text than to unaided writing, and the authors don't notice that distance. Changing single words
  isn't enough; sentences must be restructured and the author's stance added. Backs step 4 of the
  skill.

## Added on 2026-10-27

Read in the abstract, except where noted otherwise: they support what the abstract claims, not
the details of the method.

### Traits

- **From Context Shift to Stylistic Collapse (2026).** arXiv 2605.28826. 17 models and 24
  linguistic probes: instruction-tuned models cut complex punctuation to 3–23% of the base
  frequency and collapse discourse entropy. Backs the human-traits section (keep parentheses,
  semicolons, colons) and the "flat text" of `detectors.md`.
- **The Last Fingerprint: How Markdown Training Shapes LLM Prose (2026).** arXiv 2603.27006.
  Twelve models from five providers: the em dash is Markdown leaking into prose; it persists when
  asked not to use formatting and, in some models, even when it's forbidden. Llama doesn't use it
  (0 per 1,000 words); GPT-4.1 reaches 9.1. Backs §12 of both catalogues.
- **Em-ergence of the em-dash (2026).** arXiv 2606.29540, preregistered. In 69,632 medRxiv
  preprints, Discussions with at least one em dash go from 4.2% before ChatGPT to 20.3% in 2025.
  It's a population indicator, not one for a single text. Backs §12.
- **Saying More Than They Know (2026).** arXiv 2604.19768. 225 argumentative texts: models build
  triads at almost twice an expert's rate, add twice as many hedges and spread rhetorical devices
  more evenly; people ask twice as many rhetorical questions. Backs §6, §7 and §11 of
  `patterns-es.md` (§6, §7 and §10 of `patterns-en.md`).
- **Why is AI-generated language so hard to understand? (2026).** arXiv 2610.29162. Nine frontier
  models: more inanimate subjects with human verbs, more rare n-grams, longer dependencies, more
  stacked nouns and more reduced relatives than human text; they attribute it to the information
  density pressure of training on code and reasoning. It's the NYU and UT Austin study the press
  covered as "six habits". Backs §21 and §22.
- **Voice Under Revision (2026).** arXiv 2604.22142. 300 personal narratives rewritten by three
  models: function words, contractions and first-person pronouns go down; lexical variety, word
  length and elaborate punctuation go up. Prompts that ask to keep the voice reduce the change but
  don't reverse it. Backs the human-traits section and step 4 of the skill.
- **Novels generated by language models show compressed formal variation (2026).** arXiv
  2608.12630, and **Linguistic and Embedding-Based Profiling (2025)**, arXiv 2507.13614. Variation
  in sentence structure and length is lower in generated text than in human text, and new models
  resemble each other more and more. Backs §9 (§8 in `patterns-en.md`).
- **ChatGPT-generated texts show authorship traits that identify them as non-human (2025).**
  arXiv 2508.16385. The model prefers nouns to verbs; people anchor the text in tense, aspect and
  mood. Backs §20.
- **Wikipedia: Signs of AI writing**, reviewed on 2026-10-27. Vocabulary by period (mid-2024 to
  mid-2026: emphasizing, enhance, highlighting, showcasing; since mid-2026: challenge, clearer,
  dependable, foster, leverage, multifaceted, prioritize, quietly, steady, universally); curly
  quotes typical of ChatGPT and DeepSeek, not of Claude or Gemini; the em dash as a historical
  signal up to September 2026; and the warning that fixing surface marks only makes detection
  harder without solving the text's problem.
- **stopslop** ([mgiovani/stopslop](https://github.com/mgiovani/stopslop), `docs/rules.md`). Its
  colon rule flags only the reveal pattern; its curly-quote rule is off because in its labeled
  corpus they appeared in human text as often as in AI text. Backs §13 and the *weak alone* of §15.

### Detectors

- **Base Models Look Human To AI Detectors (2026).** arXiv 2605.19516. GPTZero and Pangram judge
  base-model text as human almost every time, and not the text of their tuned versions: detectors
  track artifacts of instruction tuning.
- **Ontological Instability and Statistical Amplification (2026).** arXiv 2610.03110. When
  Mistral-7B-Instruct was asked to sound more human, verb diversity rose and the text became easier
  to detect; the RoBERTa detector gave 76.3% false positives on formal human writing.
- **Why AI Detection Fails for Academic Integrity (2026).** arXiv 2608.11256. Light AI edits
  ("refine just the abstract") flagged at 38 to 80%; untouched originals from 2023–2025, 9 to 15%;
  after Undetectable AI, under 4% stays flagged. Scores track the density of long words and of the
  Academic Word List.
- **Team DArgk, ELOQUENT 2026.** arXiv 2609.22221. Evasion achieved with reinforcement learning
  produces shorter, simpler, less varied texts: evading isn't sounding more human.
- **Pangram.** Prices and quota read on pangram.com on 2026-10-27: 5 free analyses a day with an
  account, API at US$0.05 per 100 words, Spanish support. Its own August 2025 test gives 97% on
  humanized text against 46% for GPTZero and 7% for Binoculars; the vendor ran it. The evaluation
  by Jabarian and Imas (Chicago Booth), cited by third parties, ranks it first on false positives
  and negatives.
- **GPTZero.** Free plan of 10,000 words a month, no API (gptzero.me/pricing and 2026 reviews).
