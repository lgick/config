require('trouble').setup({
  auto_refresh = true,
  auto_preview = true,
  restore_window = true, -- Возвращать фокус на предыдущее окно после закрытия
  follow = true, -- Автоматически переходить к ошибке при перемещении в списке
  indent_guides = true, -- Рисовать линии вложенности в дереве
  max_items = 200, -- Ограничение количества строк (для производительности)
  multiline = true, -- Показывать длинные сообщения об ошибках целиком
  focus = true, -- Курсор в trouble при открытии

  keys = {
    ['?'] = 'help',
    r = 'refresh',
    q = 'close',
    ['<cr>'] = 'jump_close',
    s = 'jump_split',
    v = 'jump_vsplit',
    o = 'fold_toggle',
    i = 'inspect',
    dd = 'delete',
    d = { action = 'delete', mode = 'v' },
    X = 'fold_close_all',
    E = 'fold_open_all',

    ['<esc>'] = false,
    R = false,
    ['<2-leftmouse>'] = false,
    ['<c-s>'] = false,
    ['<c-v>'] = false,
    ['}'] = false,
    [']]'] = false,
    ['{'] = false,
    ['[['] = false,
    p = false,
    P = false,
    zo = false,
    zO = false,
    zc = false,
    zC = false,
    za = false,
    zA = false,
    zm = false,
    zr = false,
    zM = false,
    zR = false,
    zx = false,
    zX = false,
    zn = false,
    zN = false,
    zi = false,
    gb = false,
  },

  -- Группировка (по умолчанию по файлам)
  groups = {
    { 'filename', format = '{file} {git_status} {count}' },
  },
})
