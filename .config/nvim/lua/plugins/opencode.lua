require('opencode').setup({
  -- Общие настройки
  preferred_picker = nil, -- 'telescope', 'fzf', 'mini.pick', 'snacks', 'select'
  preferred_completion = 'blink', -- 'blink', 'nvim-cmp', 'vim_complete'
  default_global_keymaps = false, -- Если false, отключает все стандартные глобальные горячие клавиши
  default_mode = 'build', -- 'build' или 'plan'
  default_system_prompt = nil, -- Пользовательский системный промпт
  keymap_prefix = '<leader>a', -- Префикс для горячих клавиш
  opencode_executable = 'opencode', -- Имя вашего бинарного файла opencode
  prompt_guard = nil, -- Защита промптов

  -- Настройка горячих клавиш
  keymap = {
    editor = {
      ['<leader>at'] = false, -- Переключить фокус
      ['<leader>aq'] = false, -- Закрыть окно Opencode
      ['<leader>ag'] = false, -- Переключить окно Opencode
      ['<leader>ax'] = false, -- Поменять положение окон
      ['<leader>ao'] = false, -- Открыть окно вывода
      ['<leader>aV'] = false, -- Настроить вариант модели
      ['<leader>az'] = false, -- Переключить зум
      ['<leader>ad'] = false, -- Открыть вид диффов
      ['<leader>a]'] = false, -- Следующий дифф
      ['<leader>a['] = false, -- Предыдущий дифф
      ['<leader>ac'] = false, -- Закрыть вид диффов
      ['<leader>aR'] = false, -- Переименовать сессию
      ['<leader>arr'] = false, -- Восстановить снимок файла
      ['<leader>arR'] = false, -- Восстановить все снимки
      ['<leader>atr'] = false, -- Переключить вывод рассуждений
      ['<leader>att'] = false, -- Переключить вывод инструментов
      ['<leader>atm'] = false, -- Переключить макс. кол-во сообщений

      ['<leader>ai'] = { 'toggle', desc = 'Toggle Opencode window' }, -- Переключить окно Opencode
      ['<leader>aI'] = { 'open_input_new_session', desc = 'Open input (new session)' }, -- Открыть ввод (новая сессия)

      ['<leader>ap'] = { 'configure_provider', desc = 'Configure provider' }, -- Настроить провайдера
      ['<leader>av'] = { 'configure_variant', desc = 'Configure model variant' }, -- Настроить вариант модели
      ['<leader>am'] = { 'switch_mode', desc = 'Switch agent mode' }, -- Сменить режим агента

      ['<leader>ah'] = { 'select_history', desc = 'Select from history' }, -- Выбрать из истории
      ['<leader>aT'] = { 'timeline', desc = 'Session timeline' }, -- Таймлайн сессии

      ['<leader>as'] = { 'select_session', desc = 'Select session' }, -- Выбрать сессию
      ['<leader>arn'] = { 'rename_session', desc = 'Rename session' }, -- Переименовать сессию

      ['<leader>ado'] = { 'diff_open', desc = 'Open diff view' }, -- Открыть вид диффов
      ['<leader>adn'] = { 'diff_next', desc = 'Next diff' }, -- Следующий дифф
      ['<leader>adp'] = { 'diff_prev', desc = 'Previous diff' }, -- Предыдущий дифф
      ['<leader>adc'] = { 'diff_close', desc = 'Close diff view' }, -- Закрыть вид диффов

      ['<leader>ara'] = { 'diff_revert_all_last_prompt', desc = 'Revert all (last prompt)' }, -- Откатить все (последний промпт)
      ['<leader>art'] = { 'diff_revert_this_last_prompt', desc = 'Revert this (last prompt)' }, -- Откатить это (последний промпт)
      ['<leader>arA'] = { 'diff_revert_all', desc = 'Revert all changes' }, -- Откатить все изменения
      ['<leader>arT'] = { 'diff_revert_this', desc = 'Revert this change' }, -- Откатить это изменение

      ['<leader>ars'] = { 'diff_restore_snapshot_file', desc = 'Restore file snapshot' }, -- Восстановить снимок файла
      ['<leader>arS'] = { 'diff_restore_snapshot_all', desc = 'Restore all snapshots' }, -- Восстановить все снимки

      ['<leader>ay'] = {
        'add_visual_selection',
        mode = { 'v' },
        desc = 'Add visual selection to context',
      }, -- Добавить выделение в контекст
      ['<leader>aY'] = {
        'add_visual_selection_inline',
        mode = { 'v' },
        desc = 'Insert visual selection inline into input',
      }, -- Вставить выделение инлайново во ввод

      --['<leader>aS'] = {
      --  'navigate_session_tree',
      --  { 'child', 'picker' },
      --  desc = 'Select child session',
      --}, -- Выбрать дочернюю сессию
      --['<leader>aP'] = { 'navigate_session_tree', { 'parent' }, desc = 'Go to parent session' }, -- Перейти к родительской сессии

      --['<leader>aB'] = {
      --  'navigate_session_tree',
      --  { 'sibling', 'picker' },
      --  desc = 'Select sibling session',
      --}, -- Выбрать соседнюю сессию

      --['<leader>a'] = { 'paste_image', desc = 'Paste image from clipboard' }, -- Вставить изображение из буфера
      ['<leader>a/'] = {
        'quick_chat',
        mode = { 'n', 'x' },
        desc = 'Quick chat with current context',
      }, -- Быстрый чат с текущим контекстом
    },
    input_window = {
      ['<tab>'] = false, -- Переключить панели ввода/вывода
      ['<S-cr>'] = false, -- Отправить промпт
      ['<C-c>'] = false, -- Отменить выполнение запроса
      ['<up>'] = false, -- Предыдущий элемент истории промптов
      ['<down>'] = false, -- Следующий элемент истории промптов
      ['<esc>'] = false, -- Отменить выполнение запроса

      ['<C-wq>'] = { 'close', desc = 'Close Opencode' }, -- Закрыть Opencode
      ['<cr>'] = { 'submit_input_prompt', mode = { 'n', 'i' }, desc = 'Submit prompt' }, -- Отправить промпт
      ['<C-n>'] = {
        'next_prompt_history',
        mode = { 'n', 'i' },
        desc = 'Next prompt history item',
        defer_to_completion = true,
      }, -- Следующий элемент истории промптов
      ['<C-p>'] = {
        'prev_prompt_history',
        mode = { 'n', 'i' },
        desc = 'Previous prompt history item',
        defer_to_completion = true,
      }, -- Предыдущий элемент истории промптов

      ['~'] = { 'mention_file', mode = 'i', desc = 'Mention file in context' }, -- Упомянуть файл в контексте
      ['@'] = { 'mention', mode = 'i', desc = 'Open mention picker' }, -- Открыть выбор упоминаний
      ['/'] = { 'slash_commands', mode = 'i', desc = 'Open slash commands picker' }, -- Открыть выбор слэш-команд
      ['#'] = { 'context_items', mode = 'i', desc = 'Open context items picker' }, -- Открыть выбор элементов контекста
      ['<M-v>'] = { 'paste_image', mode = 'i', desc = 'Paste image from clipboard' }, -- Вставить изображение из буфера
      ['<M-m>'] = { 'switch_mode', desc = 'Switch agent mode' }, -- Сменить режим агента
      ['<M-r>'] = { 'cycle_variant', mode = { 'n', 'i' }, desc = 'Cycle model variants' }, -- Переключение вариантов модели
      ['<M-i>'] = { 'toggle_input', mode = { 'n', 'i' }, desc = 'Toggle input window' }, -- Переключить окно ввода
      ['gr'] = { 'references', desc = 'Browse code references' }, -- Просмотр ссылок на код
      ['<leader>aS'] = {
        'navigate_session_tree',
        { 'child', 'picker' },
        desc = 'Select child session',
      }, -- Выбрать дочернюю сессию
      ['<leader>aP'] = { 'navigate_session_tree', { 'parent' }, desc = 'Go to parent session' }, -- Перейти к родительской сессии
      ['<leader>aB'] = {
        'navigate_session_tree',
        { 'sibling', 'picker' },
        desc = 'Select sibling session',
      }, -- Выбрать соседнюю сессию
      ['<leader>aD'] = { 'debug_message', desc = 'Open raw message debug view' }, -- Открыть дебаг сообщения
      ['<leader>aO'] = { 'debug_output', desc = 'Open raw output debug view' }, -- Открыть дебаг вывода
      ['<leader>ads'] = { 'debug_session', desc = 'Open raw session debug view' }, -- Открыть дебаг сессии
    },
    output_window = {
      ['<tab>'] = false, -- Переключить панели ввода/вывода
      ['<C-c>'] = false, -- Отменить текущий запрос
      [']]'] = false, -- Перейти к следующему сообщению
      ['[['] = false, -- Перейти к предыдущему сообщению
      ['<M-i>'] = false, -- Переключить окно ввода

      ['<C-wq>'] = { 'close', desc = 'Close Opencode' }, -- Закрыть Opencode
      ['<esc>'] = { 'cancel', desc = 'Cancel running request' }, -- Отменить текущий запрос
      ['<C-n>'] = { 'next_message', desc = 'Go to next message' }, -- Перейти к следующему сообщению
      ['<C-p>'] = { 'prev_message', desc = 'Go to previous message' }, -- Перейти к предыдущему сообщению
      ['i'] = { 'focus_input', desc = 'Focus input window' }, -- Сфокусироваться на вводе

      ['gr'] = { 'references', desc = 'Browse code references' }, -- Просмотр ссылок на код
      ['gf'] = { 'jump_to_file', desc = 'Jump to file at cursor' }, -- Перейти к файлу под курсором
      ['<leader>aS'] = {
        'navigate_session_tree',
        { 'child', 'picker' },
        desc = 'Select child session',
      }, -- Выбрать дочернюю сессию
      ['<leader>aP'] = { 'navigate_session_tree', { 'parent' }, desc = 'Go to parent session' }, -- Перейти к родительской сессии
      ['<leader>aB'] = {
        'navigate_session_tree',
        { 'sibling', 'picker' },
        desc = 'Select sibling session',
      }, -- Выбрать соседнюю сессию
      ['<leader>aD'] = { 'debug_message', desc = 'Open raw message debug view' }, -- Открыть дебаг сообщения
      ['<leader>aO'] = { 'debug_output', desc = 'Open raw output debug view' }, -- Открыть дебаг вывода
      ['<leader>ads'] = { 'debug_session', desc = 'Open raw session debug view' }, -- Открыть дебаг сессии
    },
    session_picker = {
      rename_session = { '<C-r>' }, -- Переименовать выбранную сессию
      delete_session = { '<C-d>' }, -- Удалить выбранные сессии
      new_session = { '<C-s>' }, -- Создать новую сессию
    },
    timeline_picker = {
      undo = { '<C-u>', mode = { 'i', 'n' }, desc = 'Undo to selected message' }, -- Отмена до выбранного сообщения
      fork = { '<C-f>', mode = { 'i', 'n' }, desc = 'Fork from selected message' }, -- Ответ на выбранное сообщение (fork)
    },
    history_picker = {
      delete_entry = { '<C-d>', mode = { 'i', 'n' }, desc = 'Delete selected history entries' }, -- Удалить выбранные записи истории
      clear_all = { '<C-X>', mode = { 'i', 'n' }, desc = 'Clear all history entries' }, -- Очистить всю историю
    },
    model_picker = {
      toggle_favorite = { '<C-f>', mode = { 'i', 'n' }, desc = 'Toggle model favorite' }, -- Переключить избранное для модели
    },
    mcp_picker = {
      toggle_connection = { '<C-t>', mode = { 'i', 'n' }, desc = 'Toggle MCP server connection' }, -- Переключить подключение MCP сервера
    },
    quick_chat = {
      cancel = { '<C-c>', mode = { 'i', 'n' }, desc = 'Cancel active quick chat requests' }, -- Отменить активные запросы быстрого чата
    },
  },

  -- Конфигурация сервера
  server = {
    url = nil, -- URL/хост (например, 'localhost', 'https://myserver.com')
    port = nil, -- Порт, 'auto' для случайного порта
    timeout = 5, -- Таймаут проверки состояния в секундах
    retry_delay = 2000, -- Задержка между попытками в мс
    spawn_command = nil, -- Функция для запуска сервера: function(port, url) ... end
    kill_command = nil, -- Функция для остановки сервера
    auto_kill = true, -- Убивать запущенные серверы при выходе из последнего экземпляра nvim
    path_map = nil, -- Маппинг путей хоста на пути сервера: строка или функция(path) -> string
    reverse_path_map = nil, -- Обратный маппинг
  },

  -- Конфигурация интерфейса
  ui = {
    input = {
      min_height = 0.20,
      max_height = 0.30,
      text = { wrap = true },
      auto_hide = true,
      win_options = {
        signcolumn = 'no',
        cursorline = false,
        number = false,
        relativenumber = false,
        statusline = ' %=%{&filetype}%= ',
      },
    },
    output = {
      filetype = 'opencode_output',
      time_format = nil,
      compact_assistant_headers = false,
      rendering = {
        markdown_debounce_ms = 250,
        on_data_rendered = nil,
        markdown_on_idle = false,
        markdown_on_idle_threshold = nil,
        event_throttle_ms = 40,
        event_collapsing = true,
      },
      tools = {
        show_output = false,
        show_reasoning_output = false,
        use_folds = true,
        folding_threshold = 25,
      },
      max_messages = nil,
      always_scroll_to_bottom = false,
    },
    enable_treesitter_markdown = true,
    position = 'right', -- 'справа', 'слева' или 'текущее'
    input_position = 'top', -- 'снизу' или 'сверху'
    window_width = 0.50, -- Ширина в процентах от ширины редактора
    zoom_width = 0.8, -- Ширина зума в процентах от ширины редактора
    float = {
      width = 0.95,
      height = 0.9,
      row = nil,
      col = nil,
      border = 'rounded',
      gap = 1,
      zindex = 40,
      opts = { winblend = 0 },
    },
    picker_width = 100,
    display_model = true,
    display_context_size = true,
    display_cost = false,
    window_highlight = 'Normal:OpencodeBackground,FloatBorder:OpencodeBorder',
    persist_state = true, -- Сохранять буферы при переключении/закрытии UI
    icons = {
      preset = 'nerdfonts', -- 'nerdfonts' или 'text'
      overrides = {},
    },
    loading_animation = {
      frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
    },
    questions = {
      use_vim_ui_select = false, -- Использовать vim.ui.select вместо инлайна
    },
    picker = {
      snacks_layout = nil,
    },
    completion = {
      file_sources = {
        enabled = true,
        preferred_cli_tool = 'server',
        ignore_patterns = {
          '^%.git/',
          '^%.svn/',
          '^%.hg/',
          '^%.jj/',
          'node_modules/',
          '%.pyc$',
          '%.o$',
          '%.obj$',
          '%.exe$',
          '%.dll$',
          '%.so$',
          '%.dylib$',
          '%.class$',
          '%.jar$',
          '%.war$',
          '%.ear$',
          'target/',
          'build/',
          'dist/',
          'out/',
          'deps/',
          '%.tmp$',
          '%.temp$',
          '%.log$',
          '%.cache$',
        },
        max_files = 10,
        max_display_length = 50,
      },
    },
  },

  -- Конфигурация контекста
  context = {
    enabled = true, -- Включить автоматический сбор контекста
    cursor_data = {
      enabled = false, -- Включать позицию курсора и содержимое строки в контекст
      context_lines = 5,
    },
    diagnostics = {
      enabled = true, -- Включать информацию о диагностике в контекст
      info = false,
      warning = true,
      error = true,
      only_closest = false,
    },
    current_file = {
      enabled = true, -- Включать путь и содержимое текущего файла в контекст
      show_full_path = true,
    },
    files = {
      enabled = true, -- Включать информацию о упомянутых файлах в контекст
      show_full_path = true,
    },
    selection = {
      enabled = true, -- Включать выделенный текст в контекст
    },
    agents = {
      enabled = true, -- Включать доступные агенты в контекст
    },
    buffer = {
      enabled = false, -- Отключить весь контекст буфера по умолчанию, используется только в quick chat
    },
    git_diff = {
      enabled = false, -- Включать git diff в контекст
    },
  },

  -- Конфигурация логирования
  logging = {
    enabled = false,
    level = 'info', -- debug, info, warn, error
    outfile = nil,
  },

  -- Конфигурация отладки
  debug = {
    enabled = false, -- Включить сообщения отладки в окне вывода
    capture_streamed_events = false, -- Захватывать потоковые события
    show_ids = true, -- Показывать ID
    highlight_changed_lines = false, -- Подсвечивать измененные строки
    highlight_changed_lines_timeout_ms = 120,
    quick_chat = {
      keep_session = false,
      set_active_session = false,
    },
  },

  -- Пользовательские хуки
  hooks = {
    on_file_edited = nil,
    on_session_loaded = nil,
    on_done_thinking = nil,
    on_permission_requested = nil,
  },

  -- Конфигурация Quick Chat
  quick_chat = {
    default_model = nil,
    default_agent = nil,
    instructions = nil,
  },
})
