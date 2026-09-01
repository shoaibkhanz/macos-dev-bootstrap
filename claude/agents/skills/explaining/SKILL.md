---
name: explaining
description: Structure and prose standards for explaining something to a person. Use when writing a doc, an ADR, a ticket, a docstring, a commit body, a code review, or an answer in chat.
---

# How to explain

Two jobs, and they fail in different ways. The reader has to end up able to do
something, which is structure. Every sentence has to be worth the time it takes
to read, which is prose. A beautifully written explanation of the wrong thing is
still a waste, so structure comes first.

This covers docs, ADRs, tickets, docstrings and answers in chat.

## Part 1: structure

### Ask before you explain

An explanation aimed at the wrong question cannot be rescued by good writing. So
when the ask is ambiguous, ask.

One question at a time, with the options named, because a reader can pick from a
list faster than they can compose an answer. Ask about the thing that changes
what gets written, not about preferences you could pick yourself. If you can
settle it from the repo, settle it and say what you chose.

### Motivate the problem before the solution

Nobody wants the solution to a problem they do not have yet. Open with the
failure, in concrete terms, and let the rule arrive as the obvious consequence.

Take a rule that an eval writer must read the requirements and never the system
prompt. Open with the rule and you invite an argument about it. Open with the
failure and you do not: an eval writer who has read the system prompt writes the
tests that prompt visibly satisfies, and produces a green board that evidences
nothing. By the time the rule appears, the reader has already worked out that
they want it.

### Teach the model before the mechanism

A mechanism only makes sense inside a model. Give the shape of the thing, then
the parts.

Say a system has two legs joined by a confirmation: a person authoring at human
pace, then a machine building and judging in minutes. Give that shape first and
every module has a place to sit. Give the modules first and they are nothing but
files.

### Keep examples short, and carry one through

An example the reader cannot hold in their head is a second problem, not an
explanation. Short, concrete, and specific enough to be checkable.

Where a boundary is involved, give two examples, one on each side. To pin down
what counts as a red line, two rows are enough: "always escalate chest pain" is
a red line and contains no "never"; "never use American spelling" is not one and
does. The boundary stops being arguable, and the tempting shortcut of searching
for "never" dies with it.

Then reuse that example in the next section rather than introducing a fresh one.
The reader pays the setup cost once and spends the rest on the actual point.

### Build in steps, and say where the reader is

Each step should be small, and should work on its own. Prefer tracer bullets: a
plan of fourteen slices where every slice runs the whole path end to end, so
each one can be demonstrated rather than only assembled.

At each step, say what is now possible that was not possible before, and what
comes next. A reader who knows where they are standing will follow a long
explanation. A reader who does not will leave a short one.

### Meet the objection, and the next question

Say the tempting wrong thing out loud, then say why it loses. Leaving it unsaid
does not stop the reader thinking it; it only means they think it alone.

A module docstring for a semantic checker does this well. It records that the
checks were once regexes plus a window scanned backwards for negations, and it
says why that was tempting: fast, no provider needed, and it passed its own unit
tests. Then it says what it could not do. A reader who was about to suggest
regexes has been answered.

Finish a section by answering the question the reader is now holding, not the one
you had planned.

### Concrete before general, and no black boxes

Show the real value, the real shape, the real prompt. Carry the literal prompt a
domain expert can read, not a schema for prompts. Generalise afterwards, if at
all.

Open every abstraction once, at the point the reader first depends on it. After
that it can stay closed and be used by name.

## Part 2: prose

### No em dashes

Zero. Not in product copy, not in a docstring, not in a reply. A comma, a full
stop or a colon does the same work and reads as though a person wrote it.

Where a dash felt necessary the sentence was usually two sentences.

### Write like a book, not like a report

Short sentences. Plain words. Present tense. One idea to a paragraph, and the
paragraph ends when the idea does.

Brief does not mean compressed: drop the throat-clearing, keep every clause that
carries weight.

Cut on sight: "it is important to note", "in order to", "leverage", "utilise",
"simply", "just", "basically", "essentially", "robust", "seamless".

### Say why, and name what lost

What the code does is readable from the code. Why it does that is not, and it is
the only part worth writing down.

Every explanation of a choice carries the option that lost and the reason it
lost, and every number carries the measurement behind it. Without those a later
reader cannot tell a decision from a habit, and will change it back.

### Anchor a claim, or mark it

A claim about the tree names the file, and the line number when the exact line
is the point. A claim from memory or inference says which it is. "Measured on
2026-08-28" ages honestly; "as expected" does not.

Where an anchor could rot, give the term to search for rather than the line to
jump to.

### Lead with the answer

The first sentence answers the question. The reasoning follows for whoever wants
it, and whoever does not can leave.

Never open by restating the question, and never by summarising what is about to
be said.

### Tables carry verdicts, prose carries arguments

A table is for things of one shape: a status per ticket, a cost per option. An
argument does not fit in a cell and should not be folded into one to look tidy.

### No cheerleading

Say what holds and what does not. Confidence comes from the anchor, not from an
adverb. Good news needs no exclamation, bad news needs no apology, and neither
needs a preamble about how interesting it is.

## The test

Read it aloud. If it is not something you would say to a colleague standing at
your desk, write it again.

Then check the two jobs separately, because they fail separately: every rule in
Part 1 applied, every rule in Part 2 applied, and every anchor pointing at
something that exists.

One of those is mechanical and the rest are not. The em dash rule has no
exceptions, so search for the character and expect zero hits. The cut-on-sight
list bans senses rather than spellings, so a hit there is a candidate and not
yet a verdict: "they are nothing but files" keeps the restrictive sense "just"
was carrying, while "just run the migration" is the throat-clearing the list
exists to kill. Judge each hit, then cut or keep it deliberately.
