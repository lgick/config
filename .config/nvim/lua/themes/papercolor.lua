local C = {

  -- Grayscale (Оттенки серого)
  white = "#eeeeee",
  light_grey = "#d0d0d0",
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

  -- Дополнительные оттенки
  off_white = "#e4e4e4",
  concrete = "#c6c6c6",
  ash = "#b2b2b2",
  rust = "#af5f00",
  emerald = "#00af5f",
  sky = "#afd7ff",
  yellow = "#ffff5f",
  light_green = "#afffaf",
  light_orange = "#ffd787",
  light_pink = "#ffd7ff",
  light_yellow = "#ffffd7",
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
  H("LineNr", { fg = C.ash, bg = C.white })
  -- Номер текущей строки, где находится курсор
  H("CursorLineNr", { fg = C.rust, bg = C.white, bold = true })
  -- Колонка для значков (Git, LSP диагностика)
  H("SignColumn", { fg = C.green, bg = C.white })
  -- Скрытые символы (например, маркеры в Markdown)
  H("Conceal", { fg = C.ash, bg = C.white })
  -- Вертикальный разделитель окон (сплитов)
  H("VertSplit", { fg = C.cyan })
  H("WinSeparator", { link = "VertSplit" })
  -- Колонка для свёрнутого кода (фолдинга)
  H("FoldColumn", { fg = C.teal, bg = C.white })
  -- Курсор
  H("Cursor", { fg = C.white, bg = C.cyan })
  -- Подсветка строки с курсором
  H("CursorLine", { bg = C.off_white })
  -- Подсветка колонки с курсором
  H("CursorColumn", { bg = C.off_white })
  -- "Линейка", колонка-ограничитель (например, на 80 символов)
  H("ColorColumn", { bg = C.off_white })
  -- Найденные при поиске совпадения
  H("Search", { fg = C.dark_grey, bg = C.yellow })
  -- Подсветка совпадений при интерактивном поиске (по мере ввода)
  H("IncSearch", { fg = C.yellow, bg = C.dark_grey })
  -- Статус-бар активного окна
  H("StatusLine", { fg = C.off_white, bg = C.cyan })
  -- Статус-бар неактивных окон
  H("StatusLineNC", { fg = C.dark_grey, bg = C.light_grey })
  -- Выделенный текст в визуальном режиме
  H("Visual", { fg = C.white, bg = C.teal })
  -- Подсветка парных скобок (), [], {}
  H("MatchParen", { fg = C.cyan, bg = C.concrete, bold = true })
  -- Текст, представляющий свёрнутый блок кода
  H("Folded", { fg = C.teal, bg = C.sky })
  -- Меню автодополнения для команд (:... при нажатии Tab)
  H("WildMenu", { fg = C.dark_grey, bg = C.yellow, bold = true })
  -- Всплывающее меню автодополнения (LSP, cmp)
  H("Pmenu", { fg = C.dark_grey, bg = C.light_grey })
  -- Выбранный элемент в меню автодополнения
  H("PmenuSel", { bg = C.teal, fg = C.white, bold = true })
  -- Неактивные вкладки в таб-баре
  H("TabLine", { fg = C.white, bg = C.teal })
  -- Пустое пространство в таб-баре
  H("TabLineFill", { fg = C.cyan, bg = C.cyan })
  -- Активная вкладка
  H("TabLineSel", { fg = C.dark_grey, bg = C.off_white, bold = true })
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
  -- Цвет для невидимых символов
  H("Whitespace", { fg = C.dark_red })
  -- Кастомная группа для подсветки текста длиннее 80 символов
  H("OverLength", { fg = C.dark_red })

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
  H("Function", { fg = C.cyan })
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
  H("Error", { fg = C.dark_red, bg = C.light_pink, bold = true })
  -- Ключевые слова в комментариях (TODO, FIXME)
  H("Todo", { fg = C.emerald, bg = C.white, bold = true })
  -- Подчеркнутый текст (например, ссылки в help)
  H("Underlined", { underline = true })
  -- Заголовки (в Markdown, help файлах)
  H("Title", { fg = C.medium_grey })

  -- =======================
  -- Diff группы
  -- =======================

  -- Добавленные строки (обычно зеленые)
  H("DiffAdd", { fg = C.green, bg = C.light_green })
  -- Измененные строки (обычно оранжевые/желтые)
  H("DiffChange", { fg = C.dark_grey, bg = C.light_orange })
  -- Удаленные строки (обычно красные)
  H("DiffDelete", { fg = C.dark_red, bg = C.light_pink })
  -- Подсветка конкретного измененного текста внутри измененной строки
  H("DiffText", { fg = C.teal, bg = C.light_yellow, bold = true })

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
  H("@variable.builtin", { fg = C.pink })
  -- Параметры функций
  H("@variable.parameter", { fg = C.dark_grey })
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

  -- =======================
  -- NvimTree
  -- =======================
  -- Основной фон и цвет текста в окне дерева
  H("NvimTreeNormal", { fg = C.dark_grey, bg = C.white })
  -- Неактивное окно дерева
  H("NvimTreeNormalNC", { link = "NvimTreeNormal" })
  -- Символы ~ внизу буфера
  H("NvimTreeEndOfBuffer", { fg = C.white })
  -- Вертикальный разделитель окна
  H("NvimTreeVertSplit", { link = "VertSplit" })
  -- Альтернативный разделитель окна
  H("NvimTreeWinSeparator", { link = "VertSplit" })
  -- Подсветка строки под курсором
  H("NvimTreeCursorLine", { link = "CursorLine" })
  -- Подсветка колонки под курсором
  H("NvimTreeCursorColumn", { link = "CursorColumn" })

  -- Текст файлов и папок
  -- Имя корневой папки
  H("NvimTreeRootFolder", { fg = C.pink, bold = true })
  -- Имена папок
  H("NvimTreeFolderName", { fg = C.blue })
  -- Имя открытой папки
  H("NvimTreeOpenedFolderName", { fg = C.blue, italic = true })
  -- Исполняемые файлы
  H("NvimTreeExecFile", { fg = C.olive, bold = true })
  -- Специальные файлы (например, README, LICENSE)
  H("NvimTreeSpecialFile", { link = "NvimTreeNormal" })
  -- Символические ссылки
  H("NvimTreeSymlink", { fg = C.teal, italic = true })
  -- Файлы изображений
  H("NvimTreeImageFile", { link = "NvimTreeNormal" })

  -- Иконки
  -- Иконка папки
  H("NvimTreeFolderIcon", { fg = C.blue })
  -- Иконка открытой папки
  H("NvimTreeOpenedFolderIcon", { link = "NvimTreeFolderIcon" })
  -- Иконка файла
  H("NvimTreeFileIcon", { fg = C.dark_grey })
  -- Линии-отступы в дереве
  H("NvimTreeIndentMarker", { fg = C.light_grey })
  -- Стрелка у закрытой папки
  H("NvimTreeFolderArrowClosed", { fg = C.medium_grey })
  -- Стрелка у открытой папки
  H("NvimTreeFolderArrowOpen", { fg = C.medium_grey })

  -- Состояния Git
  -- Иконка: файл удалён
  H("NvimTreeGitDeletedIcon", { fg = C.dark_red })
  -- Имя файла: удалён
  H("NvimTreeGitFileDeletedHL", { fg = C.dark_red })
  -- Иконка: изменён
  H("NvimTreeGitDirtyIcon", { fg = C.orange })
  -- Имя файла: изменён
  H("NvimTreeGitFileDirtyHL", { fg = C.orange })
  -- Иконка: игнорируется (.gitignore)
  H("NvimTreeGitIgnoredIcon", { fg = C.medium_grey })
  -- Имя файла: игнорируется
  H("NvimTreeGitFileIgnoredHL", { fg = C.medium_grey })
  -- Иконка: конфликт при merge
  H("NvimTreeGitMergeIcon", { fg = C.pink })
  -- Имя файла: конфликт при merge
  H("NvimTreeGitFileMergeHL", { fg = C.pink })
  -- Иконка: новый файл (untracked)
  H("NvimTreeGitNewIcon", { fg = C.red })
  -- Имя файла: новый
  H("NvimTreeGitFileNewHL", { fg = C.red })
  -- Иконка: файл переименован
  H("NvimTreeGitRenamedIcon", { fg = C.green })
  -- Имя файла: переименован
  H("NvimTreeGitFileRenamedHL", { fg = C.green })
  -- Иконка: файл подготовлен (staged)
  H("NvimTreeGitStagedIcon", { fg = C.green })
  -- Имя файла: staged
  H("NvimTreeGitFileStagedHL", { fg = C.green })

  -- Диагностика (ссылаемся на уже определенные цвета LSP для консистентности)
  -- Иконка ошибки
  H("NvimTreeDiagnosticErrorIcon", { link = "DiagnosticError" })
  -- Иконка предупреждения
  H("NvimTreeDiagnosticWarnIcon", { link = "DiagnosticWarn" })
  -- Иконка информации
  H("NvimTreeDiagnosticInfoIcon", { link = "DiagnosticInfo" })
  -- Иконка подсказки
  H("NvimTreeDiagnosticHintIcon", { link = "DiagnosticHint" })
  -- Файл с ошибкой
  H("NvimTreeDiagnosticErrorFileHL", { link = "DiagnosticUnderlineError" })
  -- Файл с предупреждением
  H("NvimTreeDiagnosticWarnFileHL", { link = "DiagnosticUnderlineWarn" })
  -- Файл с информацией
  H("NvimTreeDiagnosticInfoFileHL", { link = "DiagnosticUnderlineInfo" })
  -- Файл с подсказкой
  H("NvimTreeDiagnosticHintFileHL", { link = "DiagnosticUnderlineHint" })

  -- Буфер обмена, закладки, открытые и измененные файлы
  -- Подсветка скопированных файлов
  H("NvimTreeCopiedHL", { bg = C.olive, fg = C.white })
  -- Подсветка вырезанных файлов
  H("NvimTreeCutHL", { bg = C.red, fg = C.white })
  -- Иконка закладки
  H("NvimTreeBookmarkIcon", { fg = C.pink })
  -- Файл с закладкой
  H("NvimTreeBookmarkHL", { fg = C.pink })
  -- Иконка изменённого файла
  H("NvimTreeModifiedIcon", { fg = C.cyan })
  -- Имя изменённого файла
  H("NvimTreeModifiedFileHL", { fg = C.cyan })
  -- Подсветка открытых файлов
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
  if vim.api.nvim_command then
    vim.api.nvim_command("hi clear")
  else
    vim.cmd.hi("clear")
  end

  if vim.fn.exists("syntax_on") then
    vim.cmd.syntax("reset")
  end

  vim.g.colors_name = "PaperColor"

  -- рендерер хайлайтов
  set_highlights()
end

return C
