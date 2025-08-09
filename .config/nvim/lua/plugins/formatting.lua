return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
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
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        nginx = { "nginx-config-formatter" },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    })
  end,
}
