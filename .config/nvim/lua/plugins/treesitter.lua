local parsers_to_install = {
  'html',
  'css',
  'scss',
  'styled',
  'javascript',
  'jsx',
  'jsdoc',
  'json',
  'typescript',
  'vue',
  'pug',
  'markdown',
  'markdown_inline',
  'bash',
  'lua',
  'luadoc',
  'vim',
  'vimdoc',
  'dockerfile',
  'gitignore',
  'nginx',
  'regex',
}

local function install_missing_parsers()
  -- получение списка того, что уже установлено
  local installed = require('nvim-treesitter').get_installed()

  -- список в словарь для быстрого поиска
  local installed_dict = {}
  for _, lang in ipairs(installed) do
    installed_dict[lang] = true
  end

  local missing = {}
  for _, lang in ipairs(parsers_to_install) do
    if not installed_dict[lang] then
      table.insert(missing, lang)
    end
  end

  -- если чего-то не хватает - запуск установки
  if #missing > 0 then
    require('nvim-treesitter').install(missing)
  end
end

-- если tree-sitter установлен
if vim.fn.executable('tree-sitter') == 1 then
  install_missing_parsers()
else
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MasonToolsUpdateCompleted',
    once = true,
    callback = function()
      if vim.fn.executable('tree-sitter') == 1 then
        install_missing_parsers()
      end
    end,
  })
end

-- включение подсветки синтаксиса через API ядра Neovim
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('TreesitterHighlight', { clear = true }),
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
