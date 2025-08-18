-- Sets the view to treeview.
-- vim.cmd("let g:netrw_liststyle = 3")
--opt.clipboard:append("unnamedplus") -- use system clipboard as default register

local vim = vim
local opt = vim.opt

----------------------------------------
-- Общие настройки VIM
----------------------------------------

-- Вкладки с файлами и статусная строка
-- 0: Никогда не показывать
-- 1: Показывать если больше чем 1
-- 2: Всегда показывать
opt.showtabline = 1
opt.laststatus = 2

-- Размер высоты командной строки
opt.cmdheight = 1

-- Размер высоты окна с историей (CTRL-F) командной строки
opt.cmdwinheight = 20

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
opt.scrolloff = 5

-- Вертикальное окно справа
opt.splitright = true

-- Горизонтальное окно внизу
opt.splitbelow = true

-- Горизонтальная линия курсора
opt.cursorline = false

-- Вертикальная линия курсора
opt.cursorcolumn = false

------------------------------------------
-- Форматирование текста
------------------------------------------

-- Установить keymap
opt.keymap = "russian-jcukenmac"

-- По умолчанию - латинская раскладка
opt.iminsert = 0

-- По умолчанию - латинская раскладка при поиске
opt.imsearch = 0

-- Невидимый курсор мыши при наборе текста
opt.mousehide = true

-- Выделение мышкой
opt.mouse = "r"

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
-- opt.autoindent = true
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
-- Дата и время
------------------------------------------

opt.statusline = "%<%f%h%m%r [%{&fenc}] %=%c|%l/%L %P [%{strftime('%a %d.%m.%Y %H:%M')}]"

------------------------------------------
-- Цвет
------------------------------------------

-- 24-битные цвета
opt.termguicolors = true

-- темная цветовая схема
opt.background = "light"

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
  nbsp = "&",
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

-- Полоса отображения свернутых/развернутых блоков
opt.foldcolumn = "0"

----------------------------------------
-- Автозавершение & Синтаксис
----------------------------------------

-- Сигнал ошибке при отсутствии открывающей скобки
opt.showmatch = true

-- Отключение добавления первого значения при вызове <c-x><c-o>
--opt.completeopt = "longest,menuone"
opt.completeopt = { "menu", "menuone", "noselect" }
