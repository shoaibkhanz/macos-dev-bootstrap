-- herdr-nav-plus — Neovim side (optional, for full vim -> space walks)
--
-- Seamless <C-h/j/k/l> between Neovim splits and herdr. Move between Neovim
-- splits; at a split edge, hand off to the herdr-nav-plus plugin so focus
-- crosses into the neighbouring herdr pane AND, on the vertical axis (j/k),
-- keeps walking the workspace list (wrapping) at the pane-grid edge.
--
-- Load only ONE herdr navigation editor map. The simplest reliable install is
-- after/plugin so it wins over other <C-h/j/k/l> maps (e.g. vim-tmux-navigator):
--   cp editor/nvim.lua ~/.config/nvim/after/plugin/herdr_nav.lua
-- or dofile it from your config after plugins load.

local PLUGIN = "herdr-nav-plus"

local function cross(dir)
  if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    local herdr = vim.env.HERDR_BIN_PATH
    if herdr == nil or herdr == "" then
      herdr = "herdr"
    end
    -- The edge-* actions skip the Vim-forward step, so this never bounces the
    -- chord back into Neovim.
    vim.fn.system({ herdr, "plugin", "action", "invoke", "edge-" .. dir, "--plugin", PLUGIN })
  elseif vim.env.TMUX and vim.env.TMUX ~= "" then
    local tmux = { left = "Left", down = "Down", up = "Up", right = "Right" }
    pcall(vim.cmd, "TmuxNavigate" .. tmux[dir])
  end
end

local function nav(wincmd, dir)
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= prev then
    return -- moved within Neovim
  end
  cross(dir)
end

local function map(lhs, wincmd, dir, desc)
  vim.keymap.set("n", lhs, function()
    nav(wincmd, dir)
  end, { silent = true, noremap = true, desc = desc })
end

map("<C-h>", "h", "left", "Navigate left (vim/herdr)")
map("<C-j>", "j", "down", "Navigate down (vim/herdr/workspace)")
map("<C-k>", "k", "up", "Navigate up (vim/herdr/workspace)")
map("<C-l>", "l", "right", "Navigate right (vim/herdr)")
