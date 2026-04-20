require('conform').setup({
  -- Определяем кастомный форматер с нужными аргументами
  formatters = {
    ['nginx-config-formatter'] = {
      command = 'nginxfmt',
      args = {
        '-', -- Включаем режим "pipe" для чтения из stdin
        '-i',
        '2', -- Устанавливаем отступ в 2 пробела (правильный флаг)
      },
    },
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettierd' },
    javascriptreact = { 'prettierd' },
    typescript = { 'prettierd' },
    typescriptreact = { 'prettierd' },
    html = { 'prettierd' },
    css = { 'prettierd' },
    json = { 'prettierd' },
    jsonc = { 'prettierd' },
    markdown = { 'prettierd' },
    graphql = { 'prettierd' },
    nginx = { 'nginx-config-formatter' },
  },
  format_on_save = function()
    if vim.g.disable_autoformat then
      return
    end

    return { timeout_ms = 500, lsp_format = 'fallback' }
  end,
})
