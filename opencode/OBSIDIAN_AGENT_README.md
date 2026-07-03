# Obsidian Agent System for OpenCode

**Status**: ✅ Fully Configured and Ready to Use  
**Language**: British English  
**Vault Path**: `~/code/obsidian/rememberme/`

## Overview

This system provides a focused Obsidian vault assistant with four essential skills for your daily workflow as an ML engineer. All content is generated in British English.

## Quick Start

1. **Switch to Obsidian agent**: Press `Tab` in OpenCode to cycle to the `obsidian` agent
2. **Use naturally**: Just talk to the agent about your Obsidian needs
3. **Skills load automatically**: The agent will use the appropriate skill based on your request

## Available Skills

### 1. Today Note (`today-note`)
**Purpose**: Add timestamped entries to today's daily note

**How to use**:
- "Add note about transformer architecture"
- "Quick capture: need to organise experiment results"
- "Jot down: interesting paper on RAG"

**What it does**:
- Opens existing daily note (created by Obsidian plugin)
- Adds timestamp in HH:MM format
- Appends your note in British English

**Location**: `DailyNotes/YYYY-MM-DD.md`

---

### 2. Task Review (`task-review`)
**Purpose**: Review incomplete tasks from the past week

**How to use**:
- "Review my tasks"
- "What tasks are incomplete?"
- "Check pending todos"

**What it does**:
- Scans past 7 days of daily notes
- Extracts all `- [ ]` incomplete tasks
- Groups by date with `[[wiki-links]]` to source
- Asks if you want to carry forward to today

**Example output**:
```
📋 Task Review (Past 7 Days)

Found 5 incomplete tasks:

From [[2025-12-30]]:
- [ ] Complete data sampling section in [[Build a Large Language Model]]
- [ ] Review RAG architectures

From [[2025-12-28]]:
- [ ] Prepare for Governance document ([[BBYH-ML-Platform]])

Carry forward to today? (y/n)
```

---

### 3. Research Note (`research-note`)
**Purpose**: Create structured research notes for papers and technical topics

**How to use**:
- "Create research note for 'Attention Is All You Need'"
- "Take notes on RAG architectures"
- "Summarise the LoRA paper"

**What it does**:
- Creates structured note in `Pages/` folder
- Includes: Summary, Key Insights, Methodology, Results, Questions, References
- Adds relevant tags (research, ML, papers, etc.)
- Links to related notes in vault
- Uses British English throughout

**Location**: `Pages/{Topic or Paper Title}.md`

**Template sections**:
- Summary (2-3 sentence overview)
- Key Insights (main contributions)
- Methodology (approach used)
- Results (findings and metrics)
- Related Work (links to vault notes)
- Questions (further exploration)
- References (citations, URLs)

---

### 4. Blog Draft (`blog-draft`)
**Purpose**: Create technical blog posts with SEO and British English

**How to use**:
- "Create blog post about fine-tuning LLMs with LoRA"
- "Write blog explaining transformer attention"
- "Start blog on RAG systems"

**What it does**:
- Creates blog draft in `Tweets/` folder
- Structures with: Introduction, Main Sections, Conclusion
- Adds SEO-friendly frontmatter
- Includes relevant tags and `[[wiki-links]]`
- Uses British English spelling and phrasing
- Sets status as "draft"

**Location**: `Tweets/{Title}.md`

**Features**:
- SEO description (under 160 characters)
- Proper heading hierarchy
- Code examples with syntax highlighting
- Links to related vault notes
- Professional yet approachable tone

---

## Agent Configuration

**Name**: `obsidian`  
**Mode**: Primary  
**Temperature**: 0.3 (balanced)

**Tools Enabled**:
- ✅ read (search and analyse vault)
- ✅ write (create new notes)
- ✅ edit (modify existing notes)
- ✅ grep (find content)
- ✅ glob (find files)
- ✅ skill (load specialised workflows)
- ❌ bash (disabled for safety)

**Permissions**:
- **Edit**: Allow (can modify all files in vault)
- **Note**: The agent is instructed to only edit markdown files and avoid `.obsidian/` directory
- **Bash**: Disabled for safety

---

## British English Guidelines

All generated content uses British English:

**Spelling**:
- -ise: organise, analyse, optimise, realise, specialise
- -our: colour, favour, behaviour, labour
- -re: centre, metre, theatre, litre
- -ence: defence, licence (noun)
- -ll-: travelling, modelling, labelled, cancelled

**Vocabulary**:
- programme (events/plans), program (software code)
- whilst (formal), amongst
- mobile (not cell phone)
- CV (not resume)

---

## Vault Conventions

**Date Formats**:
- Filenames: `YYYY-MM-DD` (e.g., `2025-12-31.md`)
- Headings: `31 December 2025`
- Frontmatter: `date: '2025-12-31'`

**Links**: `[[wiki-links]]` format only

**Tasks**: 
- Incomplete: `- [ ]`
- Complete: `- [x]`

**Timestamps**: `HH:MM` (24-hour)

**Frontmatter**: YAML with type, title, date, tags

---

## File Structure

```
~/.config/opencode/
├── opencode.jsonc              # Main configuration
├── agent/
│   └── obsidian.md            # Obsidian agent
├── prompts/
│   └── obsidian-context.txt   # Vault context
└── skill/
    ├── today-note/
    │   └── SKILL.md
    ├── task-review/
    │   └── SKILL.md
    ├── research-note/
    │   └── SKILL.md
    └── blog-draft/
        └── SKILL.md
```

---

## Example Workflows

### Morning Routine
```
You: "Add to today: Planning to work on transformer fine-tuning"
Agent: ✓ Added to 2025-12-31.md at 08:45
```

### Task Management
```
You: "Review my tasks"
Agent: [Scans past 7 days]
       Found 8 incomplete tasks from past week...
       Carry forward to today? (y/n)
You: "yes"
Agent: ✓ Added 8 tasks to today's note under "Tasks from Previous Days"
```

### Research Note
```
You: "Create research note for the LoRA paper"
Agent: ✓ Created Pages/LoRA Low-Rank Adaptation.md
       Added sections: Summary, Key Insights, Methodology, Results
       Linked to [[Learning LLMs]] and [[PEFT]]
```

### Blog Writing
```
You: "Write blog about RAG systems"
Agent: ✓ Created Tweets/Building Production RAG Systems.md
       Status: draft
       Includes: Introduction, Architecture, Implementation, Best Practices, Conclusion
       All in British English with SEO description
```

---

## Tips for Best Results

1. **Be Specific**: "Add note about transformer attention mechanisms" vs "add note"
2. **Natural Language**: Talk naturally - the agent understands context
3. **Review Suggestions**: When tasks are carried forward, review before accepting
4. **Link Proactively**: The agent will suggest `[[links]]` to related notes
5. **Iterate on Blogs**: Drafts are meant to be edited - the agent provides structure

---

## Troubleshooting

**Issue**: Agent not found  
**Solution**: Press `Tab` to cycle to obsidian agent, or restart OpenCode

**Issue**: Daily note not found  
**Solution**: Ensure Obsidian has created today's note (it auto-creates), or create manually

**Issue**: Skills not loading  
**Solution**: Check that skill permissions are set to "allow" in config

**Issue**: American spelling appearing  
**Solution**: Report this - all content should be British English

---

## Extending the System

To add more skills in future:

1. Create new directory: `~/.config/opencode/skill/{skill-name}/`
2. Create `SKILL.md` file with frontmatter and instructions
3. Add skill permission to `opencode.jsonc`
4. Restart OpenCode or reload configuration

---

## Version

- **Created**: 31 December 2025
- **System**: OpenCode with Obsidian Agent
- **Vault**: ~/code/obsidian/rememberme/
- **Skills**: 4 (today-note, task-review, research-note, blog-draft)
- **Language**: British English

---

## Support

For issues or enhancements:
1. Check skill definitions in `skill/*/SKILL.md`
2. Review agent prompt in `agent/obsidian.md`
3. Verify vault path in `prompts/obsidian-context.txt`
4. Consult OpenCode docs: https://opencode.ai/docs/

---

**Ready to use!** Switch to the `obsidian` agent and start managing your vault with British English precision. 🇬🇧
