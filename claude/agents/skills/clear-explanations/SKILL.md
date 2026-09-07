---
name: clear-explanations
description: Use when a person wants to end up understanding a mechanism, not just receive an answer: "how does X work", "walk me through Y", "explain this code", "why does this break". For a standalone written artifact (doc, ADR, ticket, commit body, docstring) use explaining instead.
---

# Clear explanations

The goal is a story the reader can rebuild from memory tomorrow, not a set of
true statements they can only nod at. Coverage is not clarity.

## When this applies

Use this when someone wants to understand a mechanism well enough to reason
about it afterwards.

The boundary is the artifact, not the question. `explaining` owns anything
written to stand alone with no reader in the room: a doc, an ADR, a ticket, a
commit body, a docstring.

**A direct question inside a walkthrough does not hand off.** Asked to confirm a
claim, or asked anything that takes a yes or a no, answer it in the first
sentence and then carry on teaching. "Yes, the hash is what decides" comes
before the paragraph on which hash. A fresh walkthrough offered in place of the
answer reads as dodging. Abandoning the walkthrough is worse, because it drops
branch-sourcing and re-verification at the moment they matter most.

## The shape

Same skeleton every time, in this order, so the reader can tell from the headers
alone which part of the story they are in.

1. `## The problem`. One paragraph, no code. The need, or what breaks without
   the thing.
2. `## <name of the piece>`. One header per new piece, in build order, named for
   what the piece is or does. Open each by naming the gap the previous one left
   open.
3. `## Side by side`. Only when two things are being compared, and only after
   each is explained on its own. Name the axis they differ on.
4. `## The point, restated`. One or two plain sentences answering the question
   that was actually asked. No new material here.
5. A closing question. Not a header. The last paragraph.

Never label a section `Layer 1`, `Part A` or `Step 2`. The number tells the
reader its position on the page, which the page already told them. The header
should say what is in the box.

Skip a section only when there is nothing for it to hold: no second thing to
compare, no diagram to draw. Never skip the problem, never skip the closing
question, never reorder.

## The moves

**Say what each piece buys.** Introduce one piece, let it land, then add the next
one framed as "this alone is not enough, because". Each piece closes a gap the
last one visibly left. Nobody holds five new abstractions on first pass.

**Ground new things in what you have already built, not in vocabulary you assume.**
A comparison saves the reader work only if they already own the other side of it.
Trading a metaphor for a term of art does not fix that, it relocates it: now they
may need to ask what a mixin is, then what inheritance is, and one explanation
has spawned three. Reach first for the thing you explained a paragraph ago,
because that idea is already paid for. Reach next for their own code, and point
at the line rather than naming the pattern in the abstract. Only then reach
outside, and define the word in the same breath you use it, so it never sits
there as its own open question.

**Name the mechanism at every branch, not the outcome.** "The loop knows when to
stop" is not an explanation. Say which field or check is tested, where its value
comes from, and what produces it. This matters most where two systems look
parallel, because each can reach stop-or-continue through a different kind of
signal, a value comparison on one side and a structural check on message
contents on the other. Calling those the same idea collapses the moment someone
asks where the value comes from. Source every branch condition, on every side
being discussed, before building anything on top of it.

**Verify, and show the check inline.** Read the real code, grep the real data,
run git log or git show for a claim about history. For how a library behaves,
the installed source is not sufficient on its own: web-search that library's
current official documentation too. A pinned version goes stale and a comment in
the source can be aspirational, while the docs carry the contract the maintainers
intend across versions. Cite both when they agree and say that they agree. When
they disagree, say so and prefer the more authoritative one. If a claim is
questioned, re-verify source and docs before restating it. Saying it more
confidently is not a check.

Beware a check that cannot fail. A pattern that silently matches nothing looks
identical to a clean result, so confirm the tool can find what you are asking
about before trusting a zero.

**Find out whether the example exists before building one.** Grep for a caller
first. If there is none, say that plainly: "grepped for X, only the definition
exists, no caller yet". Then build the example from real material, a real field
name, a real fixture value, a real documented key, and mark which parts are
constructed. A constructed example passed off as an observed one is the most
expensive error available here, because the reader will go looking for it.

**Describe every part of a diagram you draw.** A small tree or data flow is
usually the moment it clicks, which is why it cannot be left to speak for
itself: alone, it invites the reader to invent a reading, and their reading can
diverge from yours. Every node, edge and label needs a sentence saying what it
represents and why it is drawn that way. Draw only what this explanation needs.
Treat the diagram as the summary of a walkthrough already given in words.

**Match depth to the question, not to what you know.** Before another section,
another snippet, another worked example, ask what it teaches that the last one
did not. Two walkthroughs of the same shape are coverage, not clarity: keep the
one that carries the point and compress the other to a single line. Everything
above `## The point, restated` should be there because the point needed it. When
unsure, cut, then check whether the point still lands. If it lands, the cut was
right.

**Close with a question that can fail.** Not "does that make sense?", which
collects a reflexive yes whether or not anything landed. Ask something specific
enough that a wrong or hesitant answer shows exactly which part missed: ask them
to restate the key distinction in their own words, or ask about the piece most
likely to be misread, the ambiguous edge in the diagram or the difference between
two things you just contrasted. Treat the answer as a signal to move on or to
re-explain that one piece.

## Prose

`explaining` carries the full standard and is worth reading before writing a
document. These rules are repeated here on purpose, because a chat walkthrough
loads this skill and may load nothing else.

No em dashes. Zero. A comma, a full stop or a colon does the same work and reads
as though a person wrote it.

One idea to a sentence, one idea to a paragraph. Present tense. Active voice:
"the store hashes the bytes", not "the bytes are hashed by the store".

Plain words over formal ones: "use" not "utilise", "since" not "given that",
"but" not "however". Cut on sight: "it is important to note", "in order to",
"leverage", "simply", "basically", "essentially", "robust", "seamless". That
list sits under a rule that outranks it, drop the throat-clearing and keep every
clause that carries weight, so a hit is a candidate and not yet a verdict.

Read a paragraph aloud. If you run out of breath before the full stop, it is too
long for someone hearing it for the first time.

A sentence that needs a comma, a semicolon and two subordinate clauses is
usually three sentences wearing one costume.

Not this:

> The mechanism by which the identity is resolved to a durable record is
> mediated through a registration call that the file store exposes, which itself
> branches internally on a content hash in order to determine whether
> deduplication should occur.

This:

> The upload API hands the file store an identity. The store hashes the file's
> bytes. If it has seen that hash before, it reuses the old record instead of
> creating a new one.

Same fact. Three short sentences, active voice, and the branch is now something
the reader can hold onto.

## The test

Read the headers alone. They should tell the story in order, name real pieces,
and carry no numbers.

Then check the two failures the shape does not catch on its own, because both
read fine and teach nothing. Every branch condition is sourced to a named field
and whatever produces it. Every part of every diagram has a matching sentence.
