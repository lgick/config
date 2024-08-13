local g = vim.g
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


----------------------------------------
-- Telescope
----------------------------------------

-- поиск файлов
map('n', '<leader>gf', "<cmd>Telescope find_files<CR>")

-- поиск по файлам
map('n', '<leader>gg', "<cmd>Telescope live_grep<CR>")

-- буфферы
map('n', '<leader>b', "<cmd>Telescope buffers file_ignore_patterns={}<CR>")


----------------------------------------
-- LSP
----------------------------------------

-- Изменить название в файле
map("n", "<leader>r", vim.lsp.buf.rename)

-- Jump to definitions
map("n", "<leader>j", "<cmd>Telescope lsp_definitions<CR>")

-- Show LSP references
map("n", "<leader>a", "<cmd>Telescope lsp_references<CR>")

-- Show buffer diagnostics
map("n", "<leader>s", "<cmd>Telescope diagnostics bufnr=0<CR>")

-- Show documentation for what is under cursor
map("n", "<leader>i", vim.lsp.buf.hover)

-- Toggle diagnostic
map('n', '<leader>t', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end)

-- Show LSP type definitions
--map("n", "<leader>", "<cmd>Telescope lsp_type_definitions<CR>", { silent = true })
-- Show LSP implementations
--map("n", "<leader>", "<cmd>Telescope lsp_implementations<CR>", { silent = true })
-- See available code actions
--map({ "n", "v" }, "<leader>", vim.lsp.buf.code_action, { silent = true })


----------------------------------------
-- Trouble
----------------------------------------

-- Open trouble workspace diagnostics
map("n", "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>")

-- Open trouble document diagnostics
map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>")

-- Open trouble quickfix list
map("n", "<leader>xq", "<cmd>Trouble quickfix toggle<CR>")

-- Open trouble location list
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>")

-- Open todos in trouble
map("n", "<leader>xt", "<cmd>Trouble todo toggle<CR>")
