vim.pack.add({
  { src = 'https://github.com/neovim/nvim-lspconfig' }, -- движок для подключения языковых серверов lsp к Neovim
  { src = 'https://github.com/mason-org/mason.nvim' }, -- менеджер пакетов (устанавливает бинарники серверов, линтеров, отладчиков)
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' }, -- мост между mason и lspconfig (сопоставляет имена серверов)
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' }, -- автоустановка lsp, линтеров, форматтеров.

  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' }, -- парсер кода (дает подсветку, навигацию и понимание структуры)

  { src = 'https://github.com/nvim-tree/nvim-tree.lua' }, -- сайдбар с файловым деревом
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' }, -- иконки для файлов

  { src = 'https://github.com/Saghen/blink.cmp', version = vim.version.range('1.*') }, -- автодополнение
  { src = 'https://github.com/folke/lazydev.nvim' }, -- умные подсказки для работы с api neovim и lua-плагинов

  { src = 'https://github.com/b0o/SchemaStore.nvim' }, -- каталог для json

  { src = 'https://github.com/stevearc/conform.nvim' }, -- форматирование кода (запускает prettier)

  { src = 'https://github.com/stevearc/aerial.nvim' }, -- навигация по коду в файле

  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' }, -- линии отступов для блоков кода
  { src = 'https://github.com/windwp/nvim-autopairs' }, -- автоматическое закрытие скобок
  { src = 'https://github.com/windwp/nvim-ts-autotag' }, -- автозакрытие и переименование тегов

  { src = 'https://github.com/folke/snacks.nvim' }, -- дашборд, окно picker с поиском, буфферами
  { src = 'https://github.com/folke/trouble.nvim' }, -- окно ошибок и предупреждений

  { src = 'https://www.github.com/lewis6991/gitsigns.nvim' }, -- git stager
  { src = 'https://github.com/sindrets/diffview.nvim' }, -- git diff
})

require('plugins.mason')
require('lazydev').setup({
  library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    { path = 'snacks.nvim', words = { 'Snacks' } },
  },
})
require('plugins.blink-cmp')
require('plugins.nvim-tree')
require('plugins.treesitter')
require('plugins.aerial')
require('plugins.indent-blankline')
require('plugins.conform')
require('nvim-autopairs').setup()
require('nvim-ts-autotag').setup()
require('plugins.snacks')
require('plugins.trouble')
require('plugins.git')
