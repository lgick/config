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

vim.opt.statusline = '%<%{%v:lua.StatuslineLeft()%}%=%{%v:lua.StatuslineRight()%}'
