#!/bin/bash

# Test script for Obsidian Agent System
# Run this to verify your setup is correct

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Testing Obsidian Agent System Configuration           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Check OpenCode installation
echo -e "${YELLOW}[1/7]${NC} Checking OpenCode installation..."
if command -v opencode &> /dev/null; then
    VERSION=$(opencode --version 2>/dev/null)
    echo -e "${GREEN}✓${NC} OpenCode installed: v${VERSION}"
else
    echo -e "${RED}✗${NC} OpenCode not found. Install from: https://opencode.ai"
    exit 1
fi

# Test 2: Check config file
echo -e "${YELLOW}[2/7]${NC} Checking configuration file..."
if [ -f ~/.config/opencode/opencode.jsonc ]; then
    echo -e "${GREEN}✓${NC} Config file exists: opencode.jsonc"
else
    echo -e "${RED}✗${NC} Config file missing"
    exit 1
fi

# Test 3: Check agent file
echo -e "${YELLOW}[3/7]${NC} Checking obsidian agent..."
if [ -f ~/.config/opencode/agent/obsidian.md ]; then
    echo -e "${GREEN}✓${NC} Agent file exists: agent/obsidian.md"
else
    echo -e "${RED}✗${NC} Agent file missing"
    exit 1
fi

# Test 4: Check skills
echo -e "${YELLOW}[4/7]${NC} Checking skills..."
SKILLS=("today-note" "task-review" "research-note" "blog-draft")
SKILL_COUNT=0
for skill in "${SKILLS[@]}"; do
    if [ -f ~/.config/opencode/skill/$skill/SKILL.md ]; then
        echo -e "${GREEN}  ✓${NC} $skill"
        ((SKILL_COUNT++))
    else
        echo -e "${RED}  ✗${NC} $skill (missing)"
    fi
done

if [ $SKILL_COUNT -eq 4 ]; then
    echo -e "${GREEN}✓${NC} All 4 skills present"
else
    echo -e "${RED}✗${NC} Only $SKILL_COUNT/4 skills found"
    exit 1
fi

# Test 5: Check vault exists
echo -e "${YELLOW}[5/7]${NC} Checking Obsidian vault..."
if [ -d ~/code/obsidian/rememberme ]; then
    NOTE_COUNT=$(find ~/code/obsidian/rememberme -name "*.md" -type f | wc -l | tr -d ' ')
    echo -e "${GREEN}✓${NC} Vault exists: ~/code/obsidian/rememberme"
    echo -e "${GREEN}  ✓${NC} Found ${NOTE_COUNT} markdown files"
else
    echo -e "${RED}✗${NC} Vault not found at ~/code/obsidian/rememberme"
    exit 1
fi

# Test 6: Check DailyNotes folder
echo -e "${YELLOW}[6/7]${NC} Checking DailyNotes folder..."
if [ -d ~/code/obsidian/rememberme/DailyNotes ]; then
    DAILY_COUNT=$(ls ~/code/obsidian/rememberme/DailyNotes/*.md 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}✓${NC} DailyNotes folder exists"
    echo -e "${GREEN}  ✓${NC} Found ${DAILY_COUNT} daily notes"
else
    echo -e "${RED}✗${NC} DailyNotes folder missing"
    exit 1
fi

# Test 7: Check template
echo -e "${YELLOW}[7/7]${NC} Checking templates..."
if [ -f ~/code/obsidian/rememberme/Templates/DailyNoteTemplate.md ]; then
    echo -e "${GREEN}✓${NC} Daily note template exists"
else
    echo -e "${YELLOW}⚠${NC}  Daily note template not found (optional)"
fi

# Summary
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                  ✅ ALL TESTS PASSED                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Your Obsidian Agent System is ready to use!${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "1. cd ~/code/obsidian"
echo "2. opencode"
echo "3. Press Tab to switch to 'obsidian' agent"
echo "4. Try: \"Add to today: Testing the new system!\""
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  Quick Start: ~/.config/opencode/QUICK_START.md"
echo "  Full Docs:   ~/.config/opencode/OBSIDIAN_AGENT_README.md"
echo ""
