local snacks = require('snacks')
local backdrop = 70

snacks.setup({
  input = {
    enabled = true,
    icon = '> ',
    win = {
      backdrop = backdrop,
      width = 80,
      row = 10,
      keys = {
        i_esc = { '<esc>', { 'cmp_close', 'cancel' }, mode = 'i', expr = true },
      },
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
      select = {
        win = {
          input = {
            keys = {
              ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
              ['<CR>'] = { 'confirm', mode = { 'n', 'i' } },
            },
          },
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
          max_width = 100,
        },
      },
    },
    prompt = '> ',
    win = {
      input = {
        keys = {
          ['<Esc>'] = { 'close', mode = { 'i', 'n' } },

          ['i'] = 'focus_input',

          ['<c-g>'] = { 'toggle_live', mode = { 'i', 'n' } },

          ['<c-j>'] = { 'list_down', mode = { 'i', 'n' } },
          ['<c-k>'] = { 'list_up', mode = { 'i', 'n' } },
          ['<c-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
          ['<c-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },

          ['<CR>'] = { 'focus_list', mode = { 'n', 'i' } },
          ['<c-s>'] = { 'edit_split', mode = { 'i', 'n' } },
          ['<c-v>'] = { 'edit_vsplit', mode = { 'i', 'n' } },
          ['<c-o>'] = { 'qflist', mode = { 'i', 'n' } },

          ['?'] = 'toggle_help_list',

          ['q'] = false,
          ['/'] = false,
          ['<C-Down>'] = false,
          ['<C-Up>'] = false,
          ['<C-c>'] = false,
          ['<C-w>'] = false,
          ['<Down>'] = false,
          ['<S-CR>'] = false,
          ['<S-Tab>'] = false,
          ['<Tab>'] = false,
          ['<Up>'] = false,
          ['<a-d>'] = false,
          ['<a-f>'] = false,
          ['<a-h>'] = false,
          ['<a-i>'] = false,
          ['<a-r>'] = false,
          ['<a-m>'] = false,
          ['<a-p>'] = false,
          ['<a-w>'] = false,
          ['<c-a>'] = false,
          ['<c-b>'] = false,
          ['<c-i>'] = false,
          ['<c-f>'] = false,
          ['<c-n>'] = false,
          ['<c-p>'] = false,
          ['<c-q>'] = false,
          ['<c-t>'] = false,
          ['<c-r>#'] = false,
          ['<c-r>%'] = false,
          ['<c-r><c-a>'] = false,
          ['<c-r><c-f>'] = false,
          ['<c-r><c-l>'] = false,
          ['<c-r><c-p>'] = false,
          ['<c-r><c-w>'] = false,
          ['<c-w>H'] = false,
          ['<c-w>J'] = false,
          ['<c-w>K'] = false,
          ['<c-w>L'] = false,
          ['G'] = false,
          ['gg'] = false,
          ['j'] = false,
          ['k'] = false,
        },
      },
      list = {
        keys = {
          ['<Esc>'] = 'close',

          ['i'] = 'focus_input',
          ['<Tab>'] = 'focus_preview',

          ['<CR>'] = 'confirm',
          ['s'] = 'edit_split',
          ['v'] = 'edit_vsplit',
          ['o'] = 'qflist',

          ['<c-j>'] = 'list_down',
          ['<c-k>'] = 'list_up',
          ['<c-u>'] = 'preview_scroll_up',
          ['<c-d>'] = 'preview_scroll_down',

          ['tf'] = 'toggle_follow',
          ['th'] = 'toggle_hidden',
          ['ti'] = 'toggle_ignored',

          ['?'] = 'toggle_help_list',

          ['q'] = false,
          ['/'] = false,
          ['<2-LeftMouse>'] = false,
          ['<Down>'] = false,
          ['<S-CR>'] = false,
          ['<S-Tab>'] = false,
          ['<Up>'] = false,
          ['<a-d>'] = false,
          ['<a-f>'] = false,
          ['<a-h>'] = false,
          ['<a-i>'] = false,
          ['<a-m>'] = false,
          ['<a-p>'] = false,
          ['<a-w>'] = false,
          ['<c-a>'] = false,
          ['<c-b>'] = false,
          ['<c-f>'] = false,
          ['<c-n>'] = false,
          ['<c-p>'] = false,
          ['<c-q>'] = false,
          ['<c-g>'] = false,
          ['<c-s>'] = false,
          ['<c-t>'] = false,
          ['<c-v>'] = false,
          ['<c-w>H'] = false,
          ['<c-w>J'] = false,
          ['<c-w>K'] = false,
          ['<c-w>L'] = false,
        },
      },
      preview = {
        keys = {
          ['<Esc>'] = 'close',

          ['i'] = 'focus_input',
          ['<Tab>'] = 'focus_list',

          ['<CR>'] = 'confirm',
          ['s'] = 'edit_split',
          ['v'] = 'edit_vsplit',
          ['o'] = 'qflist',

          ['q'] = false,
        },
      },
    },
  },
})
