# Archive

Configs that are no longer part of the bootstrap. Nothing in here is installed
by `Brewfile`, symlinked by `install.sh`, or read by any running program — it is
kept only so a past setup can be recovered without digging through git history.

| Parked | Why |
|---|---|
| `aerospace/` | AeroSpace tiling WM (`alt-h/j/k/l` window focus, workspaces W/C/M/P). Replaced by herdr + Ghostty; the cask was never in the `Brewfile` and the config was never symlinked, so these bindings had not been active for a long time. Cask uninstalled 2026-07-31. |
| `sketchybar/` | Status bar whose workspace indicators were driven entirely by AeroSpace (`plugins/aerospace.sh` calls `aerospace list-workspaces --focused`). Dead with AeroSpace: not in the `Brewfile`, not installed, never symlinked. |

## Restoring one

Nothing here is wired up. To bring a config back, move it out of `archive/`,
add its package to the `Brewfile`, and add a `link_file` line to
`create_symlinks` in `install.sh` (plus its target path to `files_to_backup` in
`backup_existing`). AeroSpace reads `~/.aerospace.toml` or
`~/.config/aerospace/aerospace.toml`; sketchybar reads `~/.config/sketchybar/`.
