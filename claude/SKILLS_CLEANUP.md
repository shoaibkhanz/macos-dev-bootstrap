# Skills cleanup — 2026-07-04

Trimmed the vendored skills in `claude/agents/skills/` down to two curated
sources plus personal skills, and refreshed everything to the latest upstream.

## Sources of truth

| Collection | Repo |
|---|---|
| Superpowers (Jesse Vincent / obra) | https://github.com/obra/superpowers |
| Matt Pocock — "Skills for Real Engineers" | https://github.com/mattpocock/skills |

Vendored (copied into this repo) rather than plugin-installed, to match the
existing dotfiles pattern where `install.sh` symlinks each skill into
`~/.claude/skills/` and `~/.agents/skills`.

## How to sync (current procedure)

**Do not run either upstream's installer here.** `npx skills@latest add
mattpocock/skills` does not update the vendored tree: it writes a separate
project-level install (`.agents/skills/` + `skills-lock.json` at the repo
root), and pointed at `~/.claude/skills` it writes *through* this repo's
symlinks. `/plugin install` has the same problem in the other direction — see
"Plugin skills left unvendored". Instead:

```sh
# Deep enough to compute the delta: --depth 1 has no history, and the commit
# range below is what surfaces renames, demotions and graduations that a
# file-level diff reads as ordinary edits.
git clone --depth 50 https://github.com/mattpocock/skills /tmp/mp-skills

# Review the delta since the sha recorded in the last sync section below.
git -C /tmp/mp-skills log --oneline <last-vendored-sha>..HEAD
git -C /tmp/mp-skills diff --name-status <last-vendored-sha>..HEAD

# Then copy only the buckets we vendor (NOT in-progress/, deprecated/, personal/).
diff -rq claude/agents/skills/<name> /tmp/mp-skills/skills/<bucket>/<name>
rsync -a --delete /tmp/mp-skills/skills/<bucket>/<name>/ claude/agents/skills/<name>/

./install.sh --skills   # re-link, and prune links for renamed/dropped skills
```

Then add a dated sync section to the end of this file: the new upstream sha,
what moved, what was deliberately not taken, and why. Reading `log` and not
just `diff` is load-bearing — the 2026-09-16 check found upstream's `misc/`
demotion (`8666e05`) only in the commit list, since it changed a script this
repo does not vendor.

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

# Plugin skills left unvendored — 2026-09-01

Twenty plugin-installed skills had appeared in `claude/agents/skills/` as
untracked directories: `build-review-interface`,
`building-pydantic-ai-agents`, `design-taste-frontend`,
`engineering-skills`, `error-discovery`, `eval-audit`, `evaluate-rag`,
`fastapi-python`, `fastapi-templates`, `frontend-design`,
`generate-synthetic-data`, `logfire-instrumentation`, `logfire-query`,
`logfire-ui`, `microservices-patterns`, `pydantic`, `pydantic-ai-harness`,
`start`, `validate-evaluator`, `write-judge-prompt`.

They are now listed in `.gitignore` rather than committed. The 2026-07-04 pass
deleted this same category by hand (`pydantic-ai-development`,
`terraform-skill`, `deep-learning`, `supabase-postgres-best-practices`), and
vendoring them would have to be redone every time it recurs. `/plugin install`
is their source of truth; a vendored copy only goes stale against it.

This costs nothing at install time: `link_claude_configs` globs
`claude/agents/skills/*/`, so a machine that has them still gets the symlinks,
and a machine that does not is unaffected.

# Local skill added: `explaining` — 2026-09-01

Third local skill, beside `authoring-longform-briefs` and the
`code-hyperlearning` symlink. Structure and prose standards for explaining
something to a person: docs, ADRs, tickets, docstrings, commit bodies, chat
answers.

Model-invoked, so it fires while prose is being written rather than only when
asked for. It divides into two parts that fail separately, structure then prose,
and structure wins ties.

Complements `writing-for-agents`, which covers documents an *agent* consumes and
optimises for predictable execution. This one covers documents a *person* reads
and optimises for whether they can act afterwards. No overlap in scope, so both
stay model-invoked.

Two changes from the source text, which was written against one specific
project: its anchors (`ADR 0001`, `plan.md`, `tickets.md`, `static.py`,
`CONTEXT.md`) named files that do not exist in any other repo, and a skill
installed in `~/.claude/skills` runs everywhere. Each example was rewritten to
carry itself, keeping the concrete case and dropping the dead path. The closing
test also gained an exhaustiveness bar, since a document that is all reference
needs one to bind it.

No `agents/openai.yaml`: local skills here carry none, and only the vendored
Matt Pocock set has one because upstream ships it.

# Local skill added: `clear-explanations` — 2026-09-07

Fourth local skill. A narrative shape for walking a person through how a
mechanism works in conversation, as opposed to writing something that has to
stand alone.

Split out from `explaining` rather than merged into it, because the two collide
on the opening sentence. `explaining` says the first sentence answers the
question. This one says open with the problem and restate the point at the end.
Both are right for their own case: a yes-or-no question wants the answer first,
and a request to understand a mechanism wants the motivation first. Merging them
would have produced a skill that contradicts itself in its first rule, so the
boundary is written into both descriptions instead, and the direct-question case
stays inside this skill as an override rather than a handoff.

Prose standards are not repeated here. Every rule sampled from the source text
against `explaining` was already present in it: problem before solution, build
in steps, anchor a claim, lead with the answer, concrete before general, tables
carry verdicts, no em dashes, read it aloud. Duplicating those would have given
two cut-on-sight lists free to drift apart, but they are repeated inline anyway. A chat
walkthrough matches this skill alone, so a pointer to `explaining` would leave
the em-dash ban and the cut-on-sight list unloaded exactly when they apply.

What is its own, and what the source text adds: the fixed section skeleton, the
ban on `Layer 1` and `Part A` headers, grounding a comparison in what the reader
already owns rather than in assumed vocabulary, sourcing every branch condition
to a named field and its producer, checking that an example exists before
constructing one and labelling the parts that are constructed, describing every
part of a diagram, closing on a question that can actually fail, and reading a
library's current published docs rather than trusting the pinned source alone.

The source text's `What to avoid` list was compressed, not copied. `writing-skills`
records that for wrong-shaped output a prohibition list measurably backfires
while a positive recipe holds, and the list mostly restated the moves in the
negative. The recipe stayed, and only the failures the recipe cannot express in
the positive survived as prohibitions.

# Skills sync check — 2026-09-16

Checked mattpocock/skills upstream HEAD `959a8e9` (v1.2.3 + 44 commits)
against the vendored set. **All 29 vendored Matt Pocock skills are
byte-identical to upstream HEAD** — the v1.2 cleanup was already captured by
the 2026-08-23 re-vendor — so nothing was re-vendored.

## Upstream changes since `5b15a47`, and what we did with them

- `skills/in-progress/retro/` — new, still in-progress (post-task
  retrospective; pushes mechanical coding-standards findings toward
  deterministic checks). **Not vendored**, per the standing policy of waiting
  for graduation out of `in-progress/`. Also still there: `implement-spec`,
  `setup-ts-deep-modules`, `claude-handoff`, `loop-me`, `writing-beats`,
  `writing-fragments`, `writing-shape`.
- `8666e05` demoted `misc/` from upstream's own daily-driver linking
  (`git-guardrails-claude-code`, `migrate-to-shoehorn`, `scaffold-exercises`,
  `setup-pre-commit` are "kept around but rarely used and not promoted").
  **Kept here anyway**, deliberately — upstream still ships and maintains
  them, they only stopped being auto-linked.

## Installer detour, reverted

`npx skills@latest add mattpocock/skills` was run from the repo root. It does
not update the vendored tree; it created a parallel project-level install —
`.agents/skills/` (37 skills, including all eight `in-progress/` ones),
`.claude/skills/` symlinks into it, and `skills-lock.json` — duplicating the
29 vendored skills byte-for-byte. Removed all three; `.claude/settings.local.json`
predates the installer and was kept. `~/.claude/skills/` was never touched and
has no dangling links.

## Guardrails added afterwards

So the same detour cannot cost anything twice:

- The "Sources of truth" table at the top of this file used to prescribe `npx
  skills@latest add mattpocock/skills` as the *update* command, which is what
  produced the detour. It now carries no command; the procedure lives in "How
  to sync" beside it, scratch clone and all.
- `.gitignore` ignores `/.agents/` and `/skills-lock.json` at the repo root.
  Both were untracked *and* unignored, so the next `git add -A` would have
  committed a second copy of 29 skills plus eight in-progress ones.
  `.claude/skills/` needed no entry: `.claude/` is already ignored.
- `install.sh` grew `--skills` (and a general `--only <components>`), so
  re-linking skills after a sync is one targeted command rather than a full
  bootstrap. `link_agent_skills` now also prunes `~/.claude/skills` links that
  dangle *and* point at this repo's layout, which covers both a renamed or
  dropped skill and the deleted-worktree case from 2026-07-04. Foreign links
  (`learned`, `plaud-*`, plugin installs) are left alone — verified against a
  planted dangling link of each kind.
- Every targeted run that overwrites config now runs `backup_existing` first,
  in the *same* `step` as the linking, because `step` deliberately continues
  after a failure and a backup in its own step could fail while the links
  still got written. Verified: with the backup directory's parent unwritable,
  `--only dotfiles` fails the step and leaves the existing `~/.zshrc` intact.
- The backup list is now scoped to what the run will actually overwrite, and
  it gained the paths `link_agent_skills` deletes: `~/.agents/skills` and each
  `~/.claude/skills/<name>`. Symlinks are skipped as before, so this only
  fires for a *real* directory sitting where one of our links belongs —
  exactly the case that lost the three plannotator skills' local state in
  2026-08-23. It also gained the other two paths `link_herdr_configs` writes
  (the workspace-manager and radar plugin configs); the radar one is the path
  install.sh already records as having been replaced by a detached real file.
- `--only herdr` is split in two. `link_herdr_tree` overwrites config, so it
  sits in the transaction; `update_herdr_plugins` (plugin installs and
  `herdr integration install`) is dispatched as its own step, because it fails
  for unrelated reasons — network — and inside the shared step a GitHub outage
  would abort it and skip every component queued behind. Verified with a
  stubbed-failing `install_herdr_plugins`: on `--only herdr,skills` both config
  halves land, only the plugin step is reported failed, and the run exits 1.

  The split needed a guard the shared subshell used to provide for free.
  `step` always returns 0, so a dependent phase would otherwise run over a
  *failed* one: backup fails, configs are never linked, and
  `install_herdr_plugins` then lets the radar plugin write its sidebar block
  into whatever detached `config.toml` is still live — precisely the file the
  backup just failed to copy aside. `step_if_clean` takes the `FAILED_STEPS`
  length from before the phase it depends on and runs only if it did not grow.

  The full install had the identical hole, and had had it all along: `step
  "backup + configs"` was followed by an unconditional `step "herdr plugins"`,
  with a comment asserting config.toml was "in place first" and nothing
  checking it. Both paths now go through `step_if_clean`. Verified with an
  unwritable `$HOME` holding a detached `config.toml`, once per path: the
  backup step fails, the plugin step is skipped and says which dependency
  failed, the detached file is unchanged, and the run exits 1.
