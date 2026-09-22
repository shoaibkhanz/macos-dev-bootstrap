---
name: explaining-clearly
description: Tell the story of how code, a system, or an abstraction works, one layer at a time, every claim checked against the real source. Use whenever the user says "explain how", "how does this work", "explain this clearly", "walk me through", "why does this exist", or that an earlier explanation didn't land, and before restating a design, a class hierarchy, or a data flow.
---

# Explaining Clearly

The answer is a **story**: afterward the reader can rebuild the whole picture
from memory. Talk it through at a **whiteboard**, pointing at real code.

## The story

Every answer uses this shape, in this order, with these headers, so the reader
can tell from the headers alone where they are. `## Side by side` appears only
when two things are compared; the other four parts are always present.

The one exception is a question whose whole answer is a single fact (a return
type, a config value): give that fact in one to three sentences with its
receipt.

1. **`## The problem`**: one paragraph, no code. The need, or what breaks
   without this. Open here so the code that follows already has a reason to
   exist. ("Java speaks camelCase, Python wants snake_case, something has to
   translate every field, every time.")
2. **`## <what the piece is>`**: one header per piece, in build order, each
   named for the real noun or mechanism inside it. Open each by naming the gap
   the previous piece left. Where the piece branches ("if X, continue, else
   stop"), name the field or check that drives it and where that value comes
   from, before describing either side.
3. **`## Side by side`**: only when comparing two things (two systems, or the
   code before and after a change), and only after each is explained on its
   own. A short table or one line naming the axis they differ on; for a change,
   name what improved and the mechanism that improved it.
4. **`## The point, restated`**: one or two plain sentences answering the
   original question. Nothing new here.
5. **Closing question**, last paragraph, no header: ask something a wrong or
   hesitant answer would expose, aimed at the piece most likely to be misread
   (the easy-to-misread node of a diagram, the distinction just drawn). "Does
   that make sense?" only invites a reflexive yes. Their answer decides whether
   to move on or re-explain that piece.

Cut anything above the restated point that the point didn't need. Two examples
with the same shape: keep the one that carries it best, compress the other to a
line.

### Reference codes

When a section lists three or more parallel items the reader will answer about,
tag each one so either of you can name an item instead of re-describing it:

| Code | For |
| ---- | --- |
| `F1`, `F2` | findings |
| `O1`, `O2` | options |
| `R1`, `R2` | risks |
| `Q1`, `Q2` | open questions |

Another family of items gets its own letter, chosen the same way. Keep every
code for the rest of the conversation. Fewer than three items, or a list
nobody will point at, gets no codes.

## Done when

- Every behavioural claim has its **receipt**: the file, line, commit, or doc
  you read this turn, cited inline. A claim without one reads the same whether
  or not you checked. Someone questions a claim: re-read before restating.
- Every branch point names its **mechanism**: the exact field or check, and
  what produces its value.
- Every node and edge in a diagram has a sentence saying what it is and why it
  is drawn.
- A diagram grows with the story: the first one shows only the pieces explained
  so far, and each later section redraws it with the new piece added. The full
  diagram appears last, when every piece in it has already been named.
- Every term is grounded in something the reader already owns (the piece just
  explained, their own code), or defined in the same breath and then used. A
  term that appears once and does no work is cut.
- The closing question targets one specific piece of the story.

## Whiteboard voice

Write the way Sebastian Raschka and Chip Huyen write when they explain a
system. Short paragraphs. One idea per sentence, then a period. Plain words:
"use" not "utilize", "since" not "given that", "but" not "however". Read a
paragraph aloud; if you run out of breath before the period, split it. Real
field names, real commit hashes, real line numbers over generic placeholders.

Zero em dashes of your own. Where one would go, put a period, a comma, or
parentheses. A line quoted from the source keeps whatever characters it has.
Search the draft for `—` before sending: every hit should sit inside a quote.

A few phrases announce significance instead of showing it: "load-bearing",
"worth stating plainly", "here's the honest truth", "the real tension". Scan
for them in the same pass, but each hit is a candidate rather than a verdict.
Keep one only where it does work the specific statement cannot, and the
specific statement is usually available: which line breaks, which field
decides, which call is slow.

An analogy comes after the mechanism, never instead of it. Say what the code
does in its own nouns first; if the analogy still adds something, it gets one
sentence.

Instead of: "The mechanism by which the identity is resolved to a durable
record is mediated through a registration call that the file service exposes,
which itself branches internally on a content hash in order to determine
whether deduplication should occur."

Write: "The API hands the file service an identity. The service hashes the
file's bytes. If it has seen that hash before, it reuses the old record instead
of creating a new one."

## If the story involves

- **A library or framework's behaviour**: the installed source can be pinned
  and stale, so also read the current official docs. Cite both when they agree;
  say which you trust when they differ.
- **A worked example**: grep for a real caller first. None exists: say so
  ("grepped for X, only the definition, no caller yet"), then build one from
  real names and values, labelling the parts you constructed.
- **A yes/no clarification**: the direct answer first ("Yes, that's the claim" /
  "No, it's actually…"), then the receipt.
- **An explanation that didn't land**: don't restate it in the same words, that
  only repeats whatever missed. Drop a layer: a smaller unit, real values
  traced through one concrete case end to end. Re-explain the piece their
  answer exposed, not the whole story. If that piece carries a code they can
  name it ("F2 didn't land") rather than quote the paragraph back.
- **A document rather than code**: the shape still holds, so `## The problem`
  carries the need the document answers and the one idea it rests on goes in
  the paragraph under it, in prose. Organise the pieces by that argument.
  Reusing the source's own headings, in its own order, produces a table of
  contents rather than an explanation, whether they arrive as bullets or as
  your section headers. The receipts are quotes, and the reader should be able
  to state the argument in a sentence afterwards.
