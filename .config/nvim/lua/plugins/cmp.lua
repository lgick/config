require("luasnip.loaders.from_vscode").load()
require("luasnip.loaders.from_lua").load({ paths = "$MYVIMRC/lua/snippets" })
require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    { path = "snacks.nvim", words = { "Snacks" } },
  },
})

require("blink.cmp").setup({
  snippets = { preset = "luasnip" },
  keymap = {
    preset = "none",
    ["<CR>"] = { "select_and_accept", "fallback" },
    ["<ESC>"] = { "fallback", "hide" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-n>"] = { "show", "select_next", "fallback" },
    ["<C-.>"] = { "snippet_backward", "fallback" },
    ["<C-/>"] = { "snippet_forward", "fallback" },
    ["<C-u>"] = { "scroll_documentation_up", "fallback" },
    ["<C-d>"] = { "scroll_documentation_down", "fallback" },
  },
  completion = {
    ghost_text = {
      enabled = true,
    },
    menu = {
      auto_show = true,

      draw = {
        treesitter = { "lsp" },
        columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
      },
    },
    documentation = { auto_show = true },
  },
  signature = { enabled = true },
  fuzzy = { implementation = "lua" },
  sources = {
    default = {
      "lazydev",
      "lsp",
      "path",
      "snippets",
      "buffer",
      "copilot",
    },
    per_filetype = {
      sql = { "snippets", "dadbod", "buffer" },
    },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
      copilot = {
        name = "copilot",
        module = "blink-copilot",
        async = true,
      },
    },
  },
})
