local g = vim.g
local opt = vim.opt
local map = vim.keymap.set

g.mapleader = ","


------------------------------------------
-- Форматирование текста
------------------------------------------

-- <C-o> - переход на предыдущую позицию в списке переходов
-- <C-i> - переход на следующую позицию в списке переходов
-- :ju - лист переходов

-- Переключение языка в режиме ввода
map("i", "<C-l>", "<C-^>")

-- Сброс языка при выходе из Insert mode
map("i", "<ESC>", "<ESC><cmd>set iminsert=0<CR>")

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
-- Сворачивание блоков кода
----------------------------------------

--map("i", "<leader>z", "<C-O>za")
--map("n", "<leader>z", "za")
--map("o", "<leader>z", "<C-C>za")
--map("v", "<leader>z", "zf")


----------------------------------------
-- Hotkeys
----------------------------------------

-- , + p: Открывает предыдущий буфер
map("n", "<leader>p", "<cmd>bp<CR>")

-- , + n: Открывает следующий буфер
map("n", "<leader>n", "<cmd>bn<CR>")

-- , + d: Удаление буфера
map("n", "<leader>d", "<cmd>bdel<CR>")

-- , + c: Копирование в системный буфер
map("v", "<leader>c", "\"+y")

-- , + v: Вставка из системного буфера
map("n", "<leader>v", "\"+p")

-- , + f: File Explorer
map("n", "<leader>f", "<cmd>NvimTreeToggle<CR>")

-- , + l: Подсветка координат курсора
local cursorLight = false
map('n', '<leader>l', function()
  if cursorLight == true then
    opt.cursorline = false
    opt.cursorcolumn = false
    cursorLight = false
  else
    opt.cursorline = true
    opt.cursorcolumn = true
    cursorLight = true
  end
end)


----------------------------------------
-- Telescope
----------------------------------------

-- поиск файлов
map('n', '<leader>gf', "<cmd>Telescope find_files<CR>")

-- поиск по файлам
map('n', '<leader>gg', "<cmd>Telescope live_grep<CR>")

-- буфферы
map('n', '<leader>gb', "<cmd>Telescope buffers file_ignore_patterns={}<CR>")

-- Show LSP references
map("n", "<leader>gr", "<cmd>Telescope lsp_references<CR>")

-- Show LSP implementations
map("n", "<leader>gt", "<cmd>Telescope lsp_implementations<CR>")


----------------------------------------
-- Trouble
----------------------------------------

-- Open trouble workspace diagnostics
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>")

-- Open trouble document diagnostics
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>")


----------------------------------------
-- LSP
----------------------------------------

-- Toggle diagnostic
map('n', '<leader>t', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end)

-- See available code actions
map({ "n", "v" }, "<leader>m", vim.lsp.buf.code_action)

-- Изменить название в файле
map("n", "<leader>r", vim.lsp.buf.rename)

-- Show documentation for what is under cursor
map("n", "<leader>i", vim.lsp.buf.hover)
