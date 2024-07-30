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
    local transform_mod = require("telescope.actions.mt").transform_mod

    local trouble = require("trouble")
    local trouble_telescope = require("trouble.sources.telescope")

    -- or create your custom action
    local custom_actions = transform_mod({
      open_trouble_qflist = function()
        trouble.toggle("quickfix")
      end,
    })

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
          "--smart-case"
        },
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
          },
        },
      },
    })

    telescope.load_extension("fzf")

    -- set keymaps
    local keymap = vim.keymap -- for conciseness
    local builtin = require('telescope.builtin')
    keymap.set('n', '<leader>gf', builtin.find_files, {})
    keymap.set('n', '<leader>gg', builtin.live_grep, {})
    keymap.set('n', '<leader>gb', builtin.buffers, {})
    keymap.set('n', '<leader>gh', builtin.help_tags, {})
  end,
}
