local parsers_to_install = {
  "json",
  "javascript",
  "typescript",
  "pug",
  "tsx",
  "yaml",
  "html",
  "css",
  "prisma",
  "markdown",
  "markdown_inline",
  "svelte",
  "graphql",
  "bash",
  "lua",
  "vim",
  "dockerfile",
  "gitignore",
  "query",
  "vimdoc",
  "c",
  "cpp",
  "rust",
  "go",
  "python",
  "vue",
}

local retries = 0

-- ждет, пока Mason установит tree-sitter, и только потом ставит парсеры
local function ensure_treesitter_and_install()
  -- проверка, появился ли исполняемый файл tree-sitter в PATH (Mason добавляет его туда)
  if vim.fn.executable("tree-sitter") == 1 then
    require("nvim-treesitter").install(parsers_to_install)
  elseif retries < 30 then
    -- если еще не установился, ждем 2 секунды и проверяем снова (максимум 1 минута)
    retries = retries + 1
    vim.defer_fn(ensure_treesitter_and_install, 2000)
  else
    vim.notify(
      "Ошибка: tree-sitter не установлен через Mason после 60 секунд ожидания",
      vim.log.levels.WARN
    )
  end
end

-- запуск проверку при старте
ensure_treesitter_and_install()

-- включение подсветки синтаксиса через встроенный функционал Neovim
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
  callback = function()
    -- pcall безопасно игнорирует файлы, для которых пока нет парсера
    pcall(vim.treesitter.start)
  end,
})
