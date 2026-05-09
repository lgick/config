local snacks = require('snacks')
local backdrop = 70

snacks.setup({
  input = {
    enabled = true,
    icon = '> ',
    win = {
      backdrop = backdrop,
      width = 100,
      row = 10,
    },
  },

  picker = {
    enabled = true,
    ui_select = true,
    sources = {
      keymaps = {
        layout = { preset = 'vscode' },
        sort = {
          fields = { 'lhs:asc', 'score:desc', 'idx' },
        },
      },
    },
    layouts = {
      default = {
        fullscreen = true,
        layout = {
          backdrop = false,
        },
      },
      vertical = {
        fullscreen = true,
        layout = {
          backdrop = false,
        },
      },
      vscode = {
        fullscreen = true,
        layout = {
          backdrop = false,
        },
      },
      select = {
        layout = {
          backdrop = backdrop,
          max_width = 200,
        },
      },
    },
    prompt = '> ',
    win = {
      input = {
        keys = {
          ['<ESC>'] = { 'close', mode = { 'i', 'n' } },
          ['<C-j>'] = { 'list_down', mode = { 'i', 'n' } },
          ['<C-k>'] = { 'list_up', mode = { 'i', 'n' } },
          ['<C-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
          ['<C-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
          ['<C-o>'] = { 'qflist', mode = { 'i', 'n' } },
          ['<C-s>'] = { 'edit_split', mode = { 'i', 'n' } },
          ['<C-i>'] = { 'edit_vsplit', mode = { 'i', 'n' } },
          ['<CR>'] = { 'confirm', mode = { 'n', 'i' } },
        },
      },
    },
  },
})
