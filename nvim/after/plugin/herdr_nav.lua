-- Neovim side of seamless <C-h/j/k/l> for both herdr flavours.
--
-- herdr-app (HC_TERMINAL_ID): its nav-keys mod (herdr-app/mods/nav-keys) hands
-- the chord to Neovim; at a split edge we ask herdr-app to focus the next pane.
-- herdr TUI (HERDR_PANE_ID): hand off to the herdr-nav-plus plugin, whose
-- edge-* actions also walk the workspace list on j/k.
-- Loaded from after/plugin so it wins over other <C-h/j/k/l> maps
-- (e.g. vim-tmux-navigator).

local function cross(dir)
  if vim.env.HC_TERMINAL_ID and vim.env.HC_TERMINAL_ID ~= "" then
    vim.fn.system({ "herdr-app", "do", "pane.go", "--direction", dir })
  elseif vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    local herdr = vim.env.HERDR_BIN_PATH
    if herdr == nil or herdr == "" then
      herdr = "herdr"
    end
    -- edge-* skips the Vim-forward step, so this never bounces back into Neovim.
    vim.fn.system({ herdr, "plugin", "action", "invoke", "edge-" .. dir, "--plugin", "herdr-nav-plus" })
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
