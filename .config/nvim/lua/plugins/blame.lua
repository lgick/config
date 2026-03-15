local blame = require("blame")

blame.setup({
  mappings = {
    commit_info = "i",
    stack_push = "<C-/>",
    stack_pop = "<C-.>",
    show_commit = "<CR>",
    close = { "<ESC>", "q" },
  },
})
