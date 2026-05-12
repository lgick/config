local snacks = require('snacks')
local backdrop = 70
local window_nav = {
  function(picker)
    vim.api.nvim_echo(
      { { ' Ожидание h/j/k/l (Esc для отмены) ', 'WarningMsg' } },
      false,
      {}
    )

    local ok, char = pcall(vim.fn.getcharstr)

    vim.api.nvim_echo({ { '', 'Normal' } }, false, {})

    if not ok then
      return
    end

    local key = vim.fn.keytrans(char):lower()

    if key == '<esc>' then
      return
    end

    vim.schedule(function()
      local pickers = require('snacks').picker.get() -- Список всех открытых пикеров
      local current_picker = pickers[#pickers] -- Текущий активный пикер

      if not current_picker then
        return
      end

      if picker.opts.bo.filetype == 'snacks_picker_input' then
        current_picker:action('focus_list')
      else
        if key == 'h' or key == '<c-h>' then
          current_picker:action('focus_list')
        elseif key == 'l' or key == '<c-l>' then
          current_picker:action('focus_preview')
        elseif key == 'k' or key == '<c-k>' then
          current_picker:action('focus_list')
        elseif key == 'j' or key == '<c-j>' then
          current_picker:action('focus_preview')
        end
      end
    end)
  end,
  mode = { 'n', 'i' },
  desc = 'Snacks Window Nav',
}

local unique_files = true

local function toggle_unique_files()
  unique_files = not unique_files

  local pickers = require('snacks').picker.get() -- Список всех открытых пикеров
  local current_picker = pickers[#pickers] -- Текущий активный пикер

  current_picker.opts.transform = unique_files and 'unique_file' or nil
  current_picker:find()

  vim.notify(unique_files and 'Unique files: ON' or 'Unique files: OFF')
end

local toggle_preview_and_focus = function()
  local pickers = require('snacks').picker.get() -- Список всех открытых пикеров
  local current_picker = pickers[#pickers] -- Текущий активный пикер

  local is_hidden = vim.tbl_contains(current_picker.layout.opts.hidden, 'preview')

  current_picker:action('toggle_preview')

  vim.schedule(function()
    -- Если preview был скрыт (теперь открыт)
    if is_hidden then
      current_picker:action('focus_preview')
    else
      current_picker:action('focus_list')
    end
  end)
end

local picker_files_keys = {
  ['q'] = 'close',

  ['<Esc>'] = 'focus_input',
  ['i'] = 'focus_input',

  ['<C-w>'] = window_nav, -- навигация по <C-w>
  ['u'] = toggle_unique_files, -- только уникальные файлы в list
  ['p'] = toggle_preview_and_focus, -- отображение preview

  ['s'] = 'edit_split',
  ['v'] = 'edit_vsplit',
  ['<CR>'] = 'confirm',

  ['o'] = 'qflist',

  ['tf'] = 'toggle_follow', -- символические ссылки
  ['th'] = 'toggle_hidden', -- скрытые файлы
  ['ti'] = 'toggle_ignored', -- файлы из .gitignore

  ['<Tab>'] = false,
  ['?'] = false,
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
  ['<C-a>'] = false,
  ['<C-b>'] = false,
  ['<C-f>'] = false,
  ['<C-n>'] = false,
  ['<C-p>'] = false,
  ['<C-q>'] = false,
  ['<C-g>'] = false,
  ['<C-s>'] = false,
  ['<C-t>'] = false,
  ['<C-v>'] = false,
  ['<C-w>h'] = false,
  ['<C-w>j'] = false,
  ['<C-w>k'] = false,
  ['<C-w>l'] = false,
  ['<C-w>H'] = false,
  ['<C-w>J'] = false,
  ['<C-w>K'] = false,
  ['<C-w>L'] = false,
  ['<C-j>'] = false,
  ['<C-k>'] = false,
  ['<C-u>'] = false,
  ['<C-d>'] = false,
}

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
      grep = {
        transform = 'unique_file',
      },
      keymaps = {
        layout = { preset = 'vscode' },
        sort = {
          fields = { 'lhs:asc', 'score:desc', 'idx' },
        },
      },
      select = {
        win = {
          list = {
            keys = {
              ['<Esc>'] = 'close',
              ['<CR>'] = 'confirm',
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
        hidden = { 'input', 'preview' },
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
          ['q'] = 'close',
          ['<Esc>'] = 'cancel',
          ['<c-g>'] = { 'toggle_live', mode = { 'i', 'n' } },
          ['<CR>'] = { 'focus_list', mode = { 'n', 'i' } },
          ['<C-w>'] = window_nav,

          ['?'] = false,
          ['/'] = false,
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
          ['<C-Down>'] = false,
          ['<C-Up>'] = false,
          ['<C-c>'] = false,
          ['<C-a>'] = false,
          ['<C-b>'] = false,
          ['<C-i>'] = false,
          ['<C-f>'] = false,
          ['<C-n>'] = false,
          ['<C-p>'] = false,
          ['<C-q>'] = false,
          ['<C-t>'] = false,
          ['<C-r>#'] = false,
          ['<C-r>%'] = false,
          ['<C-r><c-a>'] = false,
          ['<C-r><c-f>'] = false,
          ['<C-r><c-l>'] = false,
          ['<C-r><c-p>'] = false,
          ['<C-r><c-w>'] = false,
          ['<C-w>h'] = false,
          ['<C-w>j'] = false,
          ['<C-w>k'] = false,
          ['<C-w>l'] = false,
          ['<C-w>H'] = false,
          ['<C-w>J'] = false,
          ['<C-w>K'] = false,
          ['<C-w>L'] = false,
          ['<C-j>'] = false,
          ['<C-k>'] = false,
          ['<C-u>'] = false,
          ['<C-d>'] = false,
          ['<C-s>'] = false,
          ['<C-v>'] = false,
          ['<C-o>'] = false,
          ['i'] = false,
          ['G'] = false,
          ['gg'] = false,
          ['j'] = false,
          ['k'] = false,
        },
      },
      list = { keys = picker_files_keys },
      preview = { keys = picker_files_keys },
    },
  },
})
