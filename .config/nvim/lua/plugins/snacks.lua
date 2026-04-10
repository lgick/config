local snacks = require("snacks")

snacks.setup({
  input = { enabled = true },

  picker = {
    enabled = true,
    win = {
      input = {
        keys = {
          ["<ESC>"] = { "close", mode = { "i", "n" } },
          ["<C-j>"] = { "list_down", mode = { "i", "n" } },
          ["<C-k>"] = { "list_up", mode = { "i", "n" } },
          ["<C-n>"] = { "preview_scroll_down", mode = { "i", "n" } },
          ["<C-p>"] = { "preview_scroll_up", mode = { "i", "n" } },
          ["<C-d>"] = { "list_bottom", mode = { "i", "n" } },
          ["<C-u>"] = { "list_top", mode = { "i", "n" } },
          ["<C-o>"] = { "qflist", mode = { "i", "n" } },
          ["<C-s>"] = { "edit_split", mode = { "i", "n" } },
          ["<C-i>"] = { "edit_vsplit", mode = { "i", "n" } },
          ["<CR>"] = { "confirm", mode = { "n", "i" } },
        },
      },
    },
  },

  dashboard = {
    sections = {
      { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
      { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
      {
        icon = " ",
        title = "Git Status",
        section = "terminal",
        enabled = function()
          return Snacks.git.get_root() ~= nil
        end,
        cmd = "git status --short --branch --renames",
        height = 10,
        ttl = 5 * 60,
        indent = 2,
        padding = 1,
      },
    },
  },
})
