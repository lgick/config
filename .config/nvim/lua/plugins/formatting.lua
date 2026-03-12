require("conform").setup({
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
  -- Определяем кастомный форматер с нужными аргументами
  formatters = {
    ["nginx-config-formatter"] = {
      command = "nginxfmt",
      args = {
        "-", -- Включаем режим "pipe" для чтения из stdin
        "-i",
        "2", -- Устанавливаем отступ в 2 пробела (правильный флаг)
      },
    },
  },
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettierd", stop_after_first = true },
    javascriptreact = { "prettierd", stop_after_first = true },
    typescript = { "prettierd", stop_after_first = true },
    typescriptreact = { "prettierd", stop_after_first = true },
    html = { "prettierd", stop_after_first = true },
    css = { "prettierd", stop_after_first = true },
    json = { "prettierd", stop_after_first = true },
    markdown = { "prettierd", stop_after_first = true },
    graphql = { "prettierd", stop_after_first = true },
    nginx = { "nginx-config-formatter" },
  },
})

require("nvim-autopairs").setup()
require("nvim-ts-autotag").setup()
