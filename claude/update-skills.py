#!/usr/bin/env python3
"""Update every skill in claude/agents/skills/ from its upstream.

Usage: claude/update-skills.py [--check]

  --check   report what would change; write nothing

The scripted form of "Updating skills" in claude/SKILLS_CLEANUP.md:

- Vendored (tracked in git): each upstream in VENDORED below. Pinned commit
  is read from, and written back to, the "Pinned versions" table there.
  Updated and new skills are copied, skills deleted upstream are removed, and
  all of it is staged by name. New skills still in a non-vendored bucket
  (in-progress/) are listed, never taken: the standing policy is to wait for
  graduation.
- Third-party (`npx skills` / skills.sh installs): every folder here that the
  lock ~/.agents/.skill-lock.json records and git does not track. Found fresh
  each run, so a skill installed tomorrow is updated without being listed
  anywhere, and its name is added to .gitignore so it can never be committed
  by accident. Each gets its source's current folder, and the lock records
  the new hash, as `npx skills add` would. New skills in those sources are not
  pulled in: they are large catalogs that were cherry-picked from.

A skill whose copy here differs from what was last synced is a local edit and
is skipped, never overwritten. Renames upstream arrive as removed + added, so
the summary lists every remaining reference to a removed name. Commits
nothing: /update-skills writes the log entry and commits.

Stdlib only, because it has to run on a fresh machine before anything else.
"""
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = os.path.join(REPO, "claude", "agents", "skills")
LOG = os.path.join(REPO, "claude", "SKILLS_CLEANUP.md")
LOCK = os.path.expanduser("~/.agents/.skill-lock.json")

# url -> (buckets vendored in full, buckets only watched for new arrivals)
VENDORED = {
    "https://github.com/mattpocock/skills": (
        ["skills/engineering", "skills/productivity", "skills/misc"],
        ["skills/in-progress"]),
    "https://github.com/obra/superpowers": (["skills"], []),
}

CHECK = "--check" in sys.argv[1:]
notes = []      # needs a person: local edits, conflicts, leftover references


def git(*args, cwd=None):
    return subprocess.run(["git", *args], cwd=cwd, check=True,
                          capture_output=True, text=True).stdout.strip()


def git_ok(*args, cwd=None):
    r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def tree_hash(path):
    """Git tree hash of a folder on disk, comparable to `rev-parse REV:dir`
    and to the lock's skillFolderHash. The global excludes file is switched
    off so a file upstream ships is never hidden; .DS_Store is dropped since
    Finder adds it and upstream never has it."""
    with tempfile.TemporaryDirectory() as tmp:
        env = dict(os.environ, GIT_INDEX_FILE=os.path.join(tmp, "idx"))
        base = ["git", "-c", "core.excludesFile=", "-C", tmp, f"--work-tree={path}"]
        subprocess.run(["git", "init", "-q", tmp], check=True)
        subprocess.run(base + ["add", "-A", "--", ".", ":(exclude,glob)**/.DS_Store"],
                       env=env, check=True, capture_output=True)
        return subprocess.run(base + ["write-tree"], env=env, check=True,
                              capture_output=True, text=True).stdout.strip()


def copy(src, name):
    if not CHECK:
        subprocess.run(["rsync", "-a", "--delete", src + "/",
                        os.path.join(SKILLS, name) + "/"], check=True)


def subdirs(clone, rev, bucket):
    out = git_ok("ls-tree", "-d", "--name-only", f"{rev}:{bucket}", cwd=clone)
    return set(out.split("\n")) - {""} if out else set()


def skill_sets(clone, rev, buckets):
    """name -> bucket, for every skill folder in those buckets at rev."""
    return {n: b for b in buckets for n in subdirs(clone, rev, b)}


def describe(clone):
    tag = git_ok("describe", "--tags", "HEAD", cwd=clone) or ""
    m = re.fullmatch(r"(.+)-(\d+)-g[0-9a-f]+", tag)
    ver = f"{m[1]} + {m[2]}" if m else tag
    date = git("log", "-1", "--format=%cs", "HEAD", cwd=clone)
    return f"{ver}, {date}" if ver else date


def sync_vendored(url, buckets, watched, log_text, tmp):
    row = re.search(rf"^\| {re.escape(url)} \| `([0-9a-f]+)` \([^)]*\) \|", log_text, re.M)
    if not row:
        sys.exit(f"No pinned row for {url} in {LOG}")
    old = row[1]
    clone = os.path.join(tmp, re.sub(r"\W", "_", url))
    git("clone", "-q", "--filter=blob:none", url, clone)
    head = git("rev-parse", "--short=7", "HEAD", cwd=clone)
    print(f"\n== {url}  {old} -> {head}")
    if git("rev-parse", "HEAD", cwd=clone).startswith(old):
        print("   up to date")
        return log_text, []

    before, after = skill_sets(clone, old, buckets), skill_sets(clone, "HEAD", buckets)
    changed, added, removed, skipped = [], [], [], []
    for name, bucket in sorted(after.items()):
        local = os.path.join(SKILLS, name)
        if os.path.lexists(local):
            mine = tree_hash(local) if os.path.isdir(local) else None
            if mine == git("rev-parse", f"HEAD:{bucket}/{name}", cwd=clone):
                continue        # already current: an earlier run or a hand-merge
            if name not in before:
                notes.append(f"CONFLICT {name}: new in {url}, but a different skill "
                             "of that name is already here. Not copied.")
                skipped.append(name)
                continue
            if mine != git("rev-parse", f"{old}:{before[name]}/{name}", cwd=clone):
                notes.append(f"LOCAL EDITS {name}: differs from {url} at {old}. "
                             "Not overwritten; merge upstream by hand.")
                skipped.append(name)
                continue
            changed.append(name)
        else:
            added.append(name)
        copy(os.path.join(clone, bucket, name), name)

    for name in sorted(set(before) - set(after)):
        local = os.path.join(SKILLS, name)
        if not os.path.isdir(local):
            continue
        if tree_hash(local) != git("rev-parse", f"{old}:{before[name]}/{name}", cwd=clone):
            notes.append(f"LOCAL EDITS {name}: removed from {url}, but edited here. "
                         "Left in place.")
            skipped.append(name)
            continue
        removed.append(name)
        if not CHECK:
            git("rm", "-r", "-q", local, cwd=REPO)

    waiting = sorted(set(skill_sets(clone, "HEAD", watched)) - set(skill_sets(clone, old, watched)))

    for label, names in (("updated", changed), ("added", added), ("removed", removed),
                         ("waiting in in-progress/, not taken", waiting)):
        if names:
            print(f"   {label} ({len(names)}): {', '.join(names)}")
    commits = git("log", "--oneline", f"{old}..HEAD", "--", *buckets, *watched, cwd=clone)
    print("   upstream commits:\n" + "\n".join("     " + c for c in commits.splitlines()))

    if not CHECK:
        for name in changed + added:
            git("add", "-A", "--", os.path.join(SKILLS, name), cwd=REPO)
    # The pin is the baseline for the local-edit check and for the next run's
    # commit list. Moving it past a skipped skill would hide the upstream change
    # it missed for good, so it holds until every skill here took HEAD. The
    # rest still update now; re-copying them next run is a no-op.
    if skipped:
        notes.append(f"PIN HELD at {old} for {url}: {len(skipped)} skill(s) need a "
                     "hand-merge first. Once merged, rerun.")
    elif not CHECK:
        log_text = log_text.replace(row[0], f"| {url} | `{head}` ({describe(clone)}) |")
    return log_text, removed


def ignore_block(names):
    """Add any missing name to the sorted claude/agents/skills/<name>/ block in
    .gitignore. Without it a fresh `npx skills add` shows up as untracked and
    the next broad `git add` commits it (find-skills, 2026-09-30)."""
    path = os.path.join(REPO, ".gitignore")
    with open(path) as f:
        lines = f.read().split("\n")
    entry = re.compile(r"^claude/agents/skills/[^/]+/$")
    idx = [i for i, l in enumerate(lines) if entry.match(l)]
    have = {lines[i] for i in idx}
    new = sorted(f"claude/agents/skills/{n}/" for n in names)
    missing = [l for l in new if l not in have]
    if missing and not CHECK:
        # By bare name, as the block is kept: "pydantic" before "pydantic-ai-…",
        # which a sort that sees the trailing "/" reverses.
        block = sorted(have | set(missing), key=lambda l: l.rstrip("/"))
        lines[idx[0]:idx[-1] + 1] = block
        with open(path, "w") as f:
            f.write("\n".join(lines))
    return [l.split("/")[3] for l in missing]


def sync_third_party(tmp):
    with open(LOCK) as f:
        lock = json.load(f)
    tracked = {p.split("/")[3] for p in
               git("ls-files", "claude/agents/skills", cwd=REPO).splitlines()}
    on_disk = {n for n in os.listdir(SKILLS)
               if os.path.isdir(os.path.join(SKILLS, n))
               and not os.path.islink(os.path.join(SKILLS, n))}
    # Tracked names are vendored or local, whatever the lock says: it still
    # carries stale entries for 28 of them from before they were vendored.
    names = sorted(n for n in on_disk - tracked if n in lock["skills"])
    for n in sorted(on_disk - tracked - set(lock["skills"])):
        notes.append(f"UNKNOWN {n}: untracked and not in the lock (a plugin, or "
                     "copied by hand?). Not updated.")
    added = ignore_block(names)
    if added:
        print(f"\n== .gitignore: newly installed, now ignored ({len(added)}): "
              + ", ".join(added))
        if not CHECK:   # staged, or the next run sees it present and it never lands
            git("add", ".gitignore", cwd=REPO)
    by_source = {}
    for n in names:
        by_source.setdefault(lock["skills"][n]["sourceUrl"], []).append(n)

    dirty = False
    for url, ns in sorted(by_source.items()):
        clone = os.path.join(tmp, re.sub(r"\W", "_", url))
        git("clone", "-q", "--depth", "1", url, clone)
        print(f"\n== {url}  (third-party)")
        for n in sorted(ns):
            e = lock["skills"][n]
            folder = os.path.dirname(e["skillPath"])
            new = git_ok("rev-parse", f"HEAD:{folder}" if folder else "HEAD^{tree}", cwd=clone)
            if not new:
                notes.append(f"GONE UPSTREAM {n}: {url} has no {folder}/ any more "
                             "(renamed or removed). Handle by hand: SKILLS_CLEANUP.md, third-party step 3.")
                continue
            if new == e["skillFolderHash"]:
                continue
            if not os.path.isdir(os.path.join(SKILLS, n)):
                notes.append(f"NOT INSTALLED {n}: in the lock but not on disk. "
                             f"`npx skills add {e['source']}` from $HOME to reinstall.")
                continue
            mine = tree_hash(os.path.join(SKILLS, n))
            now = datetime.datetime.now(datetime.timezone.utc).isoformat(
                timespec="milliseconds").replace("+00:00", "Z")
            if mine == new:
                # Already upstream's current folder, e.g. taken by hand after a
                # LOCAL EDITS note. Record it, or it re-flags on every run.
                print(f"   recorded (already current): {n}")
            elif mine != e["skillFolderHash"]:
                notes.append(f"LOCAL EDITS {n}: differs from the lock's hash. Not overwritten.")
                continue
            else:
                print(f"   updated: {n}")
                copy(os.path.join(clone, folder), n)
            e["skillFolderHash"], e["updatedAt"] = new, now
            dirty = True

    if dirty and not CHECK:
        # The lock lives outside git, so the backup is the only way back; one
        # per write, so a bad run cannot overwrite the last good copy. Written
        # to a temp file and renamed, so a crash cannot leave half a lock.
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        shutil.copy(LOCK, f"{LOCK}.bak-{stamp}")
        with open(LOCK + ".tmp", "w") as f:
            json.dump(lock, f, indent=2)
        os.replace(LOCK + ".tmp", LOCK)


def main():
    with open(LOG) as f:
        log_text = f.read()
    removed = []
    with tempfile.TemporaryDirectory() as tmp:
        for url, (buckets, watched) in VENDORED.items():
            log_text, gone = sync_vendored(url, buckets, watched, log_text, tmp)
            removed += gone
        sync_third_party(tmp)

    if not CHECK:
        with open(LOG, "w") as f:
            f.write(log_text)
        subprocess.run([os.path.join(REPO, "install.sh"), "--skills"], check=True,
                       stdout=subprocess.DEVNULL)

    # A removed name still mentioned elsewhere routes to a dead skill silently.
    for name in removed:
        hits = git_ok("grep", "-n", "-w", "-F", name, "--", "claude", "README.md",
                      ":!claude/SKILLS_CLEANUP.md", cwd=REPO)
        if hits:
            notes.append(f"REFERENCES to removed {name}:\n" + hits)

    print("\n== Needs attention" if notes else "\n== Nothing needs attention")
    for n in notes:
        print(" - " + n)
    if CHECK:
        print("\n(--check: nothing was written)")


if __name__ == "__main__":
    main()
