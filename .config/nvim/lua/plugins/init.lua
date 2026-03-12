vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },

  { src = "https://github.com/Saghen/blink.cmp" },
  { src = "https://github.com/L3MON4D3/LuaSnip" },
  { src = "https://github.com/rafamadriz/friendly-snippets" },
  { src = "https://github.com/fang2hou/blink-copilot" },
  { src = "https://github.com/folke/lazydev.nvim" },

  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
  },
  { src = "https://github.com/stevearc/aerial.nvim" },
  { src = "https://github.com/FabijanZulj/blame.nvim" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim", branch = "main" },

  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/windwp/nvim-autopairs" },
  { src = "https://github.com/windwp/nvim-ts-autotag" },

  { src = "https://github.com/folke/snacks.nvim" },
  { src = "https://github.com/folke/trouble.nvim" },
})

require("plugins.lsp")
require("plugins.cmp")
require("plugins.nvim-tree")
require("plugins.treesitter")
require("plugins.aerial") -- TODO можно заменить на snacks?
require("plugins.blame")
require("plugins.indent-blankline")
require("plugins.formatting")
require("plugins.snacks")
