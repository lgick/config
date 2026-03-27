require("mason").setup()
require("mason-lspconfig").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    "ts_ls",
    "html",
    "cssls",
    "stylua",
    "prettierd",
    "eslint-lsp",
    "lua_ls",
    "tailwindcss-language-server",
    "graphql",
    "nginx_language_server",
    "nginx-config-formatter",
    "tree-sitter-cli",
  },
  auto_update = false,
  run_on_start = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    -- inlay hints (подсказки типов)
    if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end

    -- основные LSP горячие клавиши
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

    vim.keymap.set({ "n", "x" }, "<leader>mm", function()
      -- показываем доступные code actions через snacks
      require("snacks").picker.code_actions()
    end, { noremap = true, silent = true })

    -- быстрое исправление + форматирование для TypeScript
    vim.keymap.set("n", "<leader>ml", function()
      if vim.bo.filetype == "typescript" or vim.bo.filetype == "typescriptreact" then
        vim.lsp.buf.code_action({
          apply = true,
          context = { only = { "source.removeUnused.ts" }, diagnostics = {} },
        })
        vim.defer_fn(function()
          vim.lsp.buf.format({ timeout_ms = 10000 })
        end, 100)
      else
        vim.lsp.buf.format({ timeout_ms = 10000 })
      end
    end)

    -- diagnostics float через Trouble
    vim.keymap.set("n", "<leader>mt", function()
      require("trouble").open("document_diagnostics", { fold_open = "", fold_closed = "" })
    end, opts)

    vim.api.nvim_create_autocmd("LspProgress", {
      callback = function(event)
        local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        vim.notify(vim.lsp.status(), "info", {
          id = "lsp_progress",
          opts = function(notif)
            notif.icon = event.data.params.value.kind == "end" and " "
              or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
          end,
        })
      end,
    })
  end,
})
