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
      pickers = {
        buffers = {
          show_all_buffers = true,
          sort_lastused = true,
          file_ignore_patterns = {},
          ignore_current_buffer = true,
          theme = "dropdown",
          previewer = false,
          mappings = {
            i = {
              ["<C-d>"] = actions.delete_buffer + actions.move_to_top,
            },
          },
        },
      },
      defaults = {
        default_mappings = {},
        file_ignore_patterns = {
          "%.svg",
          "%.gif",
          "%.jpeg",
          "%.jpg",
          "%.png",
          "%.webp",
          "%.ico",
          "%.ttf",
          "%.git/",
          "dist/",
          "build/",
          "node_modules/",
          "package%-lock%.json",
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
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-p>"] = actions.preview_scrolling_up,
            ["<C-n>"] = actions.preview_scrolling_down,
            ["<C-u>"] = actions.move_to_top,
            ["<C-d>"] = actions.move_to_bottom,
            ["<C-s>"] = actions.select_vertical,
            ["<C-i>"] = actions.select_horizontal,
            ["<C-o>"] = actions.send_to_qflist + actions.open_qflist,
            ["<ESC>"] = actions.close,
            ["<CR>"] = actions.select_default,
          },
          n = {
            ["<ESC>"] = actions.close,
          },
        },
      },
    })

    telescope.load_extension("fzf")
  end,
}
