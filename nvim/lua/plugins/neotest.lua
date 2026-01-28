return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            args = { "--log-level", "DEBUG" },
            runner = "pytest",
            python = ".venv/bin/python",
            pytest_discover_instances = true,
          }),
        },
      })
    end,
    keys = {
      {
        "<leader>nn",
        function() require("neotest").run.run() end,
        desc = "Run nearest test",
      },
      {
        "<leader>nf",
        function() require("neotest").run.run(vim.fn.expand("%")) end,
        desc = "Run all tests in current file",
      },
      {
        "<leader>nl",
        function() require("neotest").run.run_last() end,
        desc = "Re-run last test",
      },
      {
        "<leader>ns",
        function() require("neotest").summary.toggle() end,
        desc = "Toggle test summary",
      },
      {
        "<leader>no",
        function() require("neotest").output.open({ enter = true }) end,
        desc = "Open test output",
      },
      {
        "<leader>nO",
        function() require("neotest").output_panel.toggle() end,
        desc = "Toggle output panel",
      },
      {
        "<leader>nd",
        function() require("neotest").run.run({ strategy = "dap" }) end,
        desc = "Debug nearest test (DAP)",
      },
    },
  },
}
