# Skills cleanup — 2026-07-04

Trimmed the vendored skills in `claude/agents/skills/` down to two curated
sources plus personal skills, and refreshed everything to the latest upstream.

## Sources of truth

| Collection | Repo | Install / update |
|---|---|---|
| Superpowers (Jesse Vincent / obra) | https://github.com/obra/superpowers | `/plugin install superpowers@claude-plugins-official` — vendored here under `claude/agents/skills/` |
| Matt Pocock — "Skills for Real Engineers" | https://github.com/mattpocock/skills | `npx skills@latest add mattpocock/skills` — vendored here |

Vendored (copied into this repo) rather than plugin-installed, to match the
existing dotfiles pattern where `install.sh` symlinks each skill into
`~/.claude/skills/` and `~/.agents/skills`.

## Result: 40 skills (was 57)

- **14** Superpowers (full current set)
- **25** Matt Pocock (engineering + productivity + misc)
- **1** personal — `code-hyperlearning` (symlink to `~/code/projects/code-hyperlearning`)

## Deleted (31)

Third-party / ML / diagram / cloud skills that belong to neither source, plus
the flagged skills chosen for removal:

**Third-party & domain (23):** aws-diagrams, computer-vision-opencv,
deep-learning, deep-learning-python, deep-learning-pytorch, eraser-diagrams,
excalidraw, excalidraw-diagram-generator, gcp-development, git-commit,
find-skills, jax-best-practices, machine-learning, mermaid-diagrams,
nlp-natural-language-processing, pydantic-ai-development, pytorch,
scikit-learn-best-practices, supabase-postgres-best-practices,
terraform-diagrams, terraform-skill, transformers-huggingface,
web-design-guidelines

**Flagged, removed by choice (6):** caveman, plannotator-annotate,
plannotator-compound, plannotator-last, plannotator-review, zoom-out

**Renamed upstream (2) — old names removed, new names added:**
- `diagnose` → `diagnosing-bugs`
- `write-a-skill` → `writing-great-skills`

## Added — new from latest upstream (14)

ask-matt, codebase-design, diagnosing-bugs, domain-modeling,
git-guardrails-claude-code, grilling, implement, migrate-to-shoehorn, research,
resolving-merge-conflicts, scaffold-exercises, setup-pre-commit, teach,
writing-great-skills

## Refreshed in place (kept name, latest content)

Superpowers: brainstorming, dispatching-parallel-agents, executing-plans,
finishing-a-development-branch, receiving-code-review, requesting-code-review,
subagent-driven-development, systematic-debugging, test-driven-development,
using-git-worktrees, using-superpowers, verification-before-completion,
writing-plans, writing-skills

Matt Pocock: code-review, grill-me, grill-with-docs, handoff,
improve-codebase-architecture, prototype, setup-matt-pocock-skills, tdd,
to-issues, to-prd, triage

## Not vendored from Matt Pocock (available if wanted)

- `personal/` — edit-article, obsidian-vault (Matt-specific)
- `deprecated/` — design-an-interface, qa, request-refactor-plan, ubiquitous-language
- `in-progress/` — claude-handoff, loop-me, wayfinder, wizard, writing-beats, writing-fragments, writing-shape (experimental)

## Live symlink fix

`~/.claude/skills/` had 38 dangling symlinks pointing at a deleted Conductor
worktree (`~/conductor/workspaces/macos-dev-bootstrap/dublin/...`). All live
skill symlinks were rebuilt to point at this repo
(`~/code/macos-dev-bootstrap/claude/agents/skills/<name>`).
