local function set_papercolor()
  -- 1. Удаляем старый, закешированный модуль из памяти.
  -- Теперь следующий вызов require() будет вынужден заново прочитать файл с диска.
  package.loaded["themes.papercolor"] = nil

  -- 2. Загружаем модуль заново и вызываем функцию load()
  require("themes.papercolor").load()
end

set_papercolor()

-- команда :PaperColor для перезагрузки темы
vim.api.nvim_create_user_command("PaperColor", set_papercolor, {})

-- ==========================================================
--  АВТОМАТИЧЕСКАЯ ПЕРЕЗАГРУЗКА ТЕМЫ ПРИ СОХРАНЕНИИ ФАЙЛА
-- ==========================================================

-- 1. Создаём группу для нашей автокоманды.
-- Это лучшая практика, чтобы избежать дублирования автокоманд,
-- если конфигурация будет перезагружаться. `clear = true` очищает группу перед созданием.
local papercolor_reload_group = vim.api.nvim_create_augroup("PaperColorAutoReload", { clear = true })

-- 2. Создаём саму автокоманду
vim.api.nvim_create_autocmd("BufWritePost", {
  group = papercolor_reload_group,
  -- Шаблон, который сработает только для вашего файла темы.
  -- Использование `vim.fn.stdpath` делает путь независимым от имени пользователя.
  pattern = vim.fn.stdpath("config") .. "/lua/themes/papercolor.lua",
  -- Функция, которую нужно вызвать при срабатывании
  callback = set_papercolor,
})
