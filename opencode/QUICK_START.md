# 🚀 Quick Start Guide: Obsidian Agent System

**Created**: 31 December 2025  
**Ready to use**: ✅ Yes!

## Step-by-Step First Use

### 1️⃣ Launch OpenCode with Obsidian Agent (2 minutes)

**Option A: Start new session**
```bash
cd ~/code/obsidian
opencode
```

**Option B: Continue existing session**
```bash
# In your current OpenCode session
# Press Tab to cycle to 'obsidian' agent
```

**Verify**: You should see "obsidian" as the active agent in the UI

---

### 2️⃣ Test Each Skill (10 minutes)

Try these four commands to verify everything works:

#### Test 1: Add to Today's Note
```
You: "Add to today: Testing the new Obsidian agent system - works brilliantly!"

Expected result: 
✓ Agent appends timestamped note to DailyNotes/2025-12-31.md
✓ Uses current time in HH:MM format
✓ Maintains existing content
```

**Verify**: Open `~/code/obsidian/rememberme/DailyNotes/2025-12-31.md` and check the entry was added

---

#### Test 2: Review Tasks
```
You: "Review my tasks from this week"

Expected result:
✓ Scans DailyNotes/ for past 7 days
✓ Extracts incomplete tasks (- [ ])
✓ Groups by date with [[links]]
✓ Asks if you want to carry forward
```

**Verify**: Check if tasks from 2025-12-29.md and 2025-12-30.md appear

---

#### Test 3: Create Research Note
```
You: "Create research note on Mixture of Experts (MoE) architecture"

Expected result:
✓ Creates Pages/Mixture of Experts.md
✓ Uses structured template (Summary, Key Insights, etc.)
✓ British English spelling throughout
✓ Adds relevant tags [research, ML, MoE]
```

**Verify**: Check `~/code/obsidian/rememberme/Pages/` for the new note

---

#### Test 4: Create Blog Draft
```
You: "Write blog post about optimising LLM inference for production"

Expected result:
✓ Creates Tweets/{Title}.md
✓ Structured: Introduction, Main Sections, Conclusion
✓ British English (optimising, analyse, whilst)
✓ SEO description under 160 characters
✓ Status: draft
```

**Verify**: Check `~/code/obsidian/rememberme/Tweets/` for the draft

---

### 3️⃣ Integrate Into Your Daily Workflow (Ongoing)

Here's how to use the system daily:

#### Morning Routine (5 minutes)
```
1. Open OpenCode in your vault directory
2. Switch to 'obsidian' agent (Tab key)
3. "Review my tasks" - see what's pending
4. "Add to today: [Your morning plan]"
```

#### During the Day (As needed)
```
Quick captures:
- "Add note: Interesting insight about transformers..."
- "Quick capture: Need to research prompt caching"
- "Jot down: Meeting with [person] about [topic]"
```

#### Research Sessions
```
When reading papers:
- "Create research note for [Paper Title]"
- Agent creates structured note in Pages/
- You fill in details whilst reading
```

#### Content Creation
```
When planning blog posts:
- "Write blog about [topic]"
- Agent creates draft with structure
- You refine and expand
```

#### Weekly Review (Fridays)
```
End of week:
- "Review my tasks"
- Carry forward incomplete items
- Plan next week in today's note
```

---

## 🎯 Real-World Examples

### Example 1: Learning Session
```
You: "Add to today: Starting to learn about LoRA fine-tuning"
Agent: ✓ Added at 09:15

[After reading paper]
You: "Create research note on LoRA"
Agent: ✓ Created Pages/LoRA Low-Rank Adaptation.md

[Later]
You: "Write blog explaining LoRA for beginners"
Agent: ✓ Created Tweets/Understanding LoRA Fine-tuning.md
```

### Example 2: Task Management
```
Monday:
You: "Review my tasks"
Agent: Found 8 tasks from last week...

You: "Yes, carry forward"
Agent: ✓ Added to today under "Tasks from Previous Days"

Friday:
You: "Review my tasks"
Agent: Found 3 incomplete tasks this week...
[You decide what to carry to next week]
```

### Example 3: Research Workflow
```
You: "Create research note for 'Retrieval-Augmented Generation' paper"
Agent: ✓ Created Pages/Retrieval-Augmented Generation.md

You: "Add to today: Key insight from RAG paper - separating parametric from non-parametric knowledge"
Agent: ✓ Added at 14:30

You: "Create research note on vector databases for RAG"
Agent: ✓ Created Pages/Vector Databases for RAG.md
[Auto-links to RAG note]
```

---

## 🔧 Customisation Tips

### Personalise Your Workflow

1. **Morning template**: Create a template in your daily note for consistent structure
2. **Tag system**: The agent learns from your existing tags - keep them consistent
3. **Linking habits**: Agent suggests links - accept them to build your knowledge graph
4. **Blog voice**: After a few blogs, the agent learns your style

### Keyboard Shortcuts

Learn these OpenCode shortcuts:
- `Tab` - Switch between agents
- `Ctrl+D` / `Ctrl+U` - Scroll chat (Vim-style, from your config)
- `Ctrl+P` - Command palette

---

## 📋 Daily Checklist

Copy this to your daily note template if helpful:

```markdown
## Daily Agent Tasks
- [ ] Review incomplete tasks from past week
- [ ] Add morning plan/goals
- [ ] Capture quick notes throughout day
- [ ] Create research notes for papers read
- [ ] Update blog drafts in progress
```

---

## ⚠️ Important Notes

### What the Agent Does
✅ Appends to existing daily notes (created by Obsidian plugin)  
✅ Creates new notes in correct folders  
✅ Uses British English exclusively  
✅ Links to related notes proactively  
✅ Suggests relevant tags  

### What the Agent Doesn't Do
❌ Create daily notes (Obsidian plugin does this)  
❌ Modify existing content without permission  
❌ Use bash commands (disabled for safety)  
❌ Edit .obsidian/ folder  
❌ Use American English spelling  

---

## 🐛 Troubleshooting

### Issue: "Agent not found"
**Fix**: Press `Tab` to cycle to obsidian agent, or restart OpenCode

### Issue: "Daily note doesn't exist"
**Fix**: 
1. Open Obsidian first to let plugin create today's note
2. Or manually create `DailyNotes/YYYY-MM-DD.md`

### Issue: "Skill not loading"
**Fix**: Check `~/.config/opencode/opencode.jsonc` has skill permissions

### Issue: American spelling appears
**Fix**: This is a bug - report it. All content should be British English

### Issue: Links not working
**Fix**: Ensure note titles match exactly (case-sensitive)

---

## 📚 Learning Resources

1. **Full Documentation**: `~/.config/opencode/OBSIDIAN_AGENT_README.md`
2. **OpenCode Docs**: https://opencode.ai/docs/agents/
3. **Skills Reference**: Check each `skill/*/SKILL.md` file

---

## 🎓 Advanced Usage (Later)

Once comfortable, explore:

1. **Custom workflows**: Combine skills (review tasks → add to research note)
2. **Bulk operations**: "Create research notes for all papers in my reading list"
3. **Cross-references**: "Find all notes related to transformers"
4. **Weekly summaries**: "Summarise my research progress this week"

---

## ✅ Success Criteria

After one week, you should:
- [ ] Have 7 daily notes with timestamped entries
- [ ] Created 2-3 research notes for papers/topics
- [ ] Drafted 1 blog post
- [ ] Used task review at least twice
- [ ] Feel comfortable switching to obsidian agent
- [ ] See improved vault organisation and linking

---

## 🚦 Your Action Plan Right Now

**Next 30 minutes**:
1. ✅ Launch OpenCode in `~/code/obsidian`
2. ✅ Switch to `obsidian` agent (Tab key)
3. ✅ Run all 4 test commands above
4. ✅ Verify each skill works correctly
5. ✅ Open Obsidian and check created files

**This week**:
- Use daily for capturing thoughts
- Create 1-2 research notes
- Try task review on Friday
- Draft a blog post about something you learnt

**Feedback loop**:
- Note any British English errors
- Track which skills you use most
- Identify missing features you'd like
- Adjust your workflow based on what works

---

**Ready?** Open your terminal and start with: `cd ~/code/obsidian && opencode`

Then type: "Add to today: Started using my new Obsidian agent system! 🚀"

Good luck! 🇬🇧
