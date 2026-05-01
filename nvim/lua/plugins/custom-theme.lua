return {
  'bettervim/yugen.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    local function apply_dark_ui()
      local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
      local bg = normal.bg and string.format('#%06x', normal.bg) or '#0d0d0d'

      -- Statusline + winbar
      vim.api.nvim_set_hl(0, 'StatusLine',   { bg = bg, fg = '#cccccc' })
      vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = bg, fg = '#777777' })
      vim.api.nvim_set_hl(0, 'WinBar',       { bg = bg, fg = '#cccccc' })
      vim.api.nvim_set_hl(0, 'WinBarNC',     { bg = bg, fg = '#777777' })

      -- Floating windows (which-key popup, hover, etc.)
      vim.api.nvim_set_hl(0, 'NormalFloat',  { bg = bg, fg = '#cccccc' })
      vim.api.nvim_set_hl(0, 'FloatBorder',  { bg = bg, fg = '#444444' })
      vim.api.nvim_set_hl(0, 'FloatTitle',   { bg = bg, fg = '#cccccc', bold = true })
      vim.api.nvim_set_hl(0, 'FloatFooter',  { bg = bg, fg = '#777777' })

      -- which-key specific groups (the light footer strip)
      vim.api.nvim_set_hl(0, 'WhichKey',          { bg = bg, fg = '#cccccc' })
      vim.api.nvim_set_hl(0, 'WhichKeyGroup',     { bg = bg, fg = '#87afff' })
      vim.api.nvim_set_hl(0, 'WhichKeyDesc',      { bg = bg, fg = '#cccccc' })
      vim.api.nvim_set_hl(0, 'WhichKeySeparator', { bg = bg, fg = '#555555' })
      vim.api.nvim_set_hl(0, 'WhichKeyFloat',     { bg = bg })
      vim.api.nvim_set_hl(0, 'WhichKeyBorder',    { bg = bg, fg = '#444444' })
      vim.api.nvim_set_hl(0, 'WhichKeyValue',     { bg = bg, fg = '#888888' })
    end

    local ok = pcall(vim.cmd.colorscheme, 'yugen')
    if ok then
      apply_dark_ui()

      -- Re-apply if any plugin reloads the colorscheme later
      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = apply_dark_ui,
      })
    else
      vim.notify("yugen colorscheme not yet installed; run :Lazy sync", vim.log.levels.WARN)
    end
  end,
}
