return {
  "3rd/diagram.nvim",
  ft = { "markdown", "norg" },
  dependencies = { "3rd/image.nvim" },
  opts = {
    events = {
      render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
      clear_buffer = { "BufLeave" },
    },
    renderer_options = {
      mermaid = {
        background = nil,
        theme = nil,
        scale = 6,
      },
      plantuml = {
        charset = nil,
      },
      d2 = {
        theme_id = nil,
        dark_theme_id = nil,
        scale = nil,
        layout = nil,
        sketch = nil,
      },
    },
  },
  config = function(_, opts)
    require("diagram").setup(opts)

    local function set_diagram_keymap(buf)
      vim.keymap.set("n", "K", function()
        require("diagram").show_diagram_hover()
      end, { buffer = buf, desc = "Show diagram in new tab" })
    end

    -- Current buffer triggered plugin load via `ft = { markdown, norg }`
    set_diagram_keymap(0)

    -- Future markdown/norg buffers
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "norg" },
      callback = function(args) set_diagram_keymap(args.buf) end,
    })
  end,
}
