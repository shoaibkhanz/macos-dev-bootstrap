return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    opts = {
      integrations = {
        diffview = true,
      },
      kind = "auto",
      graph_style = "unicode",
      signs = {
        hunk = { "", "" },
        item = { "▸", "▾" },
        section = { "▸", "▾" },
      },
    },
    cmd = "Neogit",
    keys = {
      { "<Leader>gn", function() require("neogit").open() end, desc = "Neogit status" },
      { "<Leader>gN", function() require("neogit").open({ "log" }) end, desc = "Neogit log" },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<Leader>gD", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
      { "<Leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview file history" },
      { "<Leader>gF", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview branch history" },
    },
    opts = {},
  },
  -- Enable inline blame virtual text toggle
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 300,
      },
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
    },
  },
}
