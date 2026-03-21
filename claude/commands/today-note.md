---
name: today-note
description: Open today's daily note and add timestamped entries in British English
---

## Add Entry to Today's Daily Note

**Today's Date**: Use the current date for all operations.

### Step 1: Locate Today's Note

1. Calculate today's date in `YYYY-MM-DD` format
2. Read the note at `~/code/projects/obsidian/rememberme/Calendar/Daily/YYYY-MM-DD.md`
3. If it doesn't exist, inform the user (daily notes are auto-created by Obsidian)

### Step 2: Populate Quick Learn (If Present)

If the Quick Learn section exists with placeholders, populate them:

```markdown
#### Quick Learn
CEO: word
Py: code
ML: concept
Arch: pattern
```

| Category | Placeholder | What to fill in |
|----------|-------------|-----------------|
| **CEO** | `word` | A business/leadership vocabulary word with brief definition |
| **Py** | `code` | A Python built-in, module, or idiom with a simple example (e.g., `itertools.chain`, `@property`) |
| **ML** | `concept` | An ML/AI concept or technique (e.g., dropout regularisation, attention mechanism) |
| **Arch** | `pattern` | A software architecture or design pattern (e.g., Circuit Breaker, CQRS) |

**Example** (populated):
```markdown
#### Quick Learn
CEO: Synergy — combined effort producing greater results than individual contributions
Py: `collections.defaultdict` — dict subclass that calls a factory function for missing keys
```python
from collections import defaultdict

d = defaultdict(list)
d['fruits'].append('apple')
d['fruits'].append('banana')
# d = {'fruits': ['apple', 'banana']}
```
ML: Batch normalisation — normalising layer inputs to stabilise and accelerate training
Arch: Saga pattern — managing distributed transactions via a sequence of local transactions
```

**Rules**:
- Only update if the section exists — if missing, skip entirely
- Only replace placeholder text (`word`, `code`, `concept`, `pattern`)
- Don't overwrite already-populated items
- Keep entries concise (one line each)
- Include brief explanation after an em dash (—)
- For Py: wrap code in backticks and include a full code snippet with import and usage example
- Vary topics daily

### Step 3: Add Timestamped Entry

1. Identify the appropriate section (usually Log or Capture)
2. Add entry with 24-hour timestamp format:

```markdown
14:35

New entry content here.
```

3. Ensure blank lines around the timestamp
4. Write in British English (organise, colour, centre, travelling)
5. Use `[[wiki-links]]` for internal references
6. Link people as `[[Firstname-Lastname]]`

### Step 4: Preserve Structure

- Do not modify other sections
- Keep frontmatter intact
- Maintain the navigation footer

### British English Reminders

- organise, analyse, optimise (not -ize)
- colour, favour, behaviour (not -or)
- centre, metre (not -er)
- travelling, modelling (double l)

## When to use me

- User asks to "add to today"
- User says "quick note", "capture this", "jot down"
- User wants to log something to daily note
- User asks to open today's note
- Natural language like "note to self"
- User asks for daily learning items or Quick Learn

## What NOT to do

- Do not create the daily note file (it already exists)
- Do not modify existing content (except Quick Learn placeholders)
- Do not change frontmatter
- Do not remove or edit timestamps from previous entries
- Do not use American English spelling
- Do not overwrite already-populated Quick Learn items
