local M = {}
local initialized = false

local function ensure()
  if initialized then
    return
  end
  require('persistence').setup({
    dir = vim.fn.stdpath('config') .. '/_sessions/',
    need = 0,
    branch = false,
  })
  require('persistence').stop()
  initialized = true
end

local function find_tree_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'NvimTree' then
      return win
    end
  end
end

local function tree_flag(session_path)
  return session_path .. '.tree'
end

function M.save()
  ensure()
  local tree_win = find_tree_win()
  if tree_win then
    vim.api.nvim_win_close(tree_win, true)
  end
  require('persistence').save()
  local path = require('persistence').current()
  if path then
    if tree_win then
      io.open(tree_flag(path), 'w'):close()
    else
      os.remove(tree_flag(path))
    end
  end
  if tree_win then
    local ok, tree_api = pcall(require, 'nvim-tree.api')
    if ok then
      tree_api.tree.open()
    end
  end
end

local function fix_tree_after_load(session_path)
  vim.schedule(function()
    -- Закрываем сломанное окно nvim-tree из старых сессий
    local tree_win = find_tree_win()
    if tree_win then
      vim.api.nvim_win_close(tree_win, true)
    end
    local ok, tree_api = pcall(require, 'nvim-tree.api')
    if not ok then
      return
    end
    -- Открываем только если при сохранении был открыт (флаг)
    if session_path and vim.fn.filereadable(tree_flag(session_path)) == 1 then
      tree_api.tree.open()
    end
    -- Всегда синхронизируем корень с текущим cwd (на случай если дерево осталось с прошлой директорией)
    if find_tree_win() then
      tree_api.tree.change_root(vim.fn.getcwd())
    end
  end)
end

function M.load()
  ensure()
  require('persistence').load()
  fix_tree_after_load(require('persistence').current())
end

function M.select()
  ensure()

  local persistence = require('persistence')

  local function parse_name(path)
    return vim.fn.fnamemodify(path, ':t:r'):gsub('%%', '/')
  end

  Snacks.picker.pick('sessions', {
    title = 'All Sessions  [CR] load  [d] delete',
    layout = 'select',
    finder = function()
      return vim.tbl_map(function(path)
        return { text = parse_name(path), path = path }
      end, persistence.list())
    end,
    format = function(item)
      return { { item.text } }
    end,
    actions = {
      confirm = function(picker, item)
        picker:close()
        if item then
          vim.cmd('source ' .. vim.fn.fnameescape(item.path))
          fix_tree_after_load(item.path)
        end
      end,
      delete_session = function(picker, item)
        if not item then
          return
        end
        vim.fn.delete(item.path)
        vim.fn.delete(tree_flag(item.path))
        vim.notify('Deleted: ' .. item.text)
        picker:find()
      end,
    },
    win = {
      list = {
        keys = {
          ['<CR>'] = 'confirm',
          ['d'] = 'delete_session',
        },
      },
    },
  })
end

function M.delete()
  ensure()
  local path = require('persistence').current()
  if not path or vim.fn.filereadable(path) == 0 then
    vim.notify('No session file for current project', vim.log.levels.WARN)
    return
  end
  vim.fn.delete(path)
  vim.fn.delete(tree_flag(path))
  vim.notify('Session deleted: ' .. vim.fn.fnamemodify(path, ':t'))
end

return M
