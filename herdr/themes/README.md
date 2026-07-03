# herdr UI themes

Recorded `[theme.custom]` palettes for herdr's UI. herdr's chrome **and** the
`herdr-picker-plus` overlay both read this block, so one palette themes both.
Ghostty (pure black) and nvim (Yugen) are untouched.

**Active: `yugen-true.toml`** — set in `../config.toml`.

## The palettes

| File | Accent | Idea |
|---|---|---|
| **`yugen-true.toml`** ✅ | peach `#ffbe89` | Yugen colorscheme extended into the multiplexer. Warmest, most literal match. |
| `yugen-ui.toml` | blue `#87afff` | Matches nvim's which-key/chrome accent. Frees peach to mean "an agent needs you". |
| `yugen-mono.toml` | grey `#e6e6e6` | Greyscale chrome; the only colour is the herd's status. Most restrained. |
| `vesper.toml` | peach `#ffc799` | Previous theme (canonical Vesper). Warmer/lighter. Kept to revert. |

All four share the same Yugen spine — pure black `#000000`, `#d4d4d4` text, grey
borders, sage green `#7eab8e` — except `vesper.toml`. Only the accent (active
workspace bar, selected picker row, key hints) changes across the three Yugen
options. Semantic agent-state colours (working/blocked/done/idle) are identical.

## Switch

1. Open `../config.toml`, find the `[theme.custom]` block.
2. Replace it with the block from the theme file you want.
3. Reload the running server: `hdrc` (alias for `herdr server reload-config`).

The picker re-reads the config each time it opens, so no restart is needed.

## Source

Palette derived from the user's Yugen flavour in
`nvim/lua/plugins/custom-theme.lua` (bettervim/yugen.nvim + overrides):
black bg, `#cccccc`/`#d4d4d4` text, `#444`/`#555` borders, peach `#ffbe89`,
which-key blue `#87afff`, sage `#7eab8e`.
