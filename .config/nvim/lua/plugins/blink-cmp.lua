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
  cmdline = {
    keymap = {
      preset = "none",
      ["<CR>"] = { "accept", "fallback" },
      ["<C-n>"] = { "show", "insert_next", "fallback" },
      ["<C-p>"] = { "insert_prev", "fallback" },
    },
    completion = {
      list = {
        selection = {
          preselect = true, -- выбор первого элемента при открытии меню
        },
      },
      menu = {
        auto_show = function(ctx)
          local before = ctx.line:sub(1, ctx.cursor[2])

          -- показывать только если последний символ точка или пробел
          return before:sub(-1) == "." or before:sub(-1) == " "
        end,
      },
    },
  },
  keymap = {
    preset = "none",
    ["<CR>"] = { "accept", "fallback" },
    ["<ESC>"] = { "fallback", "hide" }, -- выходит из insert и скрывает меню
    ["<C-n>"] = { "insert_next", "fallback" },
    ["<C-p>"] = { "insert_prev", "fallback" },
    ["<C-/>"] = { "snippet_forward", "fallback" },
    ["<C-.>"] = { "snippet_backward", "fallback" },
    ["<C-u>"] = { "scroll_documentation_up", "fallback" },
    ["<C-d>"] = { "scroll_documentation_down", "fallback" },
    ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
  },
  completion = {
    list = {
      selection = {
        preselect = true, -- выбор первого элемента при открытии меню
      },
    },
    -- призрачный текст
    ghost_text = {
      enabled = false,
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
      "lsp",
      "lazydev",
      "snippets",
      "path",
      "buffer",
    },
    providers = {
      path = {
        module = "blink.cmp.sources.path",
        opts = {
          trailing_slash = true, -- добавлять / после выбора папки
          label_trailing_slash = true, -- показывать / в списке подсказок
          show_hidden_files_by_default = true,
        },
      },
      snippets = {
        module = "blink.cmp.sources.snippets",
      },

      lazydev = {
        module = "lazydev.integrations.blink",
      },

      lsp = {
        module = "blink.cmp.sources.lsp",
        transform_items = function(_, items)
          return vim.tbl_filter(function(item)
            return item.kind ~= require("blink.cmp.types").CompletionItemKind.Keyword
          end, items)
        end,
      },

      -- слова из буфера
      buffer = {
        transform_items = function(_, items)
          return vim.tbl_filter(function(item)
            return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text
          end, items)
        end,
      },
    },
  },
})
