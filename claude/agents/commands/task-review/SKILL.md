---
name: task-review
description: Review incomplete tasks from daily notes over the past week and optionally carry them forward
---

## What I do

1. Scan `~/code/projects/obsidian/rememberme/Calendar/Daily/` for the past 7 days
2. Extract all incomplete tasks (lines with `- [ ]`)
3. Group tasks by source date
4. Display summary with `[[wiki-links]]` to source notes
5. Ask if user wants to carry tasks forward to today
6. If yes, append to today's note under "## Tasks from Previous Days"

## How to Scan for Tasks

1. Calculate the past 7 days' dates in `YYYY-MM-DD` format
2. For each date, check if file exists: `Calendar/Daily/YYYY-MM-DD.md`
3. Use grep to find lines matching `- [ ]` (incomplete tasks)
4. Skip lines matching `- [x]` (completed tasks)
5. Preserve full task text including any `[[links]]` or tags

## Output Format

Present tasks grouped by date, most recent first:

```
📋 Task Review (Past 7 Days)

Found {N} incomplete tasks:

From [[2025-12-30]]:
- [ ] Complete data sampling section in [[Build a Large Language Model]]
- [ ] Review RAG architectures

From [[2025-12-28]]:
- [ ] Prepare for Governance document ([[BBYH-ML-Platform]])
- [ ] Update ML platform documentation

From [[2025-12-26]]:
- [ ] Research transformer optimisations

Carry forward to today? (y/n)
```

## Carrying Forward Tasks

If user says "yes" or "y":

1. Read today's note: `Calendar/Daily/{today's date}.md`
2. Check if "## Tasks from Previous Days" section exists
3. If not, add it after main content
4. Append each task with source date reference:

```markdown
## Tasks from Previous Days

- [ ] Complete data sampling section in [[Build a Large Language Model]] (from [[2025-12-30]])
- [ ] Review RAG architectures (from [[2025-12-30]])
- [ ] Prepare for Governance document ([[BBYH-ML-Platform]]) (from [[2025-12-28]])
```

## Behaviour Rules

1. **Only Incomplete Tasks**: Skip `- [x]` completed tasks
2. **Preserve Links**: Keep all `[[wiki-links]]` intact
3. **Preserve Tags**: Keep all #tags intact  
4. **Preserve Context**: Keep any text after the checkbox exactly as written
5. **No Duplicates**: Don't carry forward tasks already in today's note
6. **Source Attribution**: Add `(from [[YYYY-MM-DD]])` when carrying forward
7. **Chronological Order**: Show most recent incomplete tasks first
8. **Count Accurately**: Count and display total number found

## Date Calculation

Calculate the past 7 days from today:
- Today: 2025-12-31
- Past 7 days: 2025-12-30, 2025-12-29, 2025-12-28, 2025-12-27, 2025-12-26, 2025-12-25, 2025-12-24

## File Paths

- Daily notes location: `~/code/projects/obsidian/rememberme/Calendar/Daily/`
- Filename format: `YYYY-MM-DD.md`
- Full path example: `~/code/projects/obsidian/rememberme/Calendar/Daily/2025-12-31.md`

## British English

Use British English in all output:
- "Organise" not "organize"
- "Whilst" not "while" (formal contexts)
- "Summarise" not "summarize"

## Examples

**User**: "Review my tasks"
**Action**:
1. Scan past 7 days of Calendar/Daily/
2. Extract incomplete tasks
3. Display grouped summary
4. Ask about carrying forward

**User**: "What tasks are incomplete?"
**Action**: Same as above

**User**: "Check pending todos"
**Action**: Same as above

## Edge Cases

- **No incomplete tasks**: Display "No incomplete tasks found in the past 7 days. Well done! ✓"
- **Missing daily notes**: Skip dates where file doesn't exist (some days might not have notes)
- **Already carried forward**: If task text is identical to one already in today's note, skip it
- **Formatting variations**: Handle tasks with extra spaces, different indentation levels

## What NOT to do

- ❌ Don't modify the original daily notes
- ❌ Don't mark tasks as complete
- ❌ Don't remove tasks from source notes
- ❌ Don't duplicate tasks already in today's note
- ❌ Don't include completed tasks `- [x]`

## When to use me

- User asks to "review tasks"
- User says "check my todos"
- User wants to see "incomplete tasks"
- User asks "what's pending"
- User wants to "carry forward tasks"
