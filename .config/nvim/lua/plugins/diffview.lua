local actions = require('diffview.config').actions

-- Открывает файл из панели истории (в single_file режиме — всегда, иначе только если курсор на файле, не на коммите)
local function open_file()
  local view = require('diffview.lib').get_current_view()

  if not view or not view.panel:is_focused() then
    return
  end

  if view.panel.single_file == true then
    actions.select_entry()
  else
    local item = view.panel:get_item_at_cursor()

    -- item.files означает что курсор на коммите, а не на файле
    if not item or item.files then
      return
    end

    actions.select_entry()
  end
end

-- Восстановление файла в file_panel (git diff, без истории коммитов)
local function restore_file_with_confirm()
  local answer = vim.fn.input('Restore file? (y/n): ')

  vim.cmd('redraw!')
  vim.api.nvim_echo({}, false, {})

  if answer:lower() == 'y' then
    vim.schedule(function()
      actions.restore_entry()
    end)
  end
end

-- Закрывает буферы файлов, которых больше нет на диске (после restore)
local function close_missing_buffers(toplevel)
  vim.schedule(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
        local name = vim.api.nvim_buf_get_name(buf)
        -- Только буферы из текущего репо, у которых нет файла на диске
        if name ~= '' and name:sub(1, #toplevel) == toplevel and not vim.uv.fs_stat(name) then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
  end)
end

-- Универсальный restore для file_history_panel:
-- курсор на коммите (multi-file) → восстановить весь проект
-- курсор на файле (или коммите в single_file режиме) → восстановить один файл
local function restore_with_confirm()
  local view = require('diffview.lib').get_current_view()

  if not view or not view.panel:is_focused() then
    return
  end

  local item = view.panel:get_item_at_cursor()
  if not item then return end

  local toplevel = view.adapter.ctx and view.adapter.ctx.toplevel

  -- Курсор на коммите в режиме истории проекта → восстановить весь проект
  if item.files and not view.panel.single_file then
    local hash = item.commit and item.commit.hash
    if not hash then return end

    local short_hash = hash:sub(1, 7)
    local answer = vim.fn.input(('Restore project from commit %s? (y/n): '):format(short_hash))
    vim.cmd('redraw!')
    vim.api.nvim_echo({}, false, {})

    if answer:lower() ~= 'y' then return end

    -- Сохраняем незакоммиченные изменения в stash с именем для опознавания
    local dirty = vim.fn.system({ 'git', '-C', toplevel, 'status', '--porcelain' })
    if vim.trim(dirty) ~= '' then
      local branch = vim.trim(vim.fn.system({ 'git', '-C', toplevel, 'branch', '--show-current' }))
      local head_short = vim.trim(vim.fn.system({ 'git', '-C', toplevel, 'rev-parse', '--short', 'HEAD' }))
      local stash_msg = ('WIP on %s:%s (before restore to %s)'):format(branch, head_short, short_hash)
      vim.fn.system({ 'git', '-C', toplevel, 'stash', 'push', '--include-untracked', '-m', stash_msg })
      if vim.v.shell_error ~= 0 then
        vim.notify('git stash failed', vim.log.levels.ERROR)
        return
      end
    end

    -- Сравниваем деревья HEAD и hash для точного определения удаляемых файлов
    local head_files = vim.fn.systemlist({ 'git', '-C', toplevel, 'ls-tree', '-r', '--name-only', 'HEAD' })
    local hash_files = vim.fn.systemlist({ 'git', '-C', toplevel, 'ls-tree', '-r', '--name-only', hash })

    local hash_set = {}
    for _, f in ipairs(hash_files) do
      hash_set[f] = true
    end

    -- Файлы которые есть в HEAD но нет в hash — нужно удалить
    local to_delete = {}
    for _, f in ipairs(head_files) do
      if not hash_set[f] then
        table.insert(to_delete, f)
      end
    end

    -- Сначала checkout (пока индекс полный, pathspec '.' работает), потом удаляем лишнее
    if #hash_files > 0 then
      local result = vim.fn.system({ 'git', '-C', toplevel, 'checkout', hash, '--', '.' })
      if vim.v.shell_error ~= 0 then
        vim.notify('git checkout failed: ' .. result, vim.log.levels.ERROR)
        return
      end
    end

    if #to_delete > 0 then
      vim.fn.system(vim.list_extend({ 'git', '-C', toplevel, 'rm', '-f', '--' }, to_delete))
    end

    -- Убираем пустые директории после удаления файлов
    vim.fn.system({ 'git', '-C', toplevel, 'clean', '-fd' })
    vim.notify('Restored to ' .. short_hash)
    vim.cmd('DiffviewClose')
    close_missing_buffers(toplevel)
    return
  end

  -- Курсор на коммите в single_file режиме → берём файл из коммита
  if item.files then
    item = item.files[1]
    if not item then return end
  end

  local hash = item.commit and item.commit.hash
  local short_hash = hash and hash:sub(1, 7) or ''
  local abs_path = item.absolute_path
    or (toplevel and vim.fs.joinpath(toplevel, item.path))

  -- Файл удалён в этом коммите и уже отсутствует локально — нечего делать
  if item.status == 'D' and (not abs_path or not vim.uv.fs_stat(abs_path)) then
    vim.notify("'" .. item.path .. "' is already absent")
    return
  end

  local answer = vim.fn.input(('Restore file from commit %s? (y/n): '):format(short_hash))
  vim.cmd('redraw!')
  vim.api.nvim_echo({}, false, {})

  if answer:lower() ~= 'y' then return end

  if item.status == 'D' then
    -- Файл удалён в коммите → удаляем локально и из индекса
    vim.uv.fs_unlink(abs_path)
    vim.fn.system({ 'git', '-C', toplevel, 'rm', '--cached', '-f', '--', item.path })
    local bufnr = vim.fn.bufnr(abs_path)
    if bufnr ~= -1 then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  else
    -- git checkout автоматически создаёт директории если их нет
    local result = vim.fn.system({ 'git', '-C', toplevel, 'checkout', hash, '--', item.path })
    if vim.v.shell_error ~= 0 then
      vim.notify('Restore failed: ' .. result, vim.log.levels.ERROR)
    end
  end
end

require('diffview').setup({
  enhanced_diff_hl = true,
  file_panel = {
    listing_style = 'list',

    win_config = {
      position = 'bottom',
      height = 20,
    },
  },
  file_history_panel = {
    win_config = {
      height = 20,
    },
  },
  view = {
    default = {
      disable_diagnostics = true, -- Отключение ошибок LSP в диффах
      winbar_info = false, -- Плашки "a/файл" и "b/файл" сверху
    },
  },
  hooks = {
    view_closed = function()
      -- Обновление дерева nvim-tree (статусы git)
      local success, api = pcall(require, 'nvim-tree.api')
      if success then
        api.tree.reload()
      end
    end,
  },
  keymaps = {
    disable_defaults = true,
    view = {
      { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      { 'n', '?', actions.help({ 'view' }), { desc = 'Open the help panel' } },
      { 'n', 'f', actions.toggle_files, { desc = 'Toggle file panel' } },
    },
    file_panel = {
      { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      { 'n', '<CR>', actions.select_entry, { desc = 'Open file' } },
      { 'n', 'O', actions.goto_file_edit, { desc = 'Open local file' } },
      { 'n', 'f', actions.toggle_files, { desc = 'Toggle file panel' } },
      { 'n', 'r', restore_file_with_confirm, { desc = 'Restore file' } },
      { 'n', '<C-u>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
      { 'n', '<C-d>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
      { 'n', 'j', actions.next_entry, { desc = 'diffview_ignore' } },
      { 'n', 'k', actions.prev_entry, { desc = 'diffview_ignore' } },

      { 'n', 's', actions.toggle_stage_entry, { desc = 'Stage/unstage the selected entry' } },
      { 'n', 'S', actions.stage_all, { desc = 'Stage all entries' } },
      { 'n', 'U', actions.unstage_all, { desc = 'Unstage all entries' } },
      { 'n', '?', actions.help('file_panel'), { desc = 'Open the help panel' } },
    },
    file_history_panel = {
      { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      { 'n', '<CR>', open_file, { desc = 'Open file' } },
      { 'n', 'O', actions.goto_file_edit, { desc = 'Open local file' } },
      { 'n', 'f', actions.toggle_files, { desc = 'Toggle file panel' } },
      { 'n', 'o', actions.toggle_fold, { desc = 'Toggle directory' } },
      { 'n', 'r', restore_with_confirm, { desc = 'Restore file / project from commit' } },
      { 'n', '<C-u>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
      { 'n', '<C-d>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
      { 'n', 'j', actions.next_entry, { desc = 'diffview_ignore' } },
      { 'n', 'k', actions.prev_entry, { desc = 'diffview_ignore' } },

      { 'n', 'K', actions.open_commit_log, { desc = 'Show commit details' } },
      { 'n', '?', actions.help('file_history_panel'), { desc = 'Open the help panel' } },
      { 'n', '!', actions.options, { desc = 'Open the option panel' } },
    },
    option_panel = {
      { 'n', 'q', actions.close, { desc = 'Close the panel' } },
      { 'n', '?', actions.help('option_panel'), { desc = 'Open the help panel' } },
      { 'n', '<CR>', actions.select_entry, { desc = 'Change the current option' } },
    },
    help_panel = {
      { 'n', 'q', actions.close, { desc = 'Close help menu' } },
    },
  },
})
