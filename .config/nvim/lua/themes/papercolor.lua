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

  H("Normal", { fg = C.dark_grey, bg = C.white })
  H("NonText", { fg = C.light_grey, bg = C.white })
  H("LineNr", { fg = C.linenumber_fg, bg = C.linenumber_bg })
  H("CursorLineNr", { fg = C.cursorlinenr_fg, bg = C.cursorlinenr_bg, bold = true })
  H("SignColumn", { fg = C.green, bg = C.white })
  H("Conceal", { fg = C.linenumber_fg, bg = C.linenumber_bg })
  H("VertSplit", { fg = C.vertsplit_fg, bg = C.vertsplit_bg })
  H("FoldColumn", { fg = C.folded_fg, bg = C.white })
  H("Cursor", { fg = C.cursor_fg, bg = C.cursor_bg })
  H("CursorLine", { bg = C.cursorline })
  H("CursorColumn", { bg = C.cursorcolumn })
  H("ColorColumn", { bg = C.cursorcolumn })
  H("Search", { fg = C.search_fg, bg = C.search_bg })
  H("IncSearch", { fg = C.incsearch_fg, bg = C.incsearch_bg })
  H("StatusLine", { fg = C.statusline_active_fg, bg = C.statusline_active_bg, reverse = true }) -- Оригинал инвертирует цвета, делаем так же
  H("StatusLineNC", { fg = C.statusline_inactive_fg, bg = C.statusline_inactive_bg, reverse = true })
  H("Visual", { fg = C.visual_fg, bg = C.visual_bg })
  H("MatchParen", { fg = C.matchparen_fg, bg = C.matchparen_bg, bold = true })
  H("Folded", { fg = C.folded_fg, bg = C.folded_bg })
  H("WildMenu", { fg = C.wildmenu_fg, bg = C.wildmenu_bg, bold = true })
  H("Pmenu", { fg = C.popupmenu_fg, bg = C.popupmenu_bg })
  H("PmenuSel", { bg = C.visual_bg, fg = C.visual_fg, bold = true })
  H("TabLine", { fg = C.tabline_inactive_fg, bg = C.tabline_inactive_bg })
  H("TabLineFill", { fg = C.tabline_bg, bg = C.tabline_bg })
  H("TabLineSel", { fg = C.tabline_active_fg, bg = C.tabline_active_bg, bold = true })
  H("SpecialKey", { fg = C.light_grey })
  H("Directory", { fg = C.blue })
  H("ModeMsg", { fg = C.olive })
  H("MoreMsg", { fg = C.olive })
  H("Question", { fg = C.green })

  -- =======================
  -- Базовая подсветка (Vim Syntax)
  -- =======================
  H("Comment", { fg = C.medium_grey, italic = true }) -- Комментарии (//, /* */)
  H("Constant", { fg = C.orange }) -- Константы и литералы (числа, строки)
  H("String", { fg = C.olive }) -- Строковые литералы ("...", '...')
  H("Character", { fg = C.olive }) -- Символьные литералы ('a')
  H("Number", { fg = C.orange }) -- Числа (123, 0x0)
  H("Float", { fg = C.orange }) -- Числа с плавающей точкой (12.3)
  H("Boolean", { fg = C.orange }) -- Булевы значения (true, false)
  H("Identifier", { fg = C.dark_grey }) -- Имена переменных
  H("Function", { fg = C.cyan, bold = true }) -- Имена функций
  H("Statement", { fg = C.purple }) -- Ключевые слова-инструкции (return, import)
  H("Conditional", { fg = C.purple }) -- Условные операторы (if, else, switch)
  H("Repeat", { fg = C.purple }) -- Операторы цикла (for, while, do)
  H("Label", { fg = C.blue }) -- Метки (case, goto label:)
  H("Operator", { fg = C.teal }) -- Операторы (+, -, *, =, !)
  H("Keyword", { fg = C.purple }) -- Прочие ключевые слова, не попавшие выше
  H("Exception", { fg = C.red }) -- Ключевые слова для исключений (try, catch)
  H("PreProc", { fg = C.blue }) -- Директивы препроцессора (#include)
  H("Include", { fg = C.red }) -- Директивы подключения (#include, require)
  H("Define", { fg = C.blue }) -- Директивы определения (#define)
  H("Macro", { fg = C.blue }) -- Использование макросов
  H("PreCondit", { fg = C.teal }) -- Условные директивы препроцессора (#ifdef)
  H("Type", { fg = C.cyan, bold = true }) -- Встроенные типы (int, char, string)
  H("StorageClass", { fg = C.green, bold = true }) -- Модификаторы хранения (static, const, public)
  H("Structure", { fg = C.green, bold = true }) -- Ключевые слова для структур (struct, enum, class)
  H("Typedef", { fg = C.cyan, bold = true }) -- Определение пользовательских типов (typedef)
  H("Special", { fg = C.dark_grey }) -- Специальные символы (напр. \n в строках)
  H("Error", { fg = C.error_fg, bg = C.error_bg, bold = true }) -- Ошибки синтаксиса
  H("Todo", { fg = C.todo_fg, bg = C.todo_bg, bold = true }) -- Ключевые слова в комментариях (TODO, FIXME)
  H("Underlined", { underline = true }) -- Подчеркнутый текст (например, ссылки в help)
  H("Title", { fg = C.medium_grey }) -- Заголовки (в Markdown, help файлах)

  -- =======================
  -- Diff группы
  -- =======================

  H("DiffAdd", { fg = C.diffadd_fg, bg = C.diffadd_bg })
  H("DiffChange", { fg = C.diffchange_fg, bg = C.diffchange_bg })
  H("DiffDelete", { fg = C.diffdelete_fg, bg = C.diffdelete_bg })
  H("DiffText", { fg = C.difftext_fg, bg = C.difftext_bg, bold = true })

  -- =======================
  -- Treesitter (полная версия)
  -- =======================

  -- ### Комментарии ###
  H("@comment", { link = "Comment" })
  H("@comment.documentation", { link = "Comment" })
  H("@comment.note", { fg = C.blue, bold = true, italic = true })
  H("@comment.todo", { link = "Todo" })
  H("@comment.warning", { fg = C.orange, bold = true, italic = true })
  H("@comment.error", { link = "Error" })

  -- ### Литералы (строки, числа, и т.д.) ###
  H("@string", { link = "String" })
  H("@string.documentation", { link = "@comment.documentation" })
  H("@string.regexp", { fg = C.pink })
  H("@string.escape", { fg = C.teal })
  H("@string.special", { fg = C.purple })
  H("@string.special.url", { fg = C.blue, underline = true })
  H("@string.special.path", { fg = C.blue })

  H("@character", { link = "Character" })
  H("@character.special", { fg = C.pink })

  H("@boolean", { link = "Boolean" })
  H("@number", { link = "Number" })
  H("@number.float", { link = "Float" })

  -- ### Переменные и свойства ###
  H("@variable", { fg = C.dark_grey })
  H("@variable.builtin", { fg = C.pink, italic = true })
  H("@variable.parameter", { fg = C.dark_grey, italic = true })
  H("@variable.member", { fg = C.dark_grey })

  H("@property", { link = "@variable.member" })

  -- ### Константы и модули ###
  H("@constant", { fg = C.orange })
  H("@constant.builtin", { fg = C.cyan, bold = true })
  H("@constant.macro", { fg = C.blue })

  H("@module", { link = "Type" })
  H("@label", { link = "Label" })

  -- ### Функции и методы ###
  H("@function", { link = "Function" })
  H("@function.builtin", { fg = C.purple, italic = true })
  H("@function.call", { fg = C.cyan })
  H("@function.macro", { fg = C.blue })

  H("@function.method", { link = "@function" })
  H("@function.method.call", { link = "@function.call" })

  H("@constructor", { fg = C.green, bold = true })
  H("@operator", { link = "Operator" })

  -- ### Ключевые слова ###
  H("@keyword", { link = "Keyword" })
  H("@keyword.function", { fg = C.purple })
  H("@keyword.operator", { link = "Operator" })
  H("@keyword.import", { link = "Include" })
  H("@keyword.repeat", { link = "Repeat" })
  H("@keyword.conditional", { link = "Conditional" })
  H("@keyword.exception", { link = "Exception" })
  H("@keyword.return", { fg = C.purple })
  H("@keyword.modifier", { link = "StorageClass" })

  -- ### Типы ###
  H("@type", { link = "Type" })
  H("@type.builtin", { link = "Type" })
  H("@type.definition", { link = "Type" })

  -- ### Атрибуты и теги ###
  H("@attribute", { fg = C.olive })
  H("@tag", { fg = C.red })
  H("@tag.attribute", { fg = C.purple })
  H("@tag.delimiter", { fg = C.medium_grey })

  -- ### Пунктуация ###
  H("@punctuation.delimiter", { fg = C.medium_grey })
  H("@punctuation.bracket", { fg = C.dark_grey })
  H("@punctuation.special", { fg = C.teal })

  -- ### Разметка (Markdown, и т.д.) ###
  H("@markup.strong", { bold = true })
  H("@markup.italic", { italic = true })
  H("@markup.strikethrough", { strikethrough = true })
  H("@markup.underline", { underline = true })

  H("@markup.heading", { fg = C.olive, bold = true })
  H("@markup.quote", { fg = C.teal, italic = true })
  H("@markup.math", { fg = C.orange })

  H("@markup.link", { link = "@markup.link.label" })
  H("@markup.link.label", { fg = C.blue })
  H("@markup.link.url", { link = "@string.special.url" })

  H("@markup.list", { fg = C.orange })
  H("@markup.list.checked", { fg = C.green })
  H("@markup.list.unchecked", { fg = C.red })

  -- ### Diff ###
  H("@diff.plus", { link = "DiffAdd" })
  H("@diff.minus", { link = "DiffDelete" })
  H("@diff.delta", { link = "DiffChange" })

  H("@constant.css", { fg = C.dark_red })
  H("@tag.css", { fg = C.dark_red })
  H("@type.css", { fg = C.dark_red })
  H("@attribute.css", { fg = C.dark_red })
  H("@punctuation.delimiter.css", { fg = C.dark_red })
  H("@property.css", { fg = C.blue })

  --  -- =======================
  --  -- LSP & Plugins
  --  -- =======================
  --  -- LSP Диагностика
  --  H("LspDiagnosticsDefaultError", { fg = C.dark_red })
  --  H("LspDiagnosticsDefaultWarning", { fg = C.green })
  --  H("LspDiagnosticsDefaultInformation", { fg = C.blue })
  --  H("LspDiagnosticsDefaultHint", { fg = C.teal })
  --  H("DiagnosticError", { link = "LspDiagnosticsDefaultError" })
  --  H("DiagnosticWarn", { link = "LspDiagnosticsDefaultWarning" })
  --  H("DiagnosticInfo", { link = "LspDiagnosticsDefaultInformation" })
  --  H("DiagnosticHint", { link = "LspDiagnosticsDefaultHint" })
  --  H("DiagnosticUnderlineError", { undercurl = true, sp = C.dark_red })
  --  H("DiagnosticUnderlineWarn", { undercurl = true, sp = C.green })
  --  H("DiagnosticUnderlineInfo", { undercurl = true, sp = C.blue })
  --  H("DiagnosticUnderlineHint", { undercurl = true, sp = C.teal })

  --  -- Mason, aerial, trouble
  --  H("NormalFloat", { bg = C.light_grey })
  --  H("FloatBorder", { fg = C.cyan, bg = C.light_grey })
  --  H("MasonNormal", { link = "NormalFloat" })
  --  H("TroubleNormal", { link = "NormalFloat" })
  --  H("AerialNormal", { link = "Normal" })

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

  --  -- nvim-cmp
  --  H("CmpItemAbbr", { fg = C.dark_grey })
  --  H("CmpItemAbbrMatch", { fg = C.blue, bold = true })
  --  H("CmpItemKind", { fg = C.purple })
  --  H("CmpItemMenu", { fg = C.medium_grey })

  --  -- git-blame
  --  H("GitBlame", { fg = C.medium_grey, italic = true })
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
