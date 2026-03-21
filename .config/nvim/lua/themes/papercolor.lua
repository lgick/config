local C = {
  -- Grayscale (Оттенки серого)
  white = "#eeeeee",
  light_grey = "#d0d0d0",
  medium_grey = "#bcbcbc",
  dark_grey = "#878787",
  black = "#444444",

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
  -- Настройка групп подсветки для СВЕТЛОЙ темы
  local highlights = {
    -- ==========================================
    -- 1. EDITOR INTERFACE (Базовый интерфейс)
    -- ==========================================
    Normal = { fg = C.black, bg = C.white },
    NormalNC = { fg = C.black, bg = C.white },
    NormalFloat = { fg = C.black, bg = C.off_white },
    FloatBorder = { fg = C.dark_grey, bg = C.off_white },
    FloatTitle = { fg = C.black, bold = true },
    Title = { fg = C.black, bold = true },

    ColorColumn = { bg = C.off_white },
    CursorColumn = { bg = C.off_white },
    CursorLine = { bg = C.off_white },

    Cursor = { fg = C.white, bg = C.black },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    TermCursor = { fg = C.white, bg = C.green },

    Directory = { fg = C.blue, bold = true },
    EndOfBuffer = { fg = C.concrete },
    NonText = { fg = C.dark_grey },
    Whitespace = { fg = C.concrete },
    SpecialKey = { fg = C.pink },

    LineNr = { fg = C.dark_grey },
    LineNrAbove = { fg = C.dark_grey },
    LineNrBelow = { fg = C.dark_grey },
    CursorLineNr = { fg = C.blue, bold = true },

    SignColumn = { bg = C.white },
    FoldColumn = { fg = C.dark_grey, bg = C.white },
    Folded = { fg = C.teal, bg = C.off_white },

    WinSeparator = { fg = C.blue },
    VertSplit = { link = "WinSeparator" },

    MatchParen = { bg = C.concrete, bold = true },

    -- Search & Selection (Используем светлые фоны из палитры)
    Search = { fg = C.black, bg = C.yellow },
    CurSearch = { fg = C.white, bg = C.orange, bold = true },
    IncSearch = { fg = C.black, bg = C.light_orange },
    Substitute = { fg = C.white, bg = C.red },
    Visual = { bg = C.sky },
    VisualNOS = { link = "Visual" },

    -- Messages
    ErrorMsg = { fg = C.white, bg = C.red },
    WarningMsg = { fg = C.orange, bold = true },
    MoreMsg = { fg = C.emerald, bold = true },
    ModeMsg = { fg = C.black, bold = true },
    Question = { fg = C.cyan, bold = true },
    OkMsg = { fg = C.emerald },

    -- Popup Menu
    Pmenu = { fg = C.black, bg = C.off_white },
    PmenuSel = { fg = C.white, bg = C.blue },
    PmenuSbar = { bg = C.medium_grey },
    PmenuThumb = { bg = C.dark_grey },

    -- Tabs & StatusLine
    StatusLine = { fg = C.black, bg = C.medium_grey },
    StatusLineNC = { fg = C.dark_grey, bg = C.off_white },
    TabLine = { fg = C.dark_grey, bg = C.off_white },
    TabLineFill = { bg = C.off_white },
    TabLineSel = { fg = C.white, bg = C.blue, bold = true },

    -- Spell
    SpellBad = { undercurl = true, sp = C.red },
    SpellCap = { undercurl = true, sp = C.blue },
    SpellLocal = { undercurl = true, sp = C.teal },
    SpellRare = { undercurl = true, sp = C.purple },

    -- Diffs (Тёмный текст на пастельных фонах)
    DiffAdd = { fg = C.black, bg = C.light_green },
    DiffChange = { fg = C.black, bg = C.light_yellow },
    DiffDelete = { fg = C.dark_red, bg = C.light_pink },
    DiffText = { fg = C.black, bg = C.light_orange, bold = true },

    -- ==========================================
    -- 2. STANDARD SYNTAX (Стандартный синтаксис)
    -- ==========================================
    Comment = { fg = C.dark_grey, italic = true },

    Constant = { fg = C.orange },
    String = { fg = C.green },
    Character = { fg = C.emerald },
    Number = { fg = C.rust },
    Boolean = { fg = C.dark_red, bold = true },
    Float = { fg = C.rust },

    Identifier = { fg = C.black },
    Function = { fg = C.blue },

    Statement = { fg = C.purple },
    Conditional = { fg = C.purple },
    Repeat = { fg = C.purple },
    Label = { fg = C.orange },
    Operator = { fg = C.cyan },
    Keyword = { fg = C.pink },
    Exception = { fg = C.red },

    PreProc = { fg = C.teal },
    Include = { fg = C.teal },
    Define = { fg = C.teal },
    Macro = { fg = C.teal },
    PreCondit = { fg = C.teal },

    Type = { fg = C.blue },
    StorageClass = { fg = C.olive },
    Structure = { fg = C.olive },
    Typedef = { fg = C.olive },

    Special = { fg = C.pink },
    SpecialChar = { fg = C.pink },
    Tag = { fg = C.cyan },
    Delimiter = { fg = C.light_grey },
    SpecialComment = { fg = C.black, bold = true },
    Debug = { fg = C.red },

    Underlined = { underline = true, fg = C.blue },
    Ignore = { fg = C.white },
    Error = { fg = C.red, bold = true },
    Todo = { fg = C.black, bg = C.yellow, bold = true },

    -- ==========================================
    -- 3. DIAGNOSTICS (Диагностика)
    -- ==========================================
    DiagnosticError = { fg = C.red },
    DiagnosticWarn = { fg = C.orange },
    DiagnosticInfo = { fg = C.blue },
    DiagnosticHint = { fg = C.dark_grey },
    DiagnosticOk = { fg = C.emerald },

    DiagnosticUnderlineError = { undercurl = true, sp = C.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = C.orange },
    DiagnosticUnderlineInfo = { undercurl = true, sp = C.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = C.dark_grey },
    DiagnosticUnderlineOk = { undercurl = true, sp = C.emerald },

    DiagnosticVirtualTextError = { fg = C.red, bg = C.light_pink },
    DiagnosticVirtualTextWarn = { fg = C.orange, bg = C.light_yellow },
    DiagnosticVirtualTextInfo = { fg = C.blue, bg = C.sky },
    DiagnosticVirtualTextHint = { fg = C.dark_grey, bg = C.off_white },
    DiagnosticVirtualTextOk = { fg = C.emerald, bg = C.light_green },

    DiagnosticDeprecated = { strikethrough = true, fg = C.dark_grey },
    DiagnosticUnnecessary = { fg = C.dark_grey, undercurl = true },

    -- ==========================================
    -- 4. TREESITTER (Деревья синтаксиса)
    -- ==========================================
    ["@variable"] = { fg = C.black },
    ["@variable.builtin"] = { fg = C.dark_red, italic = true },
    ["@variable.parameter"] = { fg = C.teal },
    ["@variable.member"] = { fg = C.cyan },
    ["@constant.builtin"] = { fg = C.orange, bold = true },
    ["@constant.macro"] = { fg = C.orange },

    ["@module"] = { fg = C.cyan },
    ["@module.builtin"] = { fg = C.cyan, italic = true },
    ["@label"] = { fg = C.orange },

    ["@string.documentation"] = { fg = C.dark_grey },
    ["@string.regexp"] = { fg = C.pink },
    ["@string.escape"] = { fg = C.emerald },
    ["@string.special.url"] = { fg = C.blue, underline = true },

    ["@type.builtin"] = { fg = C.blue, italic = true },
    ["@type.definition"] = { fg = C.blue, bold = true },

    ["@attribute"] = { fg = C.pink },
    ["@property"] = { fg = C.teal },

    ["@function.builtin"] = { fg = C.blue, italic = true },
    ["@function.macro"] = { fg = C.teal },
    ["@function.method"] = { fg = C.blue },
    ["@constructor"] = { fg = C.green, bold = true },

    ["@keyword"] = { fg = C.dark_red, italic = true },
    ["@keyword.coroutine"] = { fg = C.purple, bold = true },
    ["@keyword.operator"] = { fg = C.cyan },
    ["@keyword.import"] = { fg = C.pink },
    ["@keyword.return"] = { fg = C.dark_red, italic = true },
    ["@keyword.exception"] = { fg = C.red, bold = true },
    ["@keyword.directive"] = { fg = C.teal },

    ["@punctuation.delimiter"] = { fg = C.dark_grey },
    ["@punctuation.bracket"] = { fg = C.dark_grey },
    ["@punctuation.special"] = { fg = C.pink },

    ["@comment.error"] = { fg = C.white, bg = C.red, bold = true },
    ["@comment.warning"] = { fg = C.white, bg = C.orange, bold = true },
    ["@comment.todo"] = { fg = C.black, bg = C.yellow, bold = true },
    ["@comment.note"] = { fg = C.black, bg = C.sky, bold = true },
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.heading"] = { fg = C.blue, bold = true },
    ["@markup.link.url"] = { fg = C.blue, underline = true },
    ["@markup.raw"] = { fg = C.green, bg = C.off_white },

    ["@diff.plus"] = { fg = C.green },
    ["@diff.minus"] = { fg = C.red },
    ["@diff.delta"] = { fg = C.orange },

    ["@tag"] = { fg = C.cyan },
    ["@tag.attribute"] = { fg = C.teal },
    ["@tag.delimiter"] = { fg = C.dark_grey },
  }

  -- Применение цветов
  for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
  end

  -- Отключение lsp
  for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do
    vim.api.nvim_set_hl(0, group, {})
  end
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

  vim.o.background = "light"
  vim.opt.termguicolors = true
  vim.g.colors_name = "PaperColor"

  -- рендерер хайлайтов
  set_highlights()
end

return C
