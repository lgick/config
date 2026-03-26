require("luasnip.loaders.from_vscode").lazy_load({
  paths = { vim.fn.stdpath("config") .. "/snippets" },
})

require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    { path = "snacks.nvim", words = { "Snacks" } },
  },
})

require("blink.cmp").setup({
  snippets = {
    preset = "luasnip",
  },
  keymap = {
    preset = "none",
    ["<CR>"] = { "select_and_accept", "fallback" },
    ["<ESC>"] = { "fallback", "hide" },
    ["<C-n>"] = { "show", "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-/>"] = { "snippet_forward", "fallback" },
    ["<C-.>"] = { "snippet_backward", "fallback" },
    ["<C-u>"] = { "scroll_documentation_up", "fallback" },
    ["<C-d>"] = { "scroll_documentation_down", "fallback" },
  },
  completion = {
    -- призрачный текст
    ghost_text = {
      enabled = true,
    },
    menu = {
      auto_show = true,

      draw = {
        -- вид выпадающего списка
        columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
      },
    },
    documentation = {
      auto_show = true,
    },
  },
  signature = { enabled = true },
  fuzzy = {
    implementation = "prefer_rust_with_warning",
    sorts = {
      "score", -- Primary sort: by fuzzy matching score
      "sort_text", -- Secondary sort: by sortText field if scores are equal
      "label", -- Tertiary sort: by label if still tied
    },
    prebuilt_binaries = {
      download = true,
      force_version = "v1.*",
    },
  },
  sources = {
    default = {
      "lazydev",
      "lsp",
      "path",
      "snippets",
      "buffer",
    },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },
})
