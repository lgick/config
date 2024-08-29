return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        file_ignore_patterns = {
          "%.svg",
          "%.gif",
          "%.jpeg",
          "%.jpg",
          "%.png",
          "%.webp",
          "%.ico",
          "%.ttf",
          "%.json",
          "README.md",
        },
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--hidden",
          "--smart-case",
        },
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-p>"] = actions.move_selection_previous,
            ["<C-n>"] = actions.move_selection_next,
            ["<C-k>"] = actions.preview_scrolling_up,
            ["<C-j>"] = actions.preview_scrolling_down,
            ["<C-u>"] = actions.move_to_top,
            ["<C-d>"] = actions.move_to_bottom,
            ["<C-[>"] = actions.send_selected_to_qflist,
          },
        },
      },
    })

    telescope.load_extension("fzf")
  end,
}
