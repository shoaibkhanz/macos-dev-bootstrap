return {
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.python3_host_prog = vim.fn.expand("~/.local/share/nvim/python/.venv/bin/python3")
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_auto_open_output = false
    end,
    keys = {
      { ",mi", "<cmd>MoltenInit<CR>", desc = "Molten init kernel" },
      { ",me", "<cmd>MoltenEvaluateOperator<CR>", desc = "Molten eval operator" },
      { ",ml", "<cmd>MoltenEvaluateLine<CR>", desc = "Molten eval line" },
      { ",mr", "<cmd>MoltenReevaluateCell<CR>", desc = "Molten re-eval cell" },
      { ",mr", ":<C-u>MoltenEvaluateVisual<CR>gv", mode = "v", desc = "Molten eval visual" },
      { ",md", "<cmd>MoltenDelete<CR>", desc = "Molten delete cell" },
      { ",mo", "<cmd>MoltenShowOutput<CR>", desc = "Molten show output" },
      { ",mh", "<cmd>MoltenHideOutput<CR>", desc = "Molten hide output" },
      { ",mx", "<cmd>MoltenInterrupt<CR>", desc = "Molten interrupt" },
      { "]c", "<cmd>MoltenNext<CR>", desc = "Next cell" },
      { "[c", "<cmd>MoltenPrev<CR>", desc = "Prev cell" },
    },
  },

  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty",
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },

  {
    "GCBallesteros/jupytext.nvim",
    config = function()
      local venv = vim.fn.expand("~/.local/share/nvim/python/.venv/bin")
      vim.env.PATH = venv .. ":" .. vim.env.PATH
      require("jupytext").setup({
        style = "markdown",
        output_extension = "md",
        force_ft = "markdown",
      })
    end,
  },
}
