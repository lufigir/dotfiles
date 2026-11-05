# Detectors

How to run step 6 and what to expect from it. The evidence is in [`evidence.md`](evidence.md#detectors).

## What they measure

Commercial detectors don't look for single words: they learn the fingerprint of instruction
tuning (flat, predictable, low-entropy, nominal text with reduced punctuation). That's why a base
model, with no tuning, passes as human on GPTZero and Pangram, and why asking a tuned model to
"sound human" can raise the score: it swaps words and keeps the shape.

Consequences for rewriting:

- What lowers the score is the same thing that improves the text: sentences of varied length and
  shape, verbs with human subjects, short common words, the author's punctuation, their stance and
  their details. It's the catalogue applied thoroughly, not a different method.
- Swapping synonyms moves nothing. Restructure the whole flagged paragraph.
- Text Claude rewrites is still text from a tuned model. A passage the author didn't write can
  stay flagged even with no catalogue mark left; what fixes it is the author rewriting it in their
  own words or adding the detail only they have.
- Detectors also flag human text: formal, academic and non-native writing, and human texts only
  lightly edited with AI (38 to 80% in a 2026 study). A high score doesn't prove authorship, and
  the defense against an accusation is the trail of the work: the Docs version history, scripts,
  data, notes.

## What doesn't work

Deliberate typos, homoglyphs (letters from another alphabet that look the same), invisible spaces
and automatic paraphrasers. They damage the text for whoever reads it, they show up when it's
copied or spell-checked, and the humanizers that use them produce shorter, simpler, less varied
text that looks no more human. Don't use them even if they lower a score.

## Which to use

| Detector | Access | For |
|---|---|---|
| Pangram | Web with an account, 5 free analyses a day; accepts Spanish; paid API (US$0.05 per 100 words) | The reference one: the best false-positive rate in independent evaluations and the most resistant to humanizers |
| GPTZero | Web with an account, 10,000 free words a month; no API on the free plan | Second opinion; flags sentences and separates mixed text |
| Turnitin | Only through the university | If the course uses it, its result is the one that matters; there's no personal access |

Run Pangram first. GPTZero when Pangram isn't available or when the text is mixed and it helps to
see which sentences it flags. Free detectors with no account (ZeroGPT and similar) fail on human
text in published tests; they're no use for deciding anything.

## How to run it in Brave

The `brave` MCP (`mcp__brave__*`) drives Brave Agente, a Brave profile kept for the agent with its
own sessions; if a detector asks to sign in, the user signs in there once.

1. `list_pages`, then `new_page` with the detector's URL; the user's tabs stay as they are.
2. `take_snapshot`; locate the text area and the analyze button by their accessible names.
3. `fill` with the complete final text (without titles or references if the detector counts words
   against the quota), click analyze, wait for the result and take another snapshot.
4. Note the verdict, the percentage and the flagged passages. If it asks to sign in or the day's
   quota ran out, tell the user and move on to the other detector.

## The loop

1. Run the detector on the final text from step 5.
2. If it flags passages, go back to step 2 with those paragraphs only: look for the marks that
   remain, measure the rhythm and restructure; don't swap synonyms.
3. Run it again. One analysis per round; three rounds at most, because the free quota is short.
4. If a passage is still flagged after three rounds, hand it over flagged: say which passage it
   is, what score it has and what it lacks (almost always the author's voice or a detail). Don't
   keep polishing at the cost of clarity.

Report each round: detector, score, flagged passages and what you changed.
