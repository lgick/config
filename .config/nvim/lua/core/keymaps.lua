local g = vim.g
local map = vim.keymap.set

g.mapleader = ","


------------------------------------------
-- Форматирование текста
------------------------------------------

-- Переключение языка в режиме ввода
map("i", "<C-l>", "<C-^>")

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

map("i", "<leader>z", "<C-O>za")
map("n", "<leader>z", "za")
map("o", "<leader>z", "<C-C>za")
map("v", "<leader>z", "zf")


----------------------------------------
-- Hotkeys
----------------------------------------

-- , + p: Открывает предыдущий буфер
map("n", "<leader>p", ":bp<CR>", { silent = true })

-- , + n: Открывает следующий буфер
map("n", "<leader>n", ":bn<CR>", { silent = true })

-- , + d: Удаление буфера
map("n", "<leader>d", ":bdel<CR>", { silent = true })

-- , + c: Копирование в системный буфер
map("v", "<leader>c", "\"+y", { silent = true })

-- , + v: Вставка из системного буфера
map("n", "<leader>v", "\"+p", { silent = true })

-- , + f: File Explorer
map("n", "<leader>f", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })


----------------------------------------
-- Telescope
----------------------------------------

-- поиск файлов
map('n', '<leader>gf', "<cmd>Telescope find_files<CR>", { silent = true })

-- поиск по файлам
map('n', '<leader>gg', "<cmd>Telescope live_grep<CR>", { silent = true })

-- буфферы
map('n', '<leader>b', "<cmd>Telescope buffers file_ignore_patterns={}<CR>", { silent = true })


----------------------------------------
-- LSP
----------------------------------------

-- Изменить название в файле
map("n", "<leader>r", vim.lsp.buf.rename, { silent = true })

-- Jump to definitions
map("n", "<leader>j", "<cmd>Telescope lsp_definitions<CR>", { silent = true })

-- Show LSP references
map("n", "<leader>a", "<cmd>Telescope lsp_references<CR>", { silent = true })

-- Show buffer diagnostics
map("n", "<leader>s", "<cmd>Telescope diagnostics bufnr=0<CR>", { silent = true })

-- Show documentation for what is under cursor
map("n", "<leader>i", vim.lsp.buf.hover, { silent = true })

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
map("n", "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", { silent = true })

-- Open trouble document diagnostics
map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { silent = true })

-- Open trouble quickfix list
map("n", "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", { silent = true })

-- Open trouble location list
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>", { silent = true })

-- Open todos in trouble
map("n", "<leader>xt", "<cmd>Trouble todo toggle<CR>", { silent = true })
