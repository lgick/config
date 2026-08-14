------------------------------------------
-- Дефолтные группы подсветки (Fallbacks)
------------------------------------------

local function set_statusline_defaults()
  local set_hl = vim.api.nvim_set_hl
  set_hl(0, 'StatusLineHelp', { link = 'StatusLine', default = true })
  set_hl(0, 'StatusLineNotModifiable', { link = 'StatusLine', default = true })
  set_hl(0, 'StatusLineReadOnly', { link = 'StatusLine', default = true })
  set_hl(0, 'StatusLineInsertEn', { link = 'StatusLine', default = true })
  set_hl(0, 'StatusLineInsertRu', { link = 'StatusLine', default = true })

  -- Подушка безопасности для GitStageFlow (если тема их не настраивает)
  set_hl(0, 'GitSignsStatusLine', { link = 'StatusLine', default = true })
  set_hl(0, 'GitSignsStatusLineUnstaged', { link = 'StatusLine', default = true })
  set_hl(0, 'GitSignsStatusLineStaged', { link = 'StatusLine', default = true })
end

-- Инициализируем при старте и восстанавливаем при смене тем оформления
set_statusline_defaults()
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = set_statusline_defaults,
})

------------------------------------------
-- Управление цветом курсора в режиме вставки
------------------------------------------

function _G.UpdateCursorColor()
  local mode = vim.api.nvim_get_mode().mode
  local is_insert = mode:sub(1, 1) == 'i'

  if is_insert then
    local lang = vim.opt.iminsert:get()
    if lang == 0 then
      vim.api.nvim_set_hl(0, 'CursorInsert', { link = 'CursorInsertEn' })
    elseif lang == 1 then
      vim.api.nvim_set_hl(0, 'CursorInsert', { link = 'CursorInsertRu' })
    end
  else
    vim.api.nvim_set_hl(0, 'CursorInsert', { link = 'CursorInsertEn' })
  end
end

------------------------------------------
-- Классификация буферов по категориям
------------------------------------------

function _G.GetBufferCategory(bufnr)
  local buftype = vim.bo[bufnr].buftype
  local fname = vim.api.nvim_buf_get_name(bufnr)

  -- docs
  if buftype == 'help' then
    return 'docs'
  -- пустой буфер
  elseif buftype == '' and fname == '' then
    return 'empty'
  -- файл
  elseif buftype == '' then
    return 'file'
  end

  -- плагин
  return 'plugin_file'
end

------------------------------------------
-- Определение цвета статуслайна
------------------------------------------

function _G.StatuslineHighlight()
  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()

  -- Проверяем, активно ли окно, которое сейчас отрисовывается
  local is_active = (winnr == tonumber(vim.g.actual_curwin or 0))

  -- Неактивные окна не перекрашиваем (используют дефолтный StatusLineNC)
  if not is_active then
    return ''
  end

  local category = _G.GetBufferCategory(bufnr)

  -- 1. Сначала обрабатываем режим вставки для обычных файлов
  if category == 'file' then
    local mode = vim.api.nvim_get_mode().mode
    local is_insert = mode:sub(1, 1) == 'i'

    if is_insert then
      local lang = vim.opt.iminsert:get()
      if lang == 0 then
        return '%#StatusLineInsertEn#'
      elseif lang == 1 then
        return '%#StatusLineInsertRu#'
      end
    end
  end

  -- 2. Если мы не в режиме вставки, проверяем типы буферов
  if category == 'docs' then
    return '%#StatusLineHelp#'
  elseif category == 'file' then
    -- Если для этого буфера сейчас запущен GitStageFlow,
    -- мы возвращаем пустую строку и полностью отдаем управление цвету из gitsigns.lua
    local is_git_stage = vim.b[bufnr].original_modifiable ~= nil
    if is_git_stage then
      return ''
    end

    if not vim.bo[bufnr].modifiable then
      return '%#StatusLineNotModifiable#'
    elseif vim.bo[bufnr].readonly then
      return '%#StatusLineReadOnly#'
    end
  end

  return ''
end

------------------------------------------
-- Компоненты статуслайна
------------------------------------------

function _G.StatuslineFlags()
  local bufnr = vim.api.nvim_get_current_buf()
  local category = _G.GetBufferCategory(bufnr)

  -- Флаги [+][-][RO] показываем только для реальных файлов на диске
  if category ~= 'file' then
    return ''
  end

  local flags = ''
  if vim.bo[bufnr].modified then
    flags = flags .. '[+]'
  elseif not vim.bo[bufnr].modifiable then
    flags = flags .. '[-]'
  end
  if vim.bo[bufnr].readonly then
    flags = flags .. '[RO]'
  end
  return flags
end

function _G.StatuslineEnc()
  local bufnr = vim.api.nvim_get_current_buf()
  local category = _G.GetBufferCategory(bufnr)

  -- Кодировку показываем только для реальных файлов на диске
  if category ~= 'file' then
    return ''
  end

  local fenc = vim.bo[bufnr].fenc
  if fenc == '' then
    fenc = vim.opt.encoding:get()
  end
  return '[' .. fenc .. ']'
end

function _G.StatuslineRuler()
  local bufnr = vim.api.nvim_get_current_buf()
  local category = _G.GetBufferCategory(bufnr)

  -- Для документации выводим только "строка/всего строк"
  if category == 'docs' then
    return '%l/%L'
  end
  -- Для обычных файлов — стандартную линейку
  return '%v-%l/%L %P'
end

function _G.StatuslineDate()
  local bufnr = vim.api.nvim_get_current_buf()
  local category = _G.GetBufferCategory(bufnr)

  -- Дату выводим только для реальных файлов на диске
  if category ~= 'file' then
    return ''
  end

  local fname = vim.api.nvim_buf_get_name(bufnr)
  if fname == '' or vim.fn.filereadable(fname) == 0 then
    return ''
  end

  local time
  if vim.bo[bufnr].modified then
    time = vim.fn.strftime('%d.%m.%Y %H:%M')
  else
    time = vim.fn.strftime('%d.%m.%Y %H:%M', vim.fn.getftime(fname))
  end

  return '[' .. time .. ']'
end

------------------------------------------
-- Сборка левой и правой частей
------------------------------------------

function _G.StatuslineLeft()
  local bufnr = vim.api.nvim_get_current_buf()
  local category = _G.GetBufferCategory(bufnr)

  -- Если буфер пустой — левая часть пустая
  if category == 'empty' then
    return ''
  end

  local filename = vim.fn.expand('%')
  local flags = _G.StatuslineFlags()
  local enc = _G.StatuslineEnc()

  local left = filename .. flags

  if enc ~= '' then
    left = left .. ' ' .. enc
  end

  return left
end

function _G.StatuslineRight()
  local bufnr = vim.api.nvim_get_current_buf()
  local category = _G.GetBufferCategory(bufnr)

  -- Скрываем правую часть для пустых буферов и плагинов
  if category == 'empty' or category == 'plugin_file' then
    return ''
  end

  local ruler = _G.StatuslineRuler()
  local date = _G.StatuslineDate()

  local right = ruler
  if date ~= '' then
    right = ruler .. ' ' .. date
  end

  return ' ' .. right
end

------------------------------------------
-- Применение шаблона
------------------------------------------

vim.opt.statusline =
  '%<%{%v:lua.StatuslineHighlight()%}%{%v:lua.StatuslineLeft()%}%=%{%v:lua.StatuslineRight()%}%*'
