# Editorial method

The pipeline in `SKILL.md` produces a well-set document. This produces one worth
reading. Skip it and you will make something that *looks* authoritative without being
so, which is worse than making something plainly provisional.

The governing principle: **a reader must be able to check you.** Every load-bearing
claim carries a name, a date and a URL, so a sceptical reader argues with the source
rather than with you.

---

## 1. Research

### 1.1 Rank every source before relying on it

Prefer higher rows. When you use a lower row, say so in the running text.

| Rank | Kind | Weight |
|---|---|---|
| 1 | **Normative specification** — the document that defines the thing | definitive; quote its `MUST` clauses verbatim |
| 2 | **Formal proposal with a status field** | definitive *for its status* — always report the status |
| 3 | **Governance artefacts** — charters, roadmaps, minutes | definitive about intent and priority, not outcome |
| 4 | **First-party engineering post with measurements** | credible numbers, interested party |
| 5 | **Incident and vulnerability records** | matters of record |
| 6 | **Practitioner writing** | cite as a *position*, never as a fact |
| 7 | **Vendor marketing, analyst commentary** | evidence only that a capability was productised |
| 8 | **Aggregated secondary commentary** | avoid; follow it upstream instead |

For a document about a codebase, substitute the equivalent ladder: the code at a
verified line range (1) · decision records, reporting the `Status:` field (2) · tests,
which assert the contract the author meant (3) · project memory and glossary (4) ·
upstream library source (5) · vendor documentation (6) · existing drafts and notes (7).

**The highest-value research move is replacing a rank-6 source with the rank-1 source it
was describing.** Commentary is where errors are introduced; specifications and source
files are where they are resolved.

### 1.2 Search to orient, then go primary

Search results are a map, not a destination.

1. Broad search to learn what exists and what it is called.
2. Identify the authoritative home for each named artefact.
3. Fetch it and read it in full.
4. Quote the primary document, never the search snippet.

In the document this method comes from, an early draft described a protocol change from
a vendor announcement. Reading the actual proposal revealed roughly three times as much
had been removed as the announcement mentioned, including things infrastructure depended
on. The section had to be rewritten. That is the normal outcome of going primary, and it
is why you do it before publishing rather than after.

### 1.3 Follow references out of sources

Primary documents cite each other, and those citations are the highest-yield leads you
will get.

- A spec saying "session management is addressed separately by proposal X" is telling
  you the story is incomplete without X.
- A vendor article naming an extension is telling you an extension exists — verify it at
  the standards site, not in the description.
- Documentation sites often publish a machine-readable index (`llms.txt`, `sitemap.xml`,
  a docs index). Fetch it: it reveals the *shape* of the project — which working groups
  exist, which proposals are live, what the current published version actually is.

### 1.4 Read the status field, always

For anything with a lifecycle, status determines what a reader may safely build on:

- **Final / stable / published** → build on it now.
- **In review / accepted but unreleased** → design for it, do not block on it.
- **Draft / experimental** → keep options open; do not couple to it.
- **Low priority** → assume it will not arrive; plan without it.

Record **dates** too. "Last updated 5 March 2026" tells the reader how quickly your
reading of it will go stale, and when to look again. Say so in the text. Where a
decision was reversed or superseded, say so and say what replaced it — a reversal is the
most informative thing in a decision record.

### 1.5 Go looking for the counter-evidence

A document that only marshals supporting evidence is advocacy, and readers detect it
immediately. Actively search for the strongest disconfirming result and put it in.

In the source document, a vendor's own benchmark showed a feature raising accuracy
substantially; an independent benchmark at ten times the scale showed it collapsing to
about a third of that. Both went in, adjacent, and the recommendation changed from
"adopt this technique" to "curation beats retrieval; this technique mitigates catalogues
you have not curated." **That revision is the value. If your conclusions never move
during research, you were not researching.**

For a codebase document, the equivalent is: a limitation the decision record itself
concedes, a case the implementation does not handle, a cost the design pays, or a place
where the code and its record disagree. If you find nothing, you have not looked.

### 1.6 Name the commercial interest

Once, plainly, without editorialising: *Kong sells a gateway, and its framing should be
read with that in mind, even where the underlying observations are sound.* It costs one
clause and buys the reader's trust for everything else.

### 1.7 Track your own provenance

Keep the distinction — in your notes and then in the source register — between what you
**read at source**, what reached you **second-hand**, and what is your **own inference**.
Second-hand figures are attributed to their originator *and* flagged as not read at
source. Never present inference as observation.

### 1.8 Be willing to correct the document

Research arriving after drafting will sometimes invalidate what you wrote. Rewrite the
section. Do not bolt a caveat onto a paragraph you now know is wrong and do not quietly
soften it. If the correction is significant, say in the text what the earlier consensus
was and what changed.

---

## 2. Grounding and attribution

### 2.1 What earns a quote callout

Quotation is scarce and deliberate; most source material should be paraphrased. A
`quote` block asserts that *this exact wording matters*. Use one only when:

1. **it is normative** — a `MUST` or `MUST NOT` whose modal verb carries the weight;
2. **it contains a number** you rely on;
3. **it is a design position held by a named party**, where who said it is evidence;
4. **paraphrase would lose the force**;
5. **it concedes something against interest** — a vendor stating the costs of their own
   approach is worth far more than the same words from a critic.

If none apply, paraphrase and cite. A document dense with quotation reads as a scrapbook;
a document with a dozen well-chosen ones reads as researched.

### 2.2 The anatomy of an attribution

Five elements, in this order, none dropped:

| Element | Why it is there |
|---|---|
| **Name**, small caps | a person said this, not an organisation — accountability |
| **Role and organisation** | standing: "Lead Maintainer" is why this settles the question |
| **Title of the work**, italic | lets the reader find it if the URL rots |
| **Date** | lets the reader judge staleness |
| **URL**, monospace, own line | lets the reader check you |

Where a quote reached you through an intermediary, say so in the attribution itself:
"Attributed to *Name*, reported in *Article*".

### 2.3 Do something with the quote

A quote followed by the next heading is decoration. Follow every quotation with prose
that **extracts the consequence**, **disagrees with it**, **qualifies it**, or
**connects it forward**. The quote provides the evidence; the sentence after it provides
the argument, and readers remember the argument.

---

## 3. Constructing the argument

### 3.0 Explain, do not compress

The single most common failure in a technical brief is prose that names things instead of
explaining them. It reads as competent and teaches nothing, because every sentence asks
the reader to unpack two or three abstractions at once.

> **Bad.** The wrapper adds three things a bare run cannot have. First, *a boundary
> vocabulary*: named points inside a turn at which the outside world is allowed to
> intervene. Second, *a phase machine* that makes "busy" observable, so a second
> keystroke can be routed rather than raced.

Three coined terms in two sentences, each defined by another dense clause. Compare:

> **Good.** While the agent is working, you can still type. Your text does not get thrown
> away, and it does not crash into the middle of a running turn. It waits in a queue. The
> priority gate is the moment the runner stops and says: safe spot — anything new from
> the human? That is it. It is a pickup point for your typed input.

The good version moves in time, uses ordinary words, and gives the technical name only
once the reader can already picture the thing. Five rules follow from it:

1. **Concept before name.** Never define a coined term with another coined term.
2. **One new idea per sentence.** Two ideas means two sentences.
3. **Narrate in time or in causation** — "this happens, which means that, which is why
   the code does X". A list of three abstract nouns is not an explanation.
4. **Start from the pain.** One sentence on what goes wrong without the mechanism, before
   the mechanism. The reader should feel the need before meeting the answer.
5. **The whiteboard test.** If you would not say the sentence out loud to a colleague,
   rewrite it.

None of this licenses vagueness. Every fact, file:line citation and status field stays;
what goes is the habit of packing three concepts into one clause. Explaining costs words —
budget about 15% more prose than the compressed version, and no more.

### 3.1 Define before you use

Devote the first part to vocabulary, building from primitives the reader definitely
knows. Close it with a single table assembling every term, one row each, with a column
for "answers the question…". Design discussions stall because two people use one word
differently; that table is the remedy and is usually the most photocopied page.

### 3.2 Steelman before you resolve

For a genuinely contested question, present the strongest version of each position — its
own numbered subsection, its own supporting quotations — before resolving. Give the side
you disagree with the better evidence if the better evidence is theirs.

Then **resolve by reframing rather than by scoring**. The useful resolutions observe that
the two camps optimise for different situations, and name those situations. A resolution
that declares a winner will not survive contact with a reader who holds the losing
position.

### 3.3 State what your recommendation does not fix

An explicit two-column table: what this *does* / what this does **not**. Then say plainly
what remains the reader's problem. Counter-intuitively this is the single strongest
credibility move available: a recommendation with no stated limits reads as sales
material; the same recommendation with six honestly-stated limits reads as engineering.

### 3.4 Mark judgement as judgement

"This is informed judgement, not measurement." "Legitimate approaches genuinely disagree
here." "This is an open problem across the industry, not a gap in your process." These
mark the boundary without hedging into uselessness.

### 3.5 Argue the counterfactual

Include a chapter answering "what if we do nothing?", traced in periods — months 0–3,
3–6, 6–12, and the forcing event that ends the sequence. Doing nothing is rarely a
neutral baseline, and showing why is more persuasive than any list of benefits. Pair it
with the strongest honest case for deferring, followed by your mitigation.

### 3.6 Build a decision register with a basis column

End the recommendation part with numbered decisions, each citing the section that
established it:

| # | Decision | Basis |
|---|---|---|
| D4 | Buy or adopt the gateway. Do not build. | §13.3, §21.2 — structurally a confused deputy; the mitigations are numerous and easy to get subtly wrong. |

This gives the reader a one-page artefact to take into a meeting, and it forces you to
verify that every recommendation traces to evidence. A decision with no basis to cite is
an unsupported assertion you have just found.

### 3.7 Close with what you could not answer

Finish with the open questions stated as open: what the question is, what is known, what
remains unresolved. Then grade your own document — which parts are settled fact, which
are measured, which are informed judgement, which are recommendations that should be
argued with. A document that admits its limits is trusted on the parts it does not
qualify.

### 3.8 Two appendices, always

- **Glossary**, grouped by conceptual layer rather than alphabetically, because the
  grouping is itself information.
- **Source register**, grouped by source kind, each entry saying what it was used for
  and giving its URL, closing with an **evidential weight** paragraph: which groups are
  authoritative, which are interested-party claims not independently replicated, and
  which are opinion cited as position.

---

## 4. Emphasis discipline

The ladder and its budgets live in `SKILL.md`. The promotion tests, which are what
actually keep the budget honest:

- **To a `box`:** a reader could act correctly without it, but would act better with it.
- **To a `box dark`:** a reader who skims past this will reach the wrong conclusion.
- **To a `keypanel`:** a reader who reads only this panel and nothing else in the chapter
  still takes away the correct decision.

The last test is strict and should be. In the source document only three passages met
it: the executive summary of the protocol change, the executive summary of the central
user story, and one specification `MUST` clause whose violation invalidates the whole
architecture.

Give promoted elements a title that **asserts** something — it is often the only line a
skimming reader reads.

| Weak | Strong |
|---|---|
| "Security considerations" | "The property everything else follows from" |
| "About sessions" | "Why that is fatal rather than merely untidy" |
| "Summary" | "The sentence that resolves most of the confusion" |
| "Note on timing" | "This document is being written on a hinge" |
