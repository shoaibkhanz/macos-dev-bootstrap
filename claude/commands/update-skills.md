---
name: update-skills
description: Update every skill in macos-dev-bootstrap from upstream (Matt Pocock, superpowers, every npx skills / skills.sh install), pull in new ones, log and commit
---

Repo: `~/code/macos-dev-bootstrap`. Run everything from there.

1. **Preview**: `claude/update-skills.py --check`. Nothing to update anywhere and
   nothing under "Needs attention": say so and stop.
2. **Update**: `claude/update-skills.py`. It copies, removes, stages the
   vendored skills by name, moves the pins in `claude/SKILLS_CLEANUP.md`, adds
   any newly installed third-party skill to `.gitignore`, updates the lock, and
   relinks. Read its whole output.
3. **Needs attention**, each line:
   - `LOCAL EDITS` / `PIN HELD`: show the user `diff -r` between their copy and
     upstream's, and ask whether to take upstream or keep theirs. Taking
     upstream means copying its folder over and rerunning step 2, which then
     moves the pin.
   - `CONFLICT`: a new upstream skill shares a name with one here. Ask.
   - `REFERENCES to removed …`: a renamed or deleted skill is still named
     elsewhere. Point each at the new name (the upstream commits show it).
   - `GONE UPSTREAM` / `NOT INSTALLED` / `UNKNOWN`: report; do not guess.
4. **Log**: append a dated `# Skills sync — YYYY-MM-DD` section to the end of
   `claude/SKILLS_CLEANUP.md` in the form of the previous one: old → new pin per
   upstream; updated, added, removed, each with what changed in a few words
   from the upstream commits; what was not taken and why; third-party updates.
5. **Commit and push**: `git add claude/SKILLS_CLEANUP.md .gitignore`, plus any
   file fixed in step 3. Never `git add -A`: other work may be in the tree. If
   `SKILLS_CLEANUP.md` already had unrelated uncommitted edits, stage only your
   lines. `git commit --no-verify`, then `git push origin main`.
6. **Report** in plain words: what updated, what is new, what was held back and
   why, and anything the user still has to decide.
