local g = vim.g
local cmd = vim.cmd
local api = vim.api
local opt = vim.opt
local notify = vim.notify
local map = vim.keymap.set
local fn = vim.fn

-- <C-o> - переход на предыдущую позицию в списке переходов
-- <C-i> - переход на следующую позицию в списке переходов
-- :ju - лист переходов
-- gc - комментарий в visual mode
-- <C-f> - command history window

g.mapleader = ","

------------------------------------------
-- Форматирование текста
------------------------------------------

-- Переключение языка в режиме ввода
map("i", "<C-l>", "<C-^>")

-- Сброс языка при выходе из Insert mode
map("i", "<ESC>", "<ESC><cmd>set iminsert=0<CR>")

------------------------------------------
-- Поиск
------------------------------------------

-- Значение поиска по центру экрана
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Переключение языка в режиме поиска
map("c", "<C-l>", "<C-^>")

------------------------------------------
-- Hardcore mode
------------------------------------------

-- Отключение стрелочек
map("n", "<Up>", "<nop>")
map("n", "<Down>", "<nop>")
map("n", "<Left>", "<nop>")
map("n", "<Right>", "<nop>")
map("i", "<BS>", "<nop>")

----------------------------------------
-- Hotkeys
----------------------------------------

-- , + p: Открывает предыдущий буфер
map("n", "<leader>p", "<cmd>bp<CR>")

-- , + n: Открывает следующий буфер
map("n", "<leader>n", "<cmd>bn<CR>")

-- , + d: Удаляет буфер
map("n", "<leader>d", "<cmd>bdel<CR>")

-- , + c: Копирует в системный буфер
map("v", "<leader>c", '"+y')

-- , + v: Вставляет из системного буфера
map("n", "<leader>v", '"+p')

-- , + f: File Explorer
map("n", "<leader>f", "<cmd>NvimTreeToggle<CR>")

-- , + o: Aerial - code navigation
map("n", "<leader>o", "<cmd>AerialToggle<CR>")

--- , + w: Git blame
map("n", "<leader>w", "<cmd>Gitsigns blame<CR>", { desc = "Git Blame" })

--- , + l: Git stage flow
map("n", "<leader>l", "<cmd>GitStageFlow<CR>", { desc = "Git Stage Flow" })

-- , + y: Autoformat toggle
map("n", "<leader>y", function()
  if g.disable_autoformat then
    g.disable_autoformat = false
    notify("Enabled autoformat")
  else
    g.disable_autoformat = true
    notify("Disabled autoformat")
  end
end)

-- , + z: Сворачивает функциональные блоки в файле
map("n", "<leader>z", function()
  -- Проверяем, существует ли переменная vim.b.space
  if fn.exists("b:space") == 0 then
    api.nvim_buf_set_var(0, "space", 0)
  end

  -- Сворачиваем все блоки
  api.nvim_command("normal zE")

  -- Спрашиваем уровень отступа
  local i = 0
  local lenline = fn.line("$")
  local currentline = fn.line(".")
  cmd("call inputsave()")
  local space = fn.input("how many space (current value: " .. api.nvim_buf_get_var(0, "space") .. ")? ")
  cmd("call inputrestore()")

  -- Обновляем значение vim.b.space, если пользователь ввел новое значение
  local num_space = tonumber(space)
  if num_space ~= nil then
    api.nvim_buf_set_var(0, "space", num_space)
  end

  -- значение умножаем на tabstop
  local tabstop = tonumber(vim.opt.tabstop:get()) or 2
  local indent = api.nvim_buf_get_var(0, "space") * tabstop

  -- Сворачиваем блоки с уровнем отступа, равным vim.b.space
  while i <= lenline do
    local str = fn.getline(i)
    if fn.indent(i) == indent then
      if fn.match(str, "[{(%[]") ~= -1 then
        api.nvim_win_set_cursor(0, { i, 0 })
        api.nvim_command("normal $zf%")
      end
    end
    i = i + 1
  end

  -- Возвращаемся к текущей строке
  api.nvim_win_set_cursor(0, { currentline, 0 })
  api.nvim_command("echo ''")
end)

----------------------------------------
-- Snacks
----------------------------------------

-- поиск файлов
map("n", "<leader>s", function()
  Snacks.picker.files()
end, { desc = "Find Files" })

-- поиск по файлам
--map("n", "<leader>g", function()
--  Snacks.picker.grep()
--end, { desc = "Live Grep" })

-- буфферы
map("n", "<leader>b", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })

-- недавние файлы
map("n", "<leader>e", function()
  Snacks.picker.recent()
end, { desc = "Recent Files" })

----------------------------------------
-- LSP
----------------------------------------

-- Show LSP references
map("n", "<leader>a", vim.lsp.buf.references)

-- Изменить название в файле (вызвать :wa по завершению)
map("n", "<leader>r", vim.lsp.buf.rename)

-- Show LSP definitions
-- map("n", "<leader>j", "<cmd>Telescope lsp_definitions jump_type=split<CR>")

-- Toggle diagnostic
--map("n", "<leader>t", function()
--  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
--end)

-- See available code actions
--map({ "n", "v" }, "<leader>m", vim.lsp.buf.code_action)

-- Show documentation for what is under cursor
--map("n", "<leader>i", vim.lsp.buf.hover)

----------------------------------------
-- Trouble
----------------------------------------

-- Open trouble workspace diagnostics
map("n", "<leader>x", "<cmd>Trouble diagnostics toggle<CR>")

-- Open trouble document diagnostics
map("n", "<leader>X", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>")

------------------------------------------
-- Codeium
------------------------------------------

-- Открывает чат
map("n", "<leader>h", "<cmd>call codeium#Chat()<CR>")

------------------------------------------
-- Nvim
------------------------------------------

function _G.ReloadConfig()
  for name in pairs(package.loaded) do
    if name:match("^plugins") or name:match("^snacks") or name:match("^themes") or name:match("^config") then
      package.loaded[name] = nil
    end
  end

  dofile(vim.env.MYVIMRC)
  notify("Конфигурация перезагружена!", vim.log.levels.INFO)
end

map("n", "<leader>1", "<cmd>lua ReloadConfig()<CR>", { desc = "Reload config" })

map("n", "<leader>2", function()
  Snacks.picker.highlights({ pattern = "hl_group:" })
end, { desc = "Highlights" })

-- Определяет синтаксис слова под курсором
map("n", "<leader>3", ":Inspect<CR>")
map("n", "<leader>4", ":InspectTree<CR>")

-- Отображает сообщения в новом буфере
map("n", "<leader>5", ":tabnew | put =execute('messages')<CR>")

-- Проверяет работу плагинов nvim
map("n", "<leader>6", ":checkhealth<CR>")

-- Сбрасывает nvim до заводских настроек
map("n", "<leader>7", function()
  local confirm = fn.input("ПОЛНОСТЬЮ сбросить Neovim? (y/n): ")

  if confirm:lower() ~= "y" then
    return
  end

  local paths = {
    fn.stdpath("cache"), -- ~/.cache/nvim
    fn.stdpath("data"), -- ~/.local/share/nvim
    fn.stdpath("state"), -- ~/.local/state/nvim
  }

  for _, path in ipairs(paths) do
    if fn.empty(fn.glob(path)) == 0 then
      fn.delete(path, "rf")
    end
  end

  opt.shada = ""
  os.exit()
end, { desc = "Nuke nvim" })

-- Обновляет плагины nvim
map("n", "<leader>8", function()
  local confirm = fn.input("Обновить плагины Neovim? (y/n): ")

  if confirm:lower() ~= "y" then
    return
  end

  vim.pack.update()
  vim.cmd("MasonToolsUpdate")
  vim.cmd("TSUpdate")
end, { desc = "Update nvim plugins" })
