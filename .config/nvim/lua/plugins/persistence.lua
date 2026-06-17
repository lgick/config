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

function M.save()
  ensure()
  require('persistence').save()
end

function M.load()
  ensure()
  require('persistence').load()
end

function M.select()
  ensure()

  local persistence = require('persistence')

  local function parse_name(path)
    return vim.fn.fnamemodify(path, ':t:r'):gsub('%%', '/')
  end

  Snacks.picker.pick('sessions', {
    title = 'Sessions  [CR] load  [d] delete',
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
          vim.schedule(function()
            require('nvim-tree.api').tree.change_root(vim.fn.getcwd())
          end)
        end
      end,
      delete_session = function(picker, item)
        if not item then
          return
        end
        vim.fn.delete(item.path)
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
  vim.notify('Session deleted: ' .. vim.fn.fnamemodify(path, ':t'))
end

return M
