return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    local lspconfig = require("lua.plugins.lspconfig")
    local mason_lspconfig = require("mason-lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- отключение семантической подсветки
    for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do
      vim.api.nvim_set_hl(0, group, {})
    end

    local on_attach = function(client, bufnr) end

    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    mason_lspconfig.setup({
      ensure_installed = {
        "ts_ls",
        "html",
        "cssls",
        "lua_ls",
        "graphql",
        "emmet_ls",
        "eslint",
        "nginx_language_server",
      },
      handlers = {
        function(server_name)
          lspconfig[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,

        ["eslint"] = function()
          lspconfig.eslint.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              workingDirectories = { mode = "auto" },
              experimental = { useFlatConfig = true },
            },
          })
        end,

        ["graphql"] = function()
          lspconfig.graphql.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
          })
        end,

        ["emmet_ls"] = function()
          lspconfig.emmet_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
          })
        end,

        ["lua_ls"] = function()
          lspconfig.lua_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              Lua = {
                diagnostics = { globals = { "vim" }, disable = { "missing-fields" } },
                completion = { callSnippet = "Replace" },
              },
            },
          })
        end,
      },
    })
  end,
}
