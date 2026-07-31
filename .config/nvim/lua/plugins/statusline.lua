local opt = vim.opt
local fn = vim.fn

------------------------------------------
-- Имя буфера
------------------------------------------

function _G.StatuslineFilename()
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.bo[bufnr].buftype

  if buftype ~= '' then
    local ft = vim.bo[bufnr].filetype
    if ft ~= '' then
      return ft
    end
    return fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
  end

  return fn.expand('%')
end

function _G.StatuslineFlags()
  if vim.bo.buftype ~= '' then
    return ''
  end

  local flags = ''
  if vim.bo.filetype == 'help' then
    flags = flags .. '[Help]'
  end
  if vim.bo.modified then
    flags = flags .. '[+]'
  elseif not vim.bo.modifiable then
    flags = flags .. '[-]'
  end
  if vim.bo.readonly then
    flags = flags .. '[RO]'
  end
  return flags
end

function _G.StatuslineEnc()
  if vim.bo.buftype ~= '' then
    return ''
  end
  return '[' .. vim.bo.fenc .. ']'
end

------------------------------------------
-- Дата и время
------------------------------------------

function _G.StatuslineDate()
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.bo[bufnr].buftype
  local fname = vim.api.nvim_buf_get_name(bufnr)

  if buftype ~= '' or fname == '' or fn.filereadable(fname) == 0 then
    return ''
  end

  local time
  if vim.bo[bufnr].modified then
    time = fn.strftime('%d.%m.%Y %H:%M')
  else
    time = fn.strftime('%d.%m.%Y %H:%M', fn.getftime(fname))
  end

  return '[' .. time .. ']'
end

opt.statusline = "%<%{v:lua.StatuslineFilename()}%{v:lua.StatuslineFlags()} %{v:lua.StatuslineEnc()} %=%v-%l/%L %P %{v:lua.StatuslineDate()}"
