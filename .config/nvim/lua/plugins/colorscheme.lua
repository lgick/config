return {
  "my/papercolor", -- Просто уникальное имя для вашего локального плагина
  lazy = false,
  priority = 1000,
  dir = vim.fn.stdpath("config"), -- Указываем, что плагин находится в нашей конфигурации
  config = function()
    vim.cmd.colorscheme("PaperColor")
  end,
}
