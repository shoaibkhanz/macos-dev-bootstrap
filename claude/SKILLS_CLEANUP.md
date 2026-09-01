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

# Skills sync — 2026-07-30

Refreshed the Matt Pocock set against upstream and brought the plannotator
commands back as skills.

## Renamed upstream (2)

- `to-prd` → `to-spec` (folder was already `to-spec/`; only the skill name and
  description lagged behind)
- `to-issues` → `to-tickets` — tickets now declare their blocking edges, as
  text in the local file or as native blocking links on a real tracker

## Re-added as skills (3)

`plannotator-annotate`, `plannotator-last`, `plannotator-review` — previously
deleted in the 2026-07-04 pass, then reintroduced as slash commands under
`claude/commands/`. They now live in `claude/agents/skills/` like everything
else, each with an `agents/openai.yaml` and `disable-model-invocation: true`
so they only run when asked for by name. The three `claude/commands/plannotator-*.md`
files are gone.

## Refreshed in place

ask-matt, grilling, handoff, implement, prototype (SKILL/LOGIC/UI),
setup-matt-pocock-skills, to-spec, to-tickets, writing-great-skills.

Notable behaviour change in `setup-matt-pocock-skills`: it now leads each
section with the recommended answer, skips Section B when `triage` isn't
installed, and skips the monorepo question unless it finds monorepo signals.

# Skills sync — 2026-08-23

Re-vendored both collections from upstream HEAD. Vendored copies were verbatim
with no local edits, so every existing skill was replaced wholesale
(`rsync -a --delete`) rather than merged.

| Collection | Upstream commit | Version |
|---|---|---|
| obra/superpowers | `b36e082` (2026-08-12) | v6.3.0 |
| mattpocock/skills | `5b15a47` (2026-08-21) | v1.2.3 |

## Result: 48 skills (was 45)

- **14** Superpowers (full current set, unchanged names)
- **28** Matt Pocock (engineering 18, misc 4, productivity 6 + `wait-what`)
- **3** plannotator (local)
- **2** local — `authoring-longform-briefs`, `code-hyperlearning` (symlink)

## Renamed upstream (1)

- `writing-great-skills` → `writing-for-agents` (breaking, no alias). Scope
  widened from skills to any agent-consumed document, including `AGENTS.md` /
  `CLAUDE.md`. `GLOSSARY.md` is merged into `SKILL.md`; the skill-only
  mechanics (frontmatter, invocation choice, router skills) moved to
  `SKILL-MECHANICS.md`. Now model-invoked, so it fires while editing skills
  instead of only on request.

## Added — graduated out of `in-progress/` (3)

- `wizard` (engineering, **model-invoked**) — generates an interactive bash
  script that walks a human through steps only a human can do: dashboards,
  credentials, CI secrets, one-off cutovers. Bundles `template.sh`.
- `to-questionnaire` (productivity) — turns a decision you can't answer alone
  into a Markdown questionnaire for the person who can.
- `wait-what` (productivity) — one-word corrective for model verbosity;
  re-pitches the last message in Simplified Technical English.

## Renamed upstream files

- `test-driven-development/testing-anti-patterns.md` →
  `writing-good-tests.md`, rebuilt as a positive catalog with a falsifiability
  discipline (name the production change that would fail the test) and hard
  stops for the string-presence and change-detector traps.

## New files inside existing skills

- `agents/openai.yaml` beside every Matt Pocock `SKILL.md` — Codex metadata, so
  one vendored copy serves both harnesses. User-invoked skills carry
  `policy.allow_implicit_invocation: false`, the Codex analog of
  `disable-model-invocation`.
- `ask-matt/PHASE-BOUNDARIES.md` — the reasoning behind the new five-option
  decision tree (continue, `/clear`, `/handoff`, subagent, `/compact`).
- `subagent-driven-development/re-review-prompt.md` — scoped re-review so a
  fix round checks the fixes, not the whole task.
- `using-superpowers/references/{gemini,hermes}-tools.md` — Gemini CLI support
  restored, Hermes Agent added. `pi-tools.md` is upstream, not a local patch.

## Notable behaviour changes

- **brainstorming** classifies requests as spike / bounded / architectural;
  small tasks skip the two-document ritual.
- **subagent-driven-development** workspace is plan-scoped
  (`.superpowers/sdd/<plan>/`), controllers rule on non-catastrophic plan
  conflicts instead of stalling, same-shape tasks batch into one dispatch, and
  implementers/reviewers may not spawn their own subagents.
- **finishing-a-development-branch** no longer offers to discard finished work,
  and refuses to `--force` a worktree removal over uncommitted files.
- **diagnosing-bugs** redacts secrets first on every command, output and
  captured artifact.
- **improve-codebase-architecture** scopes exploration with a YAGNI filter —
  the last ~20 commits bias it toward actively-developed paths.
- **prototype** emits one self-contained shareable HTML file and parks the
  exploration on a `prototype/<name>` branch instead of deleting it.
- **wayfinder** names its unit a *decision ticket* and burns research tickets
  down with parallel `/research` subagents.
- **code-review**, **codebase-design**, **improve-codebase-architecture** drop
  Claude-Code-specific tool and agent-type names from their dispatch steps.

## Live symlinks

Rebuilt `~/.claude/skills/` the way `install.sh --claude` does. Removed the
dangling `writing-great-skills` link; linked the four new skills; converted the
three `plannotator-*` entries from stale real directories (predating the
`agents/openai.yaml` addition) into repo symlinks. Non-repo skills in that
directory — `learned`, `plaud-*` — were left untouched.
