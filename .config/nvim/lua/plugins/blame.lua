return {
  {
    "FabijanZulj/blame.nvim",
    lazy = false,
    config = function()
      require("blame").setup({
        mappings = {
          commit_info = "i",
          stack_push = "<C-/>",
          stack_pop = "<C-.>",
          show_commit = "<CR>",
          close = { "<ESC>", "q" },
        },
      })
    end,
    opts = {},
  },
}
