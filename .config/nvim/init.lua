local vim = vim
local g = vim.g
local opt = vim.opt
local wo = vim.wo
local map = vim.keymap.set
local cmd = vim.cmd
local Plug = vim.fn['plug#']

g.mapleader = ","

vim.call('plug#begin')

-- Цветовая схема
Plug('catppuccin/nvim', {['as'] = 'catppuccin'})

-- Treesitter: Подсветка синтаксиса
Plug('nvim-treesitter/nvim-treesitter', {['do'] = ':TSUpdate'})

-- Nerdtree: навигация по файлам
Plug('preservim/nerdtree', { ['on'] = 'NERDTreeToggle' })
g.NERDTreeRespectWildIgnore = 1

-- LSP & autocomplete
Plug('neovim/nvim-lspconfig')
Plug('hrsh7th/cmp-nvim-lsp')
Plug('hrsh7th/cmp-buffer')
Plug('hrsh7th/cmp-path')
Plug('hrsh7th/cmp-cmdline')
Plug('hrsh7th/nvim-cmp')
-- For vsnip users.
Plug('hrsh7th/cmp-vsnip')
Plug('hrsh7th/vim-vsnip')

-- Mason: добавление серверов, форматеров
Plug('williamboman/mason.nvim')

-- Telescope: поиск
Plug('nvim-lua/plenary.nvim')
Plug('nvim-telescope/telescope.nvim', { ['tag'] = '0.1.8' })

-- Null-ls: диагностика
Plug('jose-elias-alvarez/null-ls.nvim')

vim.call('plug#end')


----------------------------------------
-- Общие настройки VIM
----------------------------------------

-- Вкладки с файлами и статусная строка
-- 0: Никогда не показывать
-- 1: Показывать если больше чем 1
-- 2: Всегда показывать
opt.showtabline = 1
opt.laststatus = 2

-- Команданая строка
-- Размер высоты
opt.cmdheight = 1

-- Номерация строк
opt.number = true
opt.relativenumber = true

-- Скрыть вывод информации в нумерации
opt.signcolumn = "no"

-- Количество символов в номерации строк
opt.numberwidth = 4

-- Отображение имени буфера в заголовке терминала
opt.title = true

-- Запрет переноса строк
opt.wrap = false

-- Отступы сверху и снизу при скролле
opt.scrolloff = 10

-- Вертикальное окно справа
opt.splitright = true

-- Горизонтальная линия курсора
opt.cursorline = false

-- Вертикальная линия курсора
opt.cursorcolumn = false


------------------------------------------
-- Форматирование текста
------------------------------------------

-- Установить keymap
opt.keymap= "russian-jcukenmac"

-- Переключение языка в режиме ввода
map("i", "<C-l>", "<C-^>")

-- Переключение языка в режиме поиска
map("c", "<C-l>", "<C-^>")

-- По умолчанию - латинская раскладка
opt.iminsert = 0

-- По умолчанию - латинская раскладка при поиске
opt.imsearch = 0

-- Невидимый курсор мыши при наборе текста
opt.mousehide = true

-- Кодировка
opt.fileencodings = "utf8,cp1251"
opt.encoding = "utf-8"

-- Отключение .swp и резервных файлов
opt.backup = false
opt.swapfile = false

-- Опции при удалении в режиме ввода
opt.backspace = "indent,eol,start"

-- Умные отступы
--opt.cin
--opt.autoindent
opt.smartindent = true

-- Пробельные символы на кнопке <tab>
opt.expandtab = true

-- Количество символов за одно нажание на TAB
opt.tabstop = 2

-- Количиство символов при автоматическом табе
opt.shiftwidth = 2

-- Настройка сессий
opt.sessionoptions = "buffers,folds,sesdir,tabpages,globals,options,resize,winpos"


------------------------------------------
-- Hardcore mode
------------------------------------------

-- Отключение стрелочек
map("n", "<Up>", "<nop>")
map("n", "<Down>", "<nop>")
map("n", "<Left>", "<nop>")
map("n", "<Right>", "<nop>")
map("i", "<BS>", "<nop>")


------------------------------------------
-- Дата и время
------------------------------------------

opt.statusline = "%<%f%h%m%r [%{&fenc}] %=%c|%l/%L %P [%{strftime('%a %d.%m.%Y %H:%M')}]"


------------------------------------------
-- Цвет
------------------------------------------

-- 24-битные цвета
opt.termguicolors = true

-- Цветовая схема
cmd('silent! colorscheme catppuccin-frappe')

-- Цвет невидимых символов listchars
cmd("highlight Whitespace guifg = #af0000 guibg = none")

-- Цвет колонки-ограничителя
cmd("highlight ColorColumn guifg = none guibg = #005f87")


------------------------------------------
-- Невидимые символы (пробелы, табуляция)
------------------------------------------

-- Включение отображения невидимых символов
opt.list = true

-- Вид табуляции и пробела
opt.listchars = {
  tab = "· ",
  trail = "·",
  extends = ">",
  precedes = "<",
  nbsp = "&"
}


------------------------------------------
-- Поиск
------------------------------------------

-- Подсветка искомых значений
opt.hlsearch = true

-- Выделение слова с знаком '-'
opt.iskeyword:append("-")

-- Быстрый переход к искомому значению
opt.incsearch = true

-- Регистр при поиске
opt.ignorecase = true

-- Умный поиск
opt.smartcase = true

-- Игнорируемые расширения файлов (для nerdtree)
opt.wildignore:append("*.pyc,*.o,*.obj,*.svn,*.swp,*.class,*.hg,*.DS_Store,*.tmp,*.zip")


----------------------------------------
-- Сворачивание блоков кода
----------------------------------------

-- Включить сворачивание
opt.foldenable = true

-- Метод определения блоков свертки
-- indent: отступами
-- syntax: синтаксический
-- manual: вручную
opt.foldmethod = "manual"
--opt.foldmethod = "expr"
--opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Полоса отображения свернутых/развернутых блоков
opt.foldcolumn = "0"

-- Уровень сверачивания блоков по умолчанию
opt.foldlevel = 0

-- Автоматическое открытие сверток при заходе на них
--opt.foldopen = "all"

-- Автоматическое закрытие сверток при уходе с них
--opt.foldclose = "all"

-- Глубина сворачивания
opt.foldnestmax = 4

map("i", "<leader>z", "<C-O>za")
map("n", "<leader>z", "za")
map("o", "<leader>z", "<C-C>za")
map("v", "<leader>z", "zf")


----------------------------------------
-- Автозавершение & Синтаксис
----------------------------------------

-- Сигнал ошибке при отсутствии открывающей скобки
opt.showmatch = true

-- Отключение добавления первого значения при вызове <c-x><c-o>
opt.completeopt = "longest,menuone"


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
map("n", "<leader>f", ":NERDTreeToggle<CR>", { silent = true })

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

-- , + w: Git blame (who)
---map <silent> <leader>w :Git blame<CR>


----------------------------------------
-- Plugins
----------------------------------------
require("plugins.treesitter")
require("plugins.lsp")
require("plugins.cmp")
require("plugins.mason")
require("plugins.telescope")
require("plugins.null-ls")
