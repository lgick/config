local C = {
  -- Оттенки серого
  white = "#eeeeee",
  light_grey = "#c7c7c7",
  dark_grey = "#838383",
  black = "#464646",

  -- Основные
  red = "#d70000",
  dark_red = "#af0000",
  orange = "#d75f00",
  pink = "#d70087",
  green = "#008700",
  olive = "#5f8700",
  cyan = "#005f87",
  blue = "#005faf",
  teal = "#0087af",
  purple = "#8700af",

  -- Дополнительные
  off_white = "#e4e4e4",
  ash = "#b2b2b2",
  rust = "#af5f00",
  emerald = "#00af5f",
  sky = "#afd7ff",
  yellow = "#ffff5f",

  light_blue = "#cffaff",
  light_green = "#b9fbc0",
  light_yellow = "#fdffb6",
  light_orange = "#ffd6a5",
  light_red = "#ffd6d6",
}

local function set_highlights()
  local highlights = {

    -- ==========================================
    -- 1. EDITOR INTERFACE (Базовый интерфейс)
    -- ==========================================
    Normal = { fg = C.black, bg = C.white },
    NormalNC = { fg = C.black, bg = C.white },
    NormalFloat = { fg = C.black, bg = C.off_white },
    FloatBorder = { fg = C.purple, bg = C.off_white },
    FloatTitle = { fg = C.black, bg = C.off_white, bold = true },
    Title = { fg = C.black },

    ColorColumn = { bg = C.off_white },
    CursorColumn = { bg = C.off_white },
    CursorLine = { bg = C.off_white },

    Cursor = { fg = C.white, bg = C.cyan },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    TermCursor = { fg = C.white, bg = C.cyan },

    Directory = { fg = C.cyan },
    EndOfBuffer = { link = "NonText" },
    NonText = { fg = C.dark_grey },
    Whitespace = { fg = C.light_grey },
    SpecialKey = { fg = C.light_grey },

    LineNr = { fg = C.dark_grey },
    LineNrAbove = { link = "LineNr" },
    LineNrBelow = { link = "LineNr" },
    CursorLineNr = { fg = C.rust, bg = C.off_white },

    SignColumn = { fg = C.green },
    FoldColumn = { fg = C.teal },
    Folded = { fg = C.teal, bg = C.sky },

    WinSeparator = { fg = C.cyan },
    VertSplit = { link = "WinSeparator" },

    MatchParen = { fg = C.cyan, bg = C.light_grey },

    Search = { fg = C.black, bg = C.yellow },
    CurSearch = { fg = C.yellow, bg = C.black, bold = true },
    IncSearch = { fg = C.yellow, bg = C.black },
    Substitute = { fg = C.white, bg = C.red },
    Visual = { fg = C.white, bg = C.teal },
    VisualNOS = { link = "Visual" },
    SnippetTabstop = { bg = "NONE" },
    SnippetTabstopActive = { bg = "NONE" },

    ErrorMsg = { fg = C.dark_red },
    WarningMsg = { fg = C.pink },
    MoreMsg = { fg = C.olive },
    ModeMsg = { fg = C.olive },
    Question = { fg = C.olive },
    OkMsg = { fg = C.green },

    Pmenu = { fg = C.blue, bg = C.off_white },
    PmenuSel = { fg = C.white, bg = C.cyan },
    PmenuThumb = { bg = C.cyan },
    WildMenu = { fg = C.black, bg = C.yellow, bold = true },

    TabLine = { fg = C.black, bg = C.light_grey },
    TabLineFill = { fg = C.black, bg = C.light_grey },
    TabLineSel = { fg = C.white, bg = C.cyan, bold = true },

    StatusLine = { fg = C.white, bg = C.cyan, bold = true },
    StatusLineNC = { fg = C.black, bg = C.light_grey },

    QuickFixLine = { fg = C.red },

    SpellBad = { undercurl = true, sp = C.dark_red },
    SpellCap = { undercurl = true, sp = C.purple },
    SpellLocal = { undercurl = true, sp = C.cyan },
    SpellRare = { undercurl = true, sp = C.orange },

    DiffAdd = { fg = C.green, bg = C.light_green },
    DiffChange = { fg = C.black, bg = C.off_white },
    DiffDelete = { fg = C.dark_red, bg = C.light_red },
    DiffText = { fg = C.teal, bg = "None" },

    -- ==========================================
    -- 2. STANDARD SYNTAX (Стандартный синтаксис)
    -- ==========================================
    Comment = { fg = C.dark_grey, italic = true, bold = false },

    Constant = { fg = C.black },
    String = { fg = C.olive },
    Character = { fg = C.olive },
    Number = { fg = C.orange },
    Boolean = { fg = C.green, bold = true },
    Float = { fg = C.orange },

    Identifier = { fg = C.cyan },
    Function = { fg = C.black },

    Added = { fg = C.olive },
    Removed = { fg = C.dark_red },

    Statement = { fg = C.pink },
    Conditional = { fg = C.purple, bold = true },
    Repeat = { fg = C.purple, bold = true },
    Label = { fg = C.blue },
    Operator = { fg = C.teal },
    Keyword = { fg = C.pink },
    Exception = { fg = C.red },

    PreProc = { fg = C.blue },
    Include = { fg = C.red },
    Define = { fg = C.blue },
    Macro = { fg = C.blue },
    PreCondit = { fg = C.teal },

    Type = { fg = C.cyan, bold = true },
    StorageClass = { fg = C.blue, bold = true },
    Structure = { fg = C.blue, bold = true },
    Typedef = { fg = C.black, bold = true },

    Special = { fg = C.black },
    SpecialChar = { fg = C.black },
    Tag = { fg = C.green },
    Delimiter = { fg = C.black },
    SpecialComment = { fg = C.black, bold = true },
    Debug = { fg = C.orange },

    Underlined = { fg = C.blue, underline = true },
    Ignore = { fg = C.white },
    Error = { fg = C.dark_red },
    Todo = { fg = C.emerald, bold = true },

    -- ==========================================
    -- 3. DIAGNOSTICS (Диагностика)
    -- ==========================================
    DiagnosticOk = { fg = C.olive },
    DiagnosticHint = { fg = C.teal },
    DiagnosticInfo = { fg = C.teal },
    DiagnosticWarn = { fg = C.orange },
    DiagnosticError = { fg = C.dark_red },

    DiagnosticUnderlineOk = { undercurl = true, sp = C.olive },
    DiagnosticUnderlineHint = { undercurl = true, sp = C.teal },
    DiagnosticUnderlineInfo = { undercurl = true, sp = C.teal },
    DiagnosticUnderlineWarn = { undercurl = true, sp = C.orange },
    DiagnosticUnderlineError = { undercurl = true, sp = C.dark_red },

    DiagnosticVirtualTextOk = { fg = C.olive },
    DiagnosticVirtualTextHint = { fg = C.teal },
    DiagnosticVirtualTextInfo = { fg = C.teal },
    DiagnosticVirtualTextWarn = { fg = C.orange },
    DiagnosticVirtualTextError = { fg = C.dark_red },

    DiagnosticDeprecated = { strikethrough = true, fg = C.black },
    DiagnosticUnnecessary = { fg = "None", undercurl = true },

    -- ==========================================
    -- 4. TREESITTER (Деревья синтаксиса)
    -- ==========================================
    ["@variable"] = { fg = C.black },
    ["@variable.builtin"] = { fg = C.dark_red },
    ["@variable.parameter"] = { fg = C.black },
    ["@variable.member"] = { fg = C.cyan },
    ["@constant.builtin"] = { fg = C.green, bold = true },
    ["@constant.macro"] = { fg = C.black },
    ["@constant.javascript"] = { fg = C.black, nocombine = true },

    ["@module"] = { fg = C.black },
    ["@module.builtin"] = { fg = C.blue },

    ["@label"] = { fg = C.blue },

    ["@string.documentation"] = { fg = C.black },
    ["@string.regexp"] = { fg = C.olive },
    ["@string.escape"] = { fg = C.olive, bold = true },
    ["@string.special.url"] = { fg = C.blue, underline = true },

    ["@type.builtin"] = { fg = C.cyan },
    ["@type.definition"] = { fg = C.pink, bold = true },
    ["@type.javascript"] = { fg = C.cyan, bold = true },
    ["@type.builtin.javascript"] = { link = "@type.javascript" },
    ["@type.jsdoc"] = { link = "Comment" },

    ["@attribute"] = { fg = C.teal },
    ["@property"] = { fg = C.blue },

    ["@function"] = { fg = C.cyan, bold = true },
    ["@function.builtin"] = { fg = C.cyan },
    ["@function.macro"] = { fg = C.blue },
    ["@function.method"] = { fg = C.cyan, bold = true },
    ["@function.method.call.javascript"] = { fg = C.cyan, bold = false },
    ["@constructor"] = { fg = C.green, bold = true },

    ["@keyword"] = { fg = C.blue },
    ["@keyword.type"] = { fg = C.cyan },
    ["@keyword.conditional"] = { fg = C.purple, bold = true },
    ["@keyword.repeat"] = { fg = C.purple, bold = true },
    ["@keyword.coroutine"] = { fg = C.purple },
    ["@keyword.operator"] = { fg = C.teal, bold = true },
    ["@keyword.import"] = { fg = C.pink },
    ["@keyword.return"] = { fg = C.pink },
    ["@keyword.exception"] = { fg = C.red },
    ["@keyword.directive"] = { fg = C.blue },

    ["@punctuation.delimiter"] = { fg = C.black },
    ["@punctuation.bracket"] = { fg = C.blue },
    ["@punctuation.bracket.jsdoc"] = { link = "Comment" },
    ["@punctuation.special"] = { fg = C.black },

    ["@comment.error"] = { fg = C.white, bg = C.dark_red, bold = true },
    ["@comment.warning"] = { fg = C.white, bg = C.orange, bold = true },
    ["@comment.todo"] = { fg = C.emerald, bg = C.white, bold = true },
    ["@comment.note"] = { fg = C.black, bg = C.sky, bold = true },

    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.heading"] = { fg = C.pink, bold = true },
    ["@markup.link.url"] = { fg = C.blue, underline = true },
    ["@markup.raw"] = { fg = C.olive },

    ["@diff.plus"] = { fg = C.green },
    ["@diff.minus"] = { fg = C.red },
    ["@diff.delta"] = { fg = C.orange },

    ["@tag"] = { fg = C.black },
    ["@tag.builtin"] = { fg = C.purple },
    ["@tag.attribute"] = { fg = C.pink },
    ["@tag.delimiter"] = { fg = C.black },

    ["@nospell.jsdoc"] = { link = "Comment" },

    -- ==========================================
    -- 5. Snack
    -- ==========================================
    SnacksPickerMatch = { bg = C.yellow, nocombine = true },

    -- ==========================================
    -- 6. BlinkCmp
    -- ==========================================
    BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpDocBorder = { link = "BlinkCmpMenuBorder" },
    BlinkCmpMenu = { link = "NormalFloat" },
    BlinkCmpDoc = { link = "BlinkCmpMenu" },

    -- ==========================================
    -- 7. NvimTree
    -- ==========================================
    NvimTreeGitStagedIcon = { fg = C.olive }, -- Файлы, добавленные в индекс (Staged / Ready to commit)
    NvimTreeGitRenamedIcon = { fg = C.olive }, -- Переименованные файлы
    NvimTreeGitMergeIcon = { fg = C.dark_red }, -- Файлы с конфликтами при слиянии (Merge Conflict)
    NvimTreeGitNewIcon = { fg = C.orange }, -- Новые (неотслеживаемые) файлы (Untracked)
    NvimTreeGitDirtyIcon = { fg = C.orange }, -- Измененные файлы, которые еще не в индексе (Modified / Dirty)
    NvimTreeGitDeletedIcon = { fg = C.orange }, -- Удаленные файлы (визуализация в дереве перед коммитом)
    NvimTreeGitIgnoredIcon = { fg = C.dark_grey }, -- Файлы, которые игнорируются git (из .gitignore)

    NvimTreeModifiedIcon = { fg = C.black, nocombine = true },
    NvimTreeFolderIcon = { link = "Directory", nocombine = true },

    NvimTreeCopiedHL = { bg = C.light_yellow, nocombine = true },
    NvimTreeCutHL = { bg = C.light_orange, nocombine = true },

    NvimTreeIndentMarker = { fg = C.light_grey, nocombine = true },

    -- ==========================================
    -- 8. GitSigns
    -- ==========================================
    GitSignsNr = { bg = C.orange, fg = C.white }, -- Номера строк (Unstaged)
    GitSignsStagedNr = { bg = C.olive, fg = C.white }, -- Номера строк (Staged)
    GitSignsLn = { bg = C.off_white }, -- Фон всей строки (Unstaged)
    GitSignsStagedLn = { link = "GitSignsLn" }, -- Фон всей строки (Staged)
    GitSignsStatusLine = { link = "GitSignsNr" }, -- Стили строки статуса

    -- Номера строк (Unstaged)
    GitSignsAddNr = { link = "GitSignsNr" },
    GitSignsChangeNr = { link = "GitSignsNr" },
    GitSignsDeleteNr = { link = "GitSignsNr" },
    GitSignsChangedeleteNr = { link = "GitSignsNr" },
    GitSignsTopdeleteNr = { link = "GitSignsNr" },
    GitSignsUntrackedNr = { link = "GitSignsNr" },

    -- Номера строк (Staged)
    GitSignsStagedAddNr = { link = "GitSignsStagedNr" },
    GitSignsStagedChangeNr = { link = "GitSignsStagedNr" },
    GitSignsStagedDeleteNr = { link = "GitSignsStagedNr" },
    GitSignsStagedChangedeleteNr = { link = "GitSignsStagedNr" },
    GitSignsStagedTopdeleteNr = { link = "GitSignsStagedNr" },
    GitSignsStagedUntrackedNr = { link = "GitSignsStagedNr" },

    -- Фон всей строки (Unstaged)
    GitSignsAddLn = { link = "GitSignsLn" },
    GitSignsChangeLn = { link = "GitSignsLn" },
    GitSignsChangedeleteLn = { link = "GitSignsLn" },
    GitSignsTopdeleteLn = { link = "GitSignsLn" },
    GitSignsUntrackedLn = { link = "GitSignsLn" },

    -- Фон всей строки (Staged)
    GitSignsStagedAddLn = { link = "GitSignsStagedLn" },
    GitSignsStagedChangeLn = { link = "GitSignsStagedLn" },
    GitSignsStagedChangedeleteLn = { link = "GitSignsStagedLn" },
    GitSignsStagedTopdeleteLn = { link = "GitSignsStagedLn" },
    GitSignsStagedUntrackedLn = { link = "GitSignsStagedLn" },

    -- Измененные слова в буфере
    GitSignsAddLnInline = { fg = "NONE", bg = "NONE", nocombine = true },
    GitSignsDeleteLnInline = { fg = "NONE", bg = "NONE", nocombine = true },
    GitSignsChangeLnInline = { fg = "NONE", bg = "NONE", nocombine = true },

    -- Режим предпросмотра (preview)
    GitSignsAddPreview = { fg = C.olive, bg = "NONE", nocombine = true },
    GitSignsDeletePreview = { fg = C.dark_red, bg = "NONE", nocombine = true },

    -- Измененные слова в режиме предпросмотра (preview)
    --GitSignsAddInline = { nocombine = true },
    GitSignsDeleteInline = { strikethrough = true, nocombine = true },
    GitSignsChangeInline = { fg = C.green, bold = true, nocombine = true },

    -- GitSignsNoEOLPreview = { fg = "NONE", bg = "NONE" },

    -- For word diff in virtual lines (e.g. show_deleted):
    -- GitSignsAddVirtLnInline = { fg = "NONE", bg = "NONE" },
    -- GitSignsChangeVirtLnInline = { fg = "NONE", bg = "NONE" },
    -- GitSignsDeleteVirtLnInline = { fg = "NONE", bg = "NONE" },

    -- Текст значков (Unstaged)
    -- GitSignsAdd = { bg = C.dark_red }, -- Для новых строк
    -- GitSignsChange = { bg = C.dark_red }, -- Для измененных строк
    -- GitSignsDelete = { bg = C.dark_red }, -- Для удаленных строк
    -- GitSignsChangedelete = { bg = C.dark_red }, -- Для изменений с удалением под ними
    -- GitSignsTopdelete = { bg = C.dark_red }, -- Для удалений в самом верху файла
    -- GitSignsUntracked = { bg = C.dark_red }, -- Для не отслеживаемых файлов

    -- Текст значков (Staged)
    -- GitSignsStagedAdd = { bg = C.olive }, -- Для новых строк
    -- GitSignsStagedChange = { bg = C.olive }, -- Для измененных строк
    -- GitSignsStagedDelete = { bg = C.olive }, -- Для удаленных строк
    -- GitSignsStagedChangedelete = { bg = C.olive }, -- Для изменений с удалением под ними
    -- GitSignsStagedTopdelete = { bg = C.olive }, -- Для удалений в самом верху файла
    -- GitSignsStagedUntracked = { bg = C.olive }, -- Для не отслеживаемых файлов
  }

  local nvimTreeColors = {
    "NvimTreeFileIcon",
    "NvimTreeExecFile",
    "NvimTreeOpenedFile",
    "NvimTreeSpecialFile",
    "NvimTreeImageFile",
    "NvimTreeMarkdownFile",
  }

  for _, color in ipairs(nvimTreeColors) do
    vim.api.nvim_set_hl(0, color, { link = "Title" })
  end

  for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
  end
end

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
  vim.g.colors_name = "paperblue"

  set_highlights()
end

-- отключение подсветки lsp
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    -- Отключение семантической подсветки (Semantic Tokens)
    client.server_capabilities.semanticTokensProvider = nil
  end,
})

return C
