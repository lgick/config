return {
  {
    "stevearc/aerial.nvim",
    opts = {},
    -- Optional dependencies
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("aerial").setup({
        filter_kind = {
          "Function",
          "Method",
          --"Class",
          --"Constructor",
          --"Enum",
          --"Interface",
          --"Module",
          --"Struct",
        },
        close_on_select = false,
        post_parse_symbol = function(bufnr, item, ctx)
          return not item.parent
        end,
        post_jump_cmd = "normal! zt",
        keymaps = {
          ["?"] = "actions.show_help",
          ["<CR>"] = "actions.jump",
          ["o"] = "actions.scroll",
          ["s"] = "actions.jump_vsplit",
          ["i"] = "actions.jump_split",
          ["<C-j>"] = "actions.down_and_scroll",
          ["<C-k>"] = "actions.up_and_scroll",
          ["h"] = "actions.tree_close",
          ["l"] = "actions.tree_open",
          ["q"] = "actions.close",

          ["g?"] = false,
          ["<2-LeftMouse>"] = false,
          ["<C-v>"] = false,
          ["<C-s>"] = false,
          ["p"] = false,
          ["{"] = false,
          ["}"] = false,
          ["[["] = false,
          ["]]"] = false,
          ["za"] = false,
          ["O"] = false,
          ["zA"] = false,
          ["zo"] = false,
          ["L"] = false,
          ["zO"] = false,
          ["zc"] = false,
          ["H"] = false,
          ["zC"] = false,
          ["zr"] = false,
          ["zR"] = false,
          ["zm"] = false,
          ["zM"] = false,
          ["zx"] = false,
          ["zX"] = false,
        },
      })
    end,
  },
}
