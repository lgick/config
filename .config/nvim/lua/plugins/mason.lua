require('mason').setup()
require('mason-lspconfig').setup()
require('mason-tool-installer').setup({
  ensure_installed = {
    'ts_ls',
    'html',
    'cssls',
    'stylua',
    'prettierd',
    'eslint-lsp',
    'lua_ls',
    'tailwindcss-language-server',
    'graphql',
    'nginx_language_server',
    'nginx-config-formatter',
    'tree-sitter-cli',
    'json-lsp',
  },
  auto_update = true,
  run_on_start = true,
})

vim.diagnostic.config({
  virtual_text = false, -- Отображает текст ошибок в строке
  signs = false, -- Оставляет значки слева в statuscolumn
  underline = true, -- Оставляет подчеркивание под проблемным кодом
  update_in_insert = false, -- Обновляет ошибки во время ввода
  severity_sort = true, -- Приоритет более важных ошибок
})
