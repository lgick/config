-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local nvimtree = require('nvim-tree')

-- Правила сортировки в дереве:
-- 1. _папки (по алфавиту)
-- 2. _файлы (по алфавиту)
-- 3. Обычные папки (по алфавиту)
-- 4. Обычные файлы (от новых к старым по дате изменения)
local function custom_nvim_tree_sorter(nodes)
  local uv = vim.uv or vim.loop

  -- Вспомогательное алфавитное сравнение (DRY)
  local function compare_names(a, b)
    local a_name = (a.name or ''):lower()
    local b_name = (b.name or ''):lower()
    if a_name ~= b_name then
      return a_name < b_name
    end
    return (a.name or '') < (b.name or '')
  end

  local function starts_with_underscore(node)
    return (node.name or ''):sub(1, 1) == '_'
  end

  -- Безопасное извлечение mtime
  local function get_mtime(node)
    local stat = node.fs_stat
    if not stat and node.absolute_path then
      stat = uv.fs_stat(node.absolute_path)
    end

    local mtime = stat and stat.mtime
    if type(mtime) == 'table' then
      return mtime.sec or 0, mtime.nsec or 0
    elseif type(mtime) == 'number' then
      return mtime, 0
    end
    return 0, 0
  end

  -- Оптимизация: кэшируем mtime ТОЛЬКО для обычных файлов,
  -- папки и элементы с "_" stat'ить не нужно.
  local mtime_cache = {}
  for _, node in ipairs(nodes) do
    if node.type ~= 'directory' and not starts_with_underscore(node) then
      local sec, nsec = get_mtime(node)
      mtime_cache[node] = { sec = sec, nsec = nsec }
    end
  end

  table.sort(nodes, function(a, b)
    local a_und = starts_with_underscore(a)
    local b_und = starts_with_underscore(b)

    -- 0. Элементы с "_" всегда наверху
    if a_und and not b_und then
      return true
    elseif not a_und and b_und then
      return false
    elseif a_und and b_und then
      -- Папки с "_" выше файлов с "_"
      if a.type == 'directory' and b.type ~= 'directory' then
        return true
      elseif a.type ~= 'directory' and b.type == 'directory' then
        return false
      end
      -- Внутри своих групп — строго по алфавиту
      return compare_names(a, b)
    end

    -- 1. Обычные папки всегда выше обычных файлов
    if a.type == 'directory' and b.type ~= 'directory' then
      return true
    elseif a.type ~= 'directory' and b.type == 'directory' then
      return false
    end

    -- 2. Обычные папки сортируются по алфавиту
    if a.type == 'directory' and b.type == 'directory' then
      return compare_names(a, b)
    end

    -- 3. Обычные файлы сортируются по mtime (сначала свежие)
    local a_m = mtime_cache[a]
    local b_m = mtime_cache[b]

    if a_m.sec ~= b_m.sec then
      return a_m.sec > b_m.sec
    end

    if a_m.nsec ~= b_m.nsec then
      return a_m.nsec > b_m.nsec
    end

    -- 4. Если mtime совпал — по алфавиту
    return compare_names(a, b)
  end)
end

local function custom_attach(bufnr)
  local api = require('nvim-tree.api')
  local keymap = vim.keymap

  local function opts(desc)
    return {
      desc = 'nvim-tree: ' .. desc,
      buffer = bufnr,
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  -- Принимает действие открытия файла (action) и выполняет проверку
  -- на ширину окна. Если ширина окна меньше 85 символов,
  -- nvim-tree закрывается
  local function open_with_window_check(action)
    return function()
      local node = api.tree.get_node_under_cursor()

      if not node or node.type ~= 'file' then
        return
      end

      -- Текущая ширина окна nvim-tree
      local tree_win = vim.api.nvim_get_current_win()
      local tree_width = vim.api.nvim_win_get_width(tree_win)

      -- Общая ширина терминала
      local total_width = vim.o.columns

      -- Если ширина nvim-tree больше 40 символов
      -- (когда nvim-tree открыт во весь экран),
      -- то максимальное значение - 40 символов
      local width_to_subtract = tree_width
      if width_to_subtract > 40 then
        width_to_subtract = 40
      end

      -- Остаток места
      local content_width = total_width - width_to_subtract

      -- Выполнение основного действия (открытие файла)
      action(node)

      -- Проверка условия для закрытия
      if content_width < 85 then
        api.tree.close()
      end
    end
  end

  -- открывает/закрывает директорию
  local function toggle_directory()
    local node = api.tree.get_node_under_cursor()

    if node and node.type == 'directory' then
      api.node.open.edit(node)
    end
  end

  -- custom mappings
  -- Действия открытия файлов с проверкой и возможным закрытием плагина
  keymap.set('n', '<CR>', open_with_window_check(api.node.open.edit), opts('Open'))
  keymap.set('n', 's', open_with_window_check(api.node.open.horizontal), opts('Open Split'))
  keymap.set('n', 'v', open_with_window_check(api.node.open.vertical), opts('Open VSplit'))
  keymap.set('n', 't', open_with_window_check(api.node.open.tab), opts('Open Tab'))

  keymap.set('n', 'o', toggle_directory, opts('Toggle Directory'))
  keymap.set('n', 'O', api.node.run.system, opts('Run System'))
  keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
  keymap.set('n', 'C', api.tree.change_root_to_node, opts('Change Root'))
  keymap.set('n', 'I', api.filter.custom.toggle, opts('Toggle Custom Filter'))
  keymap.set('n', 'X', api.tree.collapse_all, opts('Collapse All'))
  keymap.set('n', 'E', api.tree.expand_all, opts('Expand All'))
  keymap.set('n', 'q', api.tree.close, opts('Close'))
  keymap.set('n', 'R', api.tree.reload, opts('Refresh'))

  keymap.set('n', 'a', api.fs.create, opts('Create File'))
  keymap.set('n', 'c', api.fs.copy.node, opts('Copy'))
  keymap.set('n', 'x', api.fs.cut, opts('Cut'))
  keymap.set('n', 'p', api.fs.paste, opts('Paste'))
  keymap.set('n', 'd', api.fs.remove, opts('Delete'))
  keymap.set('n', 'r', api.fs.rename, opts('Rename'))
  keymap.set('n', 'u', api.fs.rename_full, opts('Rename Full Path'))
end

nvimtree.setup({
  sort = {
    sorter = custom_nvim_tree_sorter,
  },

  update_focused_file = {
    enable = true,
  },
  on_attach = custom_attach,
  hijack_cursor = true,

  view = {
    preserve_window_proportions = true, -- Запрещает дереву менять пропорции окон при фокусе
    relativenumber = false,
    width = {
      min = 30, -- Минимальная ширина окна
      max = 40, -- Максимальная ширина окна
    },
    side = 'left', -- Позиция окна (left/right)
  },

  renderer = {
    highlight_git = 'name',
    highlight_modified = 'none',
    highlight_diagnostics = 'none',
    indent_markers = {
      enable = true, -- Направляющие линии
    },
    icons = {
      diagnostics_placement = 'before',
      modified_placement = 'after',
      web_devicons = {
        file = {
          enable = true,
          color = false,
        },
      },
      show = {
        folder_arrow = false,
        file = true,
        git = false,
        folder = true,
        modified = true,
        diagnostics = true,
      },
      glyphs = {
        default = '',
        modified = '󰙏',
      },
    },
  },

  -- disable window_picker for
  -- explorer to work well with
  -- window splits
  actions = {
    open_file = {
      window_picker = {
        enable = false,
      },
      quit_on_open = false,
    },
  },

  filters = {
    custom = {
      '^%.',
      '.gitignore',
      'package-lock.json',
      'node_modules',
      '.certs',
      '^.git$',
      '.DS_Store',
      '*.pyc',
      '*.o',
      '*.obj',
      '*.svn',
      '*.swp',
      '*.class',
      '*.hg',
      '*.tmp',
      '*.zip',
    },
  },

  git = {
    enable = true, -- Включить/выключить интеграцию с git
    ignore = false, -- Скрывать файлы, указанные в .gitignore
    show_on_dirs = true, -- Показывать иконки статуса git на родительских папках
    show_on_open_dirs = false, -- Показывать иконки статуса, даже если папка открыта
    timeout = 400, -- Тайм-аут (в мс) для обновления статусов git
  },

  modified = {
    enable = true,
    show_on_dirs = true,
    show_on_open_dirs = false,
  },

  diagnostics = {
    enable = true,
    show_on_dirs = true,
    show_on_open_dirs = false,
    debounce_delay = 50, -- Задержка обновления в мс
    severity = {
      min = vim.diagnostic.severity.HINT, -- Минимальный уровень для отображения
      max = vim.diagnostic.severity.ERROR, -- Максимальный уровень
    },
    icons = {
      hint = '',
      info = '',
      warning = '',
      error = '',
    },
  },
})
