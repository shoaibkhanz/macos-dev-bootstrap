# OpenCode Permissions Configuration Note

**Important**: Understanding how permissions work in OpenCode

## Edit Permissions

### ❌ NOT Supported (glob patterns)
```json
"permission": {
  "edit": {
    "**/*.md": "allow",
    ".obsidian/**": "deny"
  }
}
```

### ✅ Correct Approach
```json
"permission": {
  "edit": "allow"  // or "ask" or "deny"
}
```

**Why**: The `edit` permission only supports simple values:
- `"allow"` - Allow all edits
- `"ask"` - Prompt before each edit
- `"deny"` - Disable editing

**Protection**: Instead of using permissions to restrict which files can be edited, we rely on:
1. **Agent instructions**: The agent is explicitly told in its prompt to only edit `.md` files
2. **Tool limitations**: The agent doesn't have `bash` access, reducing risk
3. **Vault-specific context**: The agent knows the vault structure and respects it

## Bash Permissions

### ✅ Glob patterns ARE supported here
```json
"permission": {
  "bash": {
    "git push": "ask",
    "rm -rf *": "deny",
    "*": "allow"
  }
}
```

**For Obsidian agent**: We've disabled bash entirely for safety
```json
"tools": {
  "bash": false
}
```

## Skill Permissions

### ✅ Specific skill names supported
```json
"permission": {
  "skill": {
    "today-note": "allow",
    "task-review": "allow",
    "research-note": "allow",
    "blog-draft": "allow",
    "other-skill": "deny"
  }
}
```

## Current Configuration Summary

**In `opencode.jsonc`**:
```json
{
  "agent": {
    "obsidian": {
      "tools": {
        "bash": false,    // No bash access
        "edit": true      // Can use edit tool
      },
      "permission": {
        "edit": "allow",  // Simple allow (no globs)
        "skill": {
          "today-note": "allow",
          "task-review": "allow",
          "research-note": "allow",
          "blog-draft": "allow"
        }
      }
    }
  }
}
```

**In `agent/obsidian.md` frontmatter**:
```yaml
permission:
  edit: "allow"
  skill:
    "today-note": "allow"
    "task-review": "allow"
    "research-note": "allow"
    "blog-draft": "allow"
```

## Safety Measures

Even with `edit: "allow"`, the system is safe because:

1. **No bash access**: Can't run destructive commands
2. **Agent instructions**: Explicitly told to only edit markdown files in vault
3. **Context awareness**: Agent understands vault structure and respects it
4. **Skill-based**: Most operations go through well-defined skills
5. **Read-first policy**: Agent reads files before modifying

## If You Need More Restriction

If you want the agent to ask before each edit:

```json
"permission": {
  "edit": "ask"  // Prompt for confirmation
}
```

This will ask you before any file modification.

---

**Last Updated**: 31 December 2025  
**Status**: Current configuration is correct and safe ✅
