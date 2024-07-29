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

-- , + d: Bbye - закрывает файл
map("n", "<leader>d", ":bdel<CR>", { silent = true })

-- , + c: Копирование в системный буфер
map("v", "<leader>c", "\"+y", { silent = true })

-- , + v: Вставка из системного буфера
map("n", "<leader>v", "\"+p", { silent = true })

-- , + f: Файловая система
-- map("n", "<leader>f", ":NERDTreeToggle<CR>", { silent = true })

-- , + l: Подсветка координат курсора
map("n", "<leader>l", ":lua ToggleCursorLight()<CR>", { silent = true })

local cursorLight = false

function ToggleCursorLight()
  if cursorLight == true then
    opt.cursorline = false
    opt.cursorcolumn = false
    cursorLight = false
  else
    opt.cursorline = true
    opt.cursorcolumn = true
    cursorLight = true
  end
end
