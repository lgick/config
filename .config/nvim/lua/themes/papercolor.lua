local C = {

  -- Grayscale (Оттенки серого)
  white = "#eeeeee",
  light_grey = "#bcbcbc",
  medium_grey = "#878787",
  dark_grey = "#444444",

  -- Warm Colors (Тёплые цвета)
  red = "#d70000",
  dark_red = "#af0000",
  orange = "#d75f00",
  pink = "#d70087",

  -- Cool Colors (Холодные цвета)
  green = "#008700",
  olive = "#5f8700",
  teal = "#0087af",
  cyan = "#005f87",
  blue = "#005faf",
  purple = "#8700af",

  cursor_fg = "#eeeeee",
  cursor_bg = "#005f87",
  cursorline = "#e4e4e4",
  cursorcolumn = "#e4e4e4",
  cursorlinenr_fg = "#af5f00",
  cursorlinenr_bg = "#eeeeee",
  popupmenu_fg = "#444444",
  popupmenu_bg = "#d0d0d0",
  search_fg = "#444444",
  search_bg = "#ffff5f",
  incsearch_fg = "#ffff5f",
  incsearch_bg = "#444444",
  linenumber_fg = "#b2b2b2",
  linenumber_bg = "#eeeeee",
  vertsplit_fg = "#005f87",
  vertsplit_bg = "#eeeeee",
  statusline_active_fg = "#e4e4e4",
  statusline_active_bg = "#005f87",
  statusline_inactive_fg = "#444444",
  statusline_inactive_bg = "#d0d0d0",
  todo_fg = "#00af5f",
  todo_bg = "#eeeeee",
  error_fg = "#af0000",
  error_bg = "#ffd7ff",
  matchparen_fg = "#005f87",
  matchparen_bg = "#c6c6c6",
  visual_fg = "#eeeeee",
  visual_bg = "#0087af",
  folded_fg = "#0087af",
  folded_bg = "#afd7ff",
  wildmenu_fg = "#444444",
  wildmenu_bg = "#ffff00",
  diffadd_fg = "#008700",
  diffadd_bg = "#afffaf",
  diffdelete_fg = "#af0000",
  diffdelete_bg = "#ffd7ff",
  difftext_fg = "#0087af",
  difftext_bg = "#ffffd7",
  diffchange_fg = "#444444",
  diffchange_bg = "#ffd787",
  tabline_bg = "#005f87",
  tabline_active_fg = "#444444",
  tabline_active_bg = "#e4e4e4",
  tabline_inactive_fg = "#eeeeee",
  tabline_inactive_bg = "#0087af",
}

-- 1. ФУНКЦИЯ, СОЗДАЮЩАЯ ХАЙЛАЙТЫ
local function set_highlights()
  -- Вспомогательная функция для установки хайлайтов
  local H = function(group, style)
    vim.api.nvim_set_hl(0, group, style)
  end
  -- =======================
  -- UI Редактора
  -- =======================

  -- Основной текст и фон редактора
  H("Normal", { fg = C.dark_grey, bg = C.white })
  -- Символы, не являющиеся текстом (~ в конце файла, @)
  H("NonText", { fg = C.light_grey, bg = C.white })
  -- Номера строк в боковой колонке
  H("LineNr", { fg = C.linenumber_fg, bg = C.linenumber_bg })
  -- Номер текущей строки, где находится курсор
  H("CursorLineNr", { fg = C.cursorlinenr_fg, bg = C.cursorlinenr_bg, bold = true })
  -- Колонка для значков (Git, LSP диагностика)
  H("SignColumn", { fg = C.green, bg = C.white })
  -- Скрытые символы (например, маркеры в Markdown)
  H("Conceal", { fg = C.linenumber_fg, bg = C.linenumber_bg })
  -- Вертикальный разделитель окон (сплитов)
  H("VertSplit", { fg = C.vertsplit_fg, bg = C.vertsplit_bg })
  -- Колонка для свёрнутого кода (фолдинга)
  H("FoldColumn", { fg = C.folded_fg, bg = C.white })
  -- Курсор
  H("Cursor", { fg = C.cursor_fg, bg = C.cursor_bg })
  -- Подсветка строки с курсором
  H("CursorLine", { bg = C.cursorline })
  -- Подсветка колонки с курсором
  H("CursorColumn", { bg = C.cursorcolumn })
  -- "Линейка", колонка-ограничитель (например, на 80 символов)
  H("ColorColumn", { bg = C.cursorcolumn })
  -- Найденные при поиске совпадения
  H("Search", { fg = C.search_fg, bg = C.search_bg })
  -- Подсветка совпадений при интерактивном поиске (по мере ввода)
  H("IncSearch", { fg = C.incsearch_fg, bg = C.incsearch_bg })
  -- Статус-бар активного окна
  H("StatusLine", { fg = C.statusline_active_fg, bg = C.statusline_active_bg })
  -- Статус-бар неактивных окон
  H("StatusLineNC", { fg = C.statusline_inactive_fg, bg = C.statusline_inactive_bg })
  -- Выделенный текст в визуальном режиме
  H("Visual", { fg = C.visual_fg, bg = C.visual_bg })
  -- Подсветка парных скобок (), [], {}
  H("MatchParen", { fg = C.matchparen_fg, bg = C.matchparen_bg, bold = true })
  -- Текст, представляющий свёрнутый блок кода
  H("Folded", { fg = C.folded_fg, bg = C.folded_bg })
  -- Меню автодополнения для команд (:... при нажатии Tab)
  H("WildMenu", { fg = C.wildmenu_fg, bg = C.wildmenu_bg, bold = true })
  -- Всплывающее меню автодополнения (LSP, cmp)
  H("Pmenu", { fg = C.popupmenu_fg, bg = C.popupmenu_bg })
  -- Выбранный элемент в меню автодополнения
  H("PmenuSel", { bg = C.visual_bg, fg = C.visual_fg, bold = true })
  -- Неактивные вкладки в таб-баре
  H("TabLine", { fg = C.tabline_inactive_fg, bg = C.tabline_inactive_bg })
  -- Пустое пространство в таб-баре
  H("TabLineFill", { fg = C.tabline_bg, bg = C.tabline_bg })
  -- Активная вкладка
  H("TabLineSel", { fg = C.tabline_active_fg, bg = C.tabline_active_bg, bold = true })
  -- Непечатаемые символы (когда включен `:set list`)
  H("SpecialKey", { fg = C.light_grey })
  -- Имена директорий (в file explorer'ах, :edit .)
  H("Directory", { fg = C.blue })
  -- Сообщение о режиме (-- INSERT --, -- VISUAL --)
  H("ModeMsg", { fg = C.olive })
  -- Приглашение "-- More --", когда текст не помещается
  H("MoreMsg", { fg = C.olive })
  -- Интерактивные вопросы, требующие ввода
  H("Question", { fg = C.green })

  -- =======================
  -- Базовая подсветка (Vim Syntax)
  -- =======================

  -- Комментарии (//, /* */)
  H("Comment", { fg = C.medium_grey, italic = true })
  -- Константы и литералы (числа, строки)
  H("Constant", { fg = C.orange })
  -- Строковые литералы ("...", '...')
  H("String", { fg = C.olive })
  -- Символьные литералы ('a')
  H("Character", { fg = C.olive })
  -- Числа (123, 0x0)
  H("Number", { fg = C.orange })
  -- Числа с плавающей точкой (12.3)
  H("Float", { fg = C.orange })
  -- Булевы значения (true, false)
  H("Boolean", { fg = C.orange })
  -- Имена переменных
  H("Identifier", { fg = C.dark_grey })
  -- Имена функций
  H("Function", { fg = C.cyan, bold = true })
  -- Ключевые слова-инструкции (return, import)
  H("Statement", { fg = C.purple })
  -- Условные операторы (if, else, switch)
  H("Conditional", { fg = C.purple })
  -- Операторы цикла (for, while, do)
  H("Repeat", { fg = C.purple })
  -- Метки (case, goto label:)
  H("Label", { fg = C.blue })
  -- Операторы (+, -, *, =, !)
  H("Operator", { fg = C.teal })
  -- Прочие ключевые слова, не попавшие выше
  H("Keyword", { fg = C.purple })
  -- Ключевые слова для исключений (try, catch)
  H("Exception", { fg = C.red })
  -- Директивы препроцессора (#include)
  H("PreProc", { fg = C.blue })
  -- Директивы подключения (#include, require)
  H("Include", { fg = C.red })
  -- Директивы определения (#define)
  H("Define", { fg = C.blue })
  -- Использование макросов
  H("Macro", { fg = C.blue })
  -- Условные директивы препроцессора (#ifdef)
  H("PreCondit", { fg = C.teal })
  -- Встроенные типы (int, char, string)
  H("Type", { fg = C.cyan, bold = true })
  -- Модификаторы хранения (static, const, public)
  H("StorageClass", { fg = C.green, bold = true })
  -- Ключевые слова для структур (struct, enum, class)
  H("Structure", { fg = C.green, bold = true })
  -- Определение пользовательских типов (typedef)
  H("Typedef", { fg = C.cyan, bold = true })
  -- Специальные символы (напр. \n в строках)
  H("Special", { fg = C.dark_grey })
  -- Ошибки синтаксиса
  H("Error", { fg = C.error_fg, bg = C.error_bg, bold = true })
  -- Ключевые слова в комментариях (TODO, FIXME)
  H("Todo", { fg = C.todo_fg, bg = C.todo_bg, bold = true })
  -- Подчеркнутый текст (например, ссылки в help)
  H("Underlined", { underline = true })
  -- Заголовки (в Markdown, help файлах)
  H("Title", { fg = C.medium_grey })

  -- =======================
  -- Diff группы
  -- =======================

  -- Добавленные строки (обычно зеленые)
  H("DiffAdd", { fg = C.diffadd_fg, bg = C.diffadd_bg })
  -- Измененные строки (обычно оранжевые/желтые)
  H("DiffChange", { fg = C.diffchange_fg, bg = C.diffchange_bg })
  -- Удаленные строки (обычно красные)
  H("DiffDelete", { fg = C.diffdelete_fg, bg = C.diffdelete_bg })
  -- Подсветка конкретного измененного текста внутри измененной строки
  H("DiffText", { fg = C.difftext_fg, bg = C.difftext_bg, bold = true })

  -- =======================
  -- Treesitter (полная версия)
  -- =======================

  -- Обычные комментарии
  H("@comment", { link = "Comment" })
  -- Документационные комментарии (JSDoc, docstrings)
  H("@comment.documentation", { link = "Comment" })
  -- Специальные теги: NOTE, INFO
  H("@comment.note", { fg = C.blue, bold = true, italic = true })
  -- Специальные теги: TODO, WIP
  H("@comment.todo", { link = "Todo" })
  -- Специальные теги: WARNING, HACK
  H("@comment.warning", { fg = C.orange, bold = true, italic = true })
  -- Специальные теги: FIXME, ERROR
  H("@comment.error", { link = "Error" })

  -- Строки
  H("@string", { link = "String" })
  -- Строки-документация (как в Python)
  H("@string.documentation", { link = "@comment.documentation" })
  -- Регулярные выражения
  H("@string.regexp", { fg = C.pink })
  -- Управляющие последовательности (\n, \t)
  H("@string.escape", { fg = C.teal })
  -- Специальные строки (символы в Ruby)
  H("@string.special", { fg = C.purple })
  -- URL-адреса
  H("@string.special.url", { fg = C.blue, underline = true })
  -- Пути к файлам
  H("@string.special.path", { fg = C.blue })

  -- Символы ('a')
  H("@character", { link = "Character" })
  -- Специальные символы (wildcards)
  H("@character.special", { fg = C.pink })

  -- Булевы значения (true, false)
  H("@boolean", { link = "Boolean" })
  -- Числа
  H("@number", { link = "Number" })
  -- Числа с плавающей точкой
  H("@number.float", { link = "Float" })

  -- Переменные
  H("@variable", { fg = C.dark_grey })
  -- Встроенные переменные (`this`, `self`)
  H("@variable.builtin", { fg = C.pink, italic = true })
  -- Параметры функций
  H("@variable.parameter", { fg = C.dark_grey, italic = true })
  -- Поля/свойства объектов (`obj.field`)
  H("@variable.member", { fg = C.blue })

  -- Имена свойств (ключи в key/value)
  H("@property", { link = "@variable.member" })

  ---- Константы
  H("@constant", { fg = C.orange })
  -- Встроенные константы (`nil`, `true`)
  H("@constant.builtin", { fg = C.cyan, bold = true })
  -- Макросы-константы
  H("@constant.macro", { fg = C.blue })

  -- Модули и пространства имен (`namespace`)
  H("@module", { link = "Type" })
  -- Метки (для `goto`)
  H("@label", { link = "Label" })

  -- Определения функций
  H("@function", { link = "Function" })
  -- Встроенные функции
  H("@function.builtin", { fg = C.purple, italic = true })
  -- Вызовы функций
  H("@function.call", { fg = C.cyan })
  -- Макросы-функции
  H("@function.macro", { fg = C.blue })

  -- Определения методов
  H("@function.method", { link = "@function" })

  -- Вызовы методов
  H("@function.method.call", { link = "@function.call" })

  -- Конструкторы (`new MyClass()`)
  H("@constructor", { fg = C.green, bold = true })
  -- Операторы (+, *, and, or)
  H("@operator", { link = "Operator" })

  -- Общие ключевые слова
  H("@keyword", { link = "Keyword" })
  -- Ключевые слова для функций (`def`, `function`)
  H("@keyword.function", { fg = C.purple })
  -- Словесные операторы (`and`, `or`)
  H("@keyword.operator", { link = "Operator" })
  -- Импорт/экспорт (`import`, `require`)
  H("@keyword.import", { link = "Include" })
  -- Циклы (`for`, `while`)
  H("@keyword.repeat", { link = "Repeat" })
  -- Условия (`if`, `else`)
  H("@keyword.conditional", { link = "Conditional" })
  -- Обработка исключений (`try`, `catch`)
  H("@keyword.exception", { link = "Exception" })
  -- Возврат значения (`return`, `yield`)
  H("@keyword.return", { fg = C.purple })
  -- Модификаторы (`static`, `public`, `const`)
  H("@keyword.modifier", { link = "StorageClass" })

  -- Имена типов и классов
  H("@type", { link = "Type" })
  -- Встроенные типы (`string`, `number`)
  H("@type.builtin", { link = "Type" })
  -- Определение типа (`typedef <имя>`)
  H("@type.definition", { link = "Type" })

  -- Атрибуты и декораторы (`@override`)
  H("@attribute", { fg = C.olive })
  -- HTML/XML теги (`<div>`)
  H("@tag", { fg = C.red })
  -- Атрибуты тегов (`class=`, `id=`)
  H("@tag.attribute", { fg = C.purple })
  -- Скобки тегов (`<`, `>`)
  H("@tag.delimiter", { fg = C.medium_grey })

  -- Разделители (`,` `;` `.`)
  H("@punctuation.delimiter", { fg = C.medium_grey })
  -- Скобки (`()` `{}` `[]`)
  H("@punctuation.bracket", { fg = C.dark_grey })
  -- Специальная пунктуация (например, `${}` в строках)
  H("@punctuation.special", { fg = C.teal })

  -- ### Разметка (Markdown, и т.д.) ###
  -- Жирный текст
  H("@markup.strong", { bold = true })
  -- Курсивный текст
  H("@markup.italic", { italic = true })
  -- Зачеркнутый текст
  H("@markup.strikethrough", { strikethrough = true })
  -- Подчеркнутый текст
  H("@markup.underline", { underline = true })
  -- Заголовки
  H("@markup.heading", { fg = C.olive, bold = true })
  -- Цитаты
  H("@markup.quote", { fg = C.teal, italic = true })
  -- Математические выражения
  H("@markup.math", { fg = C.orange })
  -- Ссылки
  H("@markup.link", { link = "@markup.link.label" })
  -- Текст ссылки
  H("@markup.link.label", { fg = C.blue })
  -- URL в ссылке
  H("@markup.link.url", { link = "@string.special.url" })
  -- Маркеры списков
  H("@markup.list", { fg = C.orange })
  -- Отмеченные пункты списка ([x])
  H("@markup.list.checked", { fg = C.green })
  -- Неотмеченные пункты списка ([ ])
  H("@markup.list.unchecked", { fg = C.red })

  -- ### Diff ###
  -- Добавленный текст в diff
  H("@diff.plus", { link = "DiffAdd" })
  -- Удаленный текст в diff
  H("@diff.minus", { link = "DiffDelete" })
  -- Измененный текст в diff
  H("@diff.delta", { link = "DiffChange" })

  -- Константы (цвета, переменные)
  H("@constant.css", { fg = C.dark_red })
  -- Имена тегов (div, span)
  H("@tag.css", { fg = C.dark_red })
  -- Имена типов (#id)
  H("@type.css", { fg = C.dark_red })
  -- Атрибуты ([href])
  H("@attribute.css", { fg = C.dark_red })
  -- Разделители (,)
  H("@punctuation.delimiter.css", { fg = C.dark_red })
  -- CSS свойства (color, font-size)
  H("@property.css", { fg = C.blue })

  -- =======================
  -- LSP & Диагностика
  -- =======================

  -- Эти группы определяют цвета для разных уровней сообщений от LSP
  -- Ошибки
  H("LspDiagnosticsDefaultError", { fg = C.dark_red })
  -- Предупреждения
  H("LspDiagnosticsDefaultWarning", { fg = C.green })
  -- Информация
  H("LspDiagnosticsDefaultInformation", { fg = C.blue })
  -- Подсказки
  H("LspDiagnosticsDefaultHint", { fg = C.teal })

  -- Стили для иконок ( ) в боковой колонке и для виртуального текста
  H("DiagnosticError", { link = "LspDiagnosticsDefaultError" })
  H("DiagnosticWarn", { link = "LspDiagnosticsDefaultWarning" })
  H("DiagnosticInfo", { link = "LspDiagnosticsDefaultInformation" })
  H("DiagnosticHint", { link = "LspDiagnosticsDefaultHint" })

  -- Волнистое подчеркивание (undercurl) для кода с проблемами
  H("DiagnosticUnderlineError", { undercurl = true, sp = C.dark_red })
  H("DiagnosticUnderlineWarn", { undercurl = true, sp = C.green })
  H("DiagnosticUnderlineInfo", { undercurl = true, sp = C.blue })
  H("DiagnosticUnderlineHint", { undercurl = true, sp = C.teal })

  -- =======================
  --  Mason, aerial, trouble
  -- =======================

  -- Эти группы создают единый стиль для всех всплывающих окон
  -- Фон всплывающих окон (LSP hover, Mason и т.д.)
  H("NormalFloat", { bg = C.light_grey })
  -- Рамка всплывающих окон
  H("FloatBorder", { fg = C.cyan, bg = C.light_grey })

  -- Стили для конкретных плагинов, наследующие общий вид для консистентности
  H("MasonNormal", { link = "NormalFloat" })
  H("TroubleNormal", { link = "NormalFloat" })
  H("AerialNormal", { link = "Normal" })

  --  -- =======================
  --  -- NvimTree
  --  -- =======================
  H("NvimTreeNormal", { fg = C.dark_grey, bg = C.white })
  H("NvimTreeNormalNC", { link = "NvimTreeNormal" })
  H("NvimTreeVertSplit", { fg = C.cyan, bg = C.white })
  H("NvimTreeEndOfBuffer", { fg = C.white })
  H("NvimTreeWinSeparator", { link = "VertSplit" })
  H("NvimTreeCursorLine", { link = "CursorLine" })
  H("NvimTreeCursorColumn", { link = "CursorColumn" })

  -- Текст файлов и папок
  H("NvimTreeRootFolder", { fg = C.pink, bold = true })
  H("NvimTreeFolderName", { fg = C.blue })
  H("NvimTreeOpenedFolderName", { fg = C.blue, italic = true })
  H("NvimTreeExecFile", { fg = C.olive, bold = true })
  H("NvimTreeSpecialFile", { link = "NvimTreeNormal" })
  H("NvimTreeSymlink", { fg = C.teal, italic = true })
  H("NvimTreeImageFile", { link = "NvimTreeNormal" })

  -- Иконки
  H("NvimTreeFolderIcon", { fg = C.blue })
  H("NvimTreeOpenedFolderIcon", { link = "NvimTreeFolderIcon" })
  H("NvimTreeFileIcon", { fg = C.dark_grey })
  H("NvimTreeIndentMarker", { fg = C.light_grey })
  H("NvimTreeFolderArrowClosed", { fg = C.medium_grey })
  H("NvimTreeFolderArrowOpen", { fg = C.medium_grey })

  -- Состояния Git
  H("NvimTreeGitDeletedIcon", { fg = C.dark_red })
  H("NvimTreeGitFileDeletedHL", { fg = C.dark_red })
  H("NvimTreeGitDirtyIcon", { fg = C.orange })
  H("NvimTreeGitFileDirtyHL", { fg = C.orange })
  H("NvimTreeGitIgnoredIcon", { fg = C.medium_grey })
  H("NvimTreeGitFileIgnoredHL", { fg = C.medium_grey })
  H("NvimTreeGitMergeIcon", { fg = C.pink })
  H("NvimTreeGitFileMergeHL", { fg = C.pink })
  H("NvimTreeGitNewIcon", { fg = C.red })
  H("NvimTreeGitFileNewHL", { fg = C.red })
  H("NvimTreeGitRenamedIcon", { fg = C.purple })
  H("NvimTreeGitFileRenamedHL", { fg = C.purple })
  H("NvimTreeGitStagedIcon", { fg = C.green })
  H("NvimTreeGitFileStagedHL", { fg = C.green })

  -- Диагностика (ссылаемся на уже определенные цвета LSP для консистентности)
  H("NvimTreeDiagnosticErrorIcon", { link = "DiagnosticError" })
  H("NvimTreeDiagnosticWarnIcon", { link = "DiagnosticWarn" })
  H("NvimTreeDiagnosticInfoIcon", { link = "DiagnosticInfo" })
  H("NvimTreeDiagnosticHintIcon", { link = "DiagnosticHint" })
  H("NvimTreeDiagnosticErrorFileHL", { link = "DiagnosticUnderlineError" })
  H("NvimTreeDiagnosticWarnFileHL", { link = "DiagnosticUnderlineWarn" })
  H("NvimTreeDiagnosticInfoFileHL", { link = "DiagnosticUnderlineInfo" })
  H("NvimTreeDiagnosticHintFileHL", { link = "DiagnosticUnderlineHint" })

  -- Буфер обмена, закладки, открытые и измененные файлы
  H("NvimTreeCopiedHL", { bg = C.olive, fg = C.white })
  H("NvimTreeCutHL", { bg = C.red, fg = C.white })
  H("NvimTreeBookmarkIcon", { fg = C.pink })
  H("NvimTreeBookmarkHL", { fg = C.pink })
  H("NvimTreeModifiedIcon", { fg = C.cyan })
  H("NvimTreeModifiedFileHL", { fg = C.cyan })
  H("NvimTreeOpenedHL", { fg = C.dark_grey, italic = true })

  -- nvim-cmp
  -- Текст элемента в меню
  H("CmpItemAbbr", { fg = C.dark_grey })
  -- Часть текста, совпадающая с вводом
  H("CmpItemAbbrMatch", { fg = C.blue, bold = true })
  -- Иконка типа (функция, переменная)
  H("CmpItemKind", { fg = C.purple })
  -- Источник (LSP, Snippet)
  H("CmpItemMenu", { fg = C.medium_grey })

  -- git-blame
  ---- Текст с автором и датой коммита
  H("GitBlame", { fg = C.medium_grey, italic = true })
end

-- 2. ФУНКЦИЯ-ЗАГРУЗЧИК
function C.load()
  -- Сброс
  if vim.api.nvim_command then
    vim.api.nvim_command("hi clear")
  else
    vim.cmd.hi("clear")
  end

  if vim.fn.exists("syntax_on") then
    vim.cmd.syntax("reset")
  end

  vim.o.termguicolors = true
  vim.g.colors_name = "PaperColor"

  -- рендерер хайлайтов
  set_highlights()
end

return C
