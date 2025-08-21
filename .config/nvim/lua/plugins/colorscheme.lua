return {
  "my/papercolor", -- Просто уникальное имя для вашего локального плагина
  lazy = false,
  priority = 1000,
  dir = vim.fn.stdpath("config"), -- Указываем, что плагин находится в нашей конфигурации
  config = function()
    local cmd = vim.cmd
    local api = vim.api
    local fn = vim.fn

    cmd.colorscheme("PaperColor")

    -- Цвет невидимых символов listchars
    api.nvim_set_hl(0, "Whitespace", { fg = "#d20f39", bg = "NONE" })

    -- Цвет колонки и строки
    api.nvim_set_hl(0, "CursorColumn", { fg = "none", bg = "#ccd0da" })
    api.nvim_set_hl(0, "CursorLine", { fg = "none", bg = "#ccd0da" })

    -- Правило подсветки для символов после 80 столбца
    api.nvim_set_hl(0, "OverLength", { fg = "#d20f39" })
    fn.matchadd("OverLength", [[\%81v.\+]])
  end,
}
