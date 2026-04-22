local snacks = require('snacks')

snacks.setup({
  input = { enabled = true },

  picker = {
    enabled = true,
    layout = {
      fullscreen = true,
    },
    win = {
      input = {
        keys = {
          ['<ESC>'] = { 'close', mode = { 'i', 'n' } },
          ['<C-j>'] = { 'list_down', mode = { 'i', 'n' } },
          ['<C-k>'] = { 'list_up', mode = { 'i', 'n' } },
          ['<C-n>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
          ['<C-p>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
          ['<C-d>'] = { 'list_bottom', mode = { 'i', 'n' } },
          ['<C-u>'] = { 'list_top', mode = { 'i', 'n' } },
          ['<C-o>'] = { 'qflist', mode = { 'i', 'n' } },
          ['<C-s>'] = { 'edit_split', mode = { 'i', 'n' } },
          ['<C-i>'] = { 'edit_vsplit', mode = { 'i', 'n' } },
          ['<CR>'] = { 'confirm', mode = { 'n', 'i' } },
        },
      },
    },
  },

  notifier = {
    enabled = true,
    timeout = 5000,
  },
  styles = {
    notification = {
      border = true,
      zindex = 100,
      wo = {
        winblend = 5,
        wrap = true,
        conceallevel = 2,
        colorcolumn = '',
      },
      bo = { filetype = 'snacks_notif' },
    },
  },
})
