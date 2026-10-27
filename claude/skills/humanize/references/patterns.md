# Patterns

Catalogue of AI writing tells in English, for any text: technical docs, PRs, commits, messages,
reviews and posts. A pattern justifies an edit on a single sighting, except those marked *weak
alone*, which need other tells in the same paragraph. Sources for each block are in
[`evidencia.md`](evidencia.md).

Every fix keeps the claim. If removing the tell leaves nothing to say, cut the sentence.

## A. Staging instead of stating

### 1. Not X but Y

*Look for:* "not X, but Y"; "not just X, but also Y"; "it's not X, it's Y"; "Y rather than X";
"less X, more Y"; the split version ("This isn't about X. It's about Y."); runs of negations
("Not a plan. Not a promise.").

The negative half names something nobody claimed so the positive half looks bigger. State the
point. Keep the contrast when the negative half corrects something the reader actually believes.

### 2. One-line closers and fragments

*Look for:* a last sentence that restates the paragraph; "And that changes everything."; "That's
the whole point."; a line after a number that says what the number showed; rows of fragments
("No license. No docs. No updates."); a closing recap of a message.

Cut the closer that repeats. Keep it if it adds a consequence the data doesn't show.

### 3. Sayings that sound deep

*Look for:* "the real question is", "at its core", "what really matters", "X is the language of
Y", aphorisms ("wire it or delete it"). Replace with the concrete claim underneath.

### 4. Staged run-up

*Look for:* "It's worth noting that", "It's important to note that", "Here's the thing:",
"Here's what matters:", "Let's dive in", "The key insight is". Delete the run-up and start with
the point.

### 5. Arguing with no one

*Look for:* "This doesn't mean that", "To be clear,", a question the text answers in the next
sentence ("The result? A faster build."). Cut it; if it holds a claim, state the claim.

### 6. Performed hedging

*Look for:* hedges that point at no specific doubt ("arguably", "in some ways", "it could be
said", "potentially", "may possibly"), spread evenly over the text. Models produce about twice
the human density of hesitancy markers. Drop the hedge where the text knows; keep one, with its
reason, where the doubt is real ("with only 12 cases").

## B. Rhythm by rule

### 7. Forced triads

Three adjectives, three examples, three facts and a moral. Models produce tricolons at nearly
twice the expert rate. Check that each item adds a distinct idea; use the number the content has.

### 8. Same length, same shape

Paragraph diagnosis. Model sentences vary less in length and structure than human ones, within a
text and across texts. A row of 10-to-20-word sentences, or sentence after sentence built "X, and
Y", is the tell: merge two that share a subject, extend one with a subordinate clause, leave one
at five words. *Weak alone.*

### 9. Repeated openings

Paragraphs or bullets that open the same way ("This approach…", "This tool…"), runs of "And"-
initial sentences. Change the subject or the order in at least half. *Weak alone.*

### 10. Devices spread evenly

Every paragraph gets its triad, contrast and closer. People concentrate rhetoric where they want
to persuade. Keep the device in the paragraph that needs it and write the rest plainly.

### 11. Shorten or split dense sentences

If the reader has to backtrack to parse a sentence, break it in two or drop clauses. One idea per
sentence.

## C. Punctuation

### 12. Em dashes

Write without em dashes, and without en dashes or hyphens standing in for them. Models keep them
even when told to drop formatting, and they mark the text at a glance. Use a period, a comma, a
colon before an explanation, or parentheses for an aside.

### 13. The reveal colon

*Look for:* short noun phrase, colon, then a reveal ("The fix: caching.", "The catch: nobody uses
it."); a colon used as a mid-sentence connector ("If you're coming from cron: instead of
schedules, you describe conditions"). Write the full sentence. A colon before a list, an example,
a quotation or an explanation the reader expects stays: people use colons more than models do.

### 14. Scare quotes and coined labels

Quotes around an ordinary word to make it a concept ("a 'human' approach"), or around a label the
text invents and never defines. Remove them; if the term is the author's, define it once. Quotes
for a quotation, a title or a word being mentioned stay.

### 15. Curly quotes

ChatGPT and DeepSeek use curly quotes and apostrophes, often mixed with straight ones. In
Markdown, code-adjacent text and plain-text messages, use straight quotes. In a document whose
style uses curly quotes throughout (Word, a publisher's style), keep them consistent instead.
*Weak alone.*

### 16. Arrows and symbols in prose

"→", "⇒", "·" or "•" between words; "+" or "/" for "and" or "or"; Markdown asterisks in a text
that isn't rendered as Markdown (an email, a form, a review box). Write the word.

## D. Inflation

### 17. AI vocabulary

*Look for:* additionally, crucial, delve, enduring, enhance, fostering, garner, interplay,
intricate, landscape (abstract), pivotal, showcase, tapestry, testament, underscore, vibrant,
seamless, robust (figurative), leverage, multifaceted, prioritize, dependable, steady, quietly,
universally, "align with", "in today's fast-paced world". Density matters more than any single
word. Replace with the plain word or the number.

### 18. Inflated significance

*Look for:* "plays a crucial role", "marks a pivotal moment", "stands as a testament",
"paves the way", "a game changer", "broader trends". Keep the fact, drop the significance; end on
the last concrete detail.

### 19. Shallow -ing riders

*Look for:* ", highlighting…", ", ensuring…", ", reflecting…", ", showcasing…", ", fostering…"
tacked onto a sentence. Instruction-tuned models use present-participle clauses two to five times
more than people. Make it a sentence with a subject, or delete it.

### 20. Nominalizations and noun stacks

Abstract nouns chained with "of" ("the implementation of the evaluation of compliance"), stacked
nouns ("horror movie soundtrack generator tool"). Models prefer nouns to verbs. Give back the verb
with its subject and tense: "we check whether the agencies comply".

### 21. Inanimate subjects that act

*Look for:* things doing what people do: "the report argues", "the data tells us", "the tool
understands", "this section explores", "the conversation eats its own tail". 2025-26 models do
this far more than people. Make the actor the subject.

### 22. Odd collocations and abstract metaphor nouns

Word pairs nobody says ("the reader's patience budget", "decision hygiene") and metaphor nouns
that sound technical: substrate, wedge, vector, locus, nexus, primitive, harness (metaphor),
surface ("API surface"), bedrock, scaffolding (metaphor), paradigm, north star, flywheel,
endgame. Use the common word: "substrate" becomes "base", "wedge in" becomes "add", "vector"
becomes "way".

### 23. Fancy ways to say "is"

"serves as", "stands as", "boasts", "features", "offers", "refers to" in place of is, are, has.

### 24. Vague and false attribution

"Experts believe", "Industry reports suggest", "studies show". Name the source and what it said,
or cut. A citation that doesn't say what the sentence attributes to it is a content error: fix it
even with no other tell.

### 25. Sales language

"cutting-edge", "game-changing", "revolutionary", "best-in-class", "I can't recommend it
enough". Keep the claim with the detail that supports it.

### 26. Synonym cycling and false ranges

Protagonist, main character, central figure, hero in one paragraph: pick one name and repeat it.
"From X to Y" where X and Y aren't on a scale: list the topics.

## E. Plain speech

### 27. Say what it does, not how it feels

"the database stays close at hand", "SQL you can read" name a feeling. Name the mechanism or a
number: "`.toSQL()` returns the exact string sent to the database". If the sentence could appear
unchanged in another project's docs, it says nothing about this one: cut it.

### 28. Active voice

Catch "is/are/was/were + past participle" and name the actor: "queries are validated" becomes
"the compiler validates queries". Passive is fine when the actor is unknown or doesn't matter.

### 29. Adverbs and the plain word

"runs quickly" becomes "is fast" or the number; "significantly improves" becomes the measured
delta. "utilize" becomes "use", "facilitate" becomes "help", "in the event that" becomes "if".

### 30. Mannered prose

Figurative verbs ("rides along", "stands on"), personified code ("the plan holds it"), rhetorical
fragments. Say what you mean.

### 31. Filler

"In order to" becomes "to"; "due to the fact that" becomes "because"; "the future looks bright"
becomes the specific plan or fact.

### 32. Over-compression

Dropped articles, verbless fragments, symbol-speak ("Parser rejects bad date → exit 2, no
write"). Write "The parser rejects a bad date, exits with code 2, and writes nothing."

## F. Formatting by rule

### 33. Bold and inline-header lists

Bold on every proper noun; bullets of the form "**Performance:** Performance improved…". Convert
to prose. A bold lead-in that ends in a period and is followed by new detail is fine.

### 34. Headings and decoration

Title Case headings (use sentence case), emoji in headings and bullets, headings that hold only
subheadings, small tables that should be a sentence.

### 35. Lists where prose belongs

A message, email or review written as headed bullets. People write those genres in paragraphs.
Keep a list only for real steps, options or requirements.

## G. Chat and draft leftovers

### 36. Chatbot residue

"I hope this helps!", "Let me know if…", "Of course!", "Certainly!", "Great question!", "I hope
this message finds you well". Remove; keep the content.

### 37. Knowledge-limit disclaimers

"Based on available information", "while specific details are limited". Say what the sources
don't show, or cut.

### 38. Writing about the document

"This section covers…", "As mentioned above", a heading repeated as the first sentence. Talk
about the subject. A pointer the reader needs ("Table 1") stays.

### 39. Writing for the wrong reader

Explaining what the reader already knows. Cut it; keep what they need.

## Human features to keep

Instruction-tuned models cut complex punctuation to a fraction of human use, and LLM rewriting
lowers function words, contractions and first-person pronouns while raising word length and
vocabulary variety. So:

- Keep the parentheses, semicolons, colons and quotes the author already uses.
- In messages, reviews and posts, use contractions and first person the way the author does.
- Prefer the short common word to the long rare one.
- Keep the specific detail, the opinion, the real doubt, the genuine question and the aside.
