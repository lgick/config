local actions = require('diffview.config').actions
local lib = require('diffview.lib')

-- view с фокусом в панели, иначе nil
local function focused_view()
  local view = lib.get_current_view()
  if view and view.panel:is_focused() then
    return view
  end
end

-- git -C <toplevel> ... (как vim.fn.system / systemlist; shell_error выставляется)
local function git(toplevel, args)
  return vim.fn.system(vim.list_extend({ 'git', '-C', toplevel }, args))
end

local function git_lines(toplevel, args)
  return vim.fn.systemlist(vim.list_extend({ 'git', '-C', toplevel }, args))
end

-- Подтверждение y/n с очисткой командной строки
local function confirm(prompt)
  local answer = vim.fn.input(prompt)
  vim.cmd('redraw!')
  vim.api.nvim_echo({}, false, {})
  return answer:lower() == 'y'
end

-- Обновление nvim-tree и открытых буферов после выхода из diffview.
-- Вызывается из хуков view_leave/view_closed: diffview всегда в своей вкладке,
-- поэтому дерево становится видимым только после ухода с этой вкладки. vim.schedule
-- выполняется уже после переключения вкладки → reload_explorer перерисует дерево.
local function refresh_after_diffview()
  vim.schedule(function()
    vim.cmd('checktime') -- перечитать изменившиеся на диске буферы
    local ok, api = pcall(require, 'nvim-tree.api')
    if ok then
      pcall(api.tree.reload)
    end
  end)
end

-- Закрывает буферы файлов, которых больше нет на диске (после restore проекта)
local function close_missing_buffers(toplevel)
  -- Префикс с разделителем, чтобы '/a/proj' не совпадал с '/a/proj2/...'
  local prefix = toplevel:gsub('/+$', '') .. '/'
  vim.schedule(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
        local name = vim.api.nvim_buf_get_name(buf)
        -- Только буферы из текущего репо, у которых нет файла на диске
        if name ~= '' and name:sub(1, #prefix) == prefix and not vim.uv.fs_stat(name) then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
  end)
end

-- Открывает файл из панели истории (в single_file режиме — всегда, иначе только
-- если курсор на файле, не на коммите)
local function open_file()
  local view = focused_view()
  if not view then
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
  local view = focused_view()
  if not view then
    return
  end

  -- Курсор должен стоять на файле, а не на заголовке/группе
  local item = view.panel:get_item_at_cursor()
  if not item or item.files then
    return
  end

  if not confirm('Restore file? (y/n): ') then
    return
  end

  vim.schedule(actions.restore_entry)
end

-- Универсальный restore для file_history_panel:
-- курсор на коммите (multi-file) → восстановить весь проект
-- курсор на файле (или коммите в single_file режиме) → восстановить один файл
local function restore_with_confirm()
  local view = focused_view()
  if not view then
    return
  end

  local item = view.panel:get_item_at_cursor()
  if not item then
    return
  end

  local toplevel = view.adapter.ctx and view.adapter.ctx.toplevel
  if not toplevel then
    vim.notify('Cannot determine repo toplevel', vim.log.levels.ERROR)
    return
  end

  -- Курсор на коммите в режиме истории проекта → восстановить весь проект
  if item.files and not view.panel.single_file then
    local hash = item.commit and item.commit.hash
    if not hash then
      return
    end

    local short_hash = hash:sub(1, 7)
    if not confirm(('Restore project from commit %s? (y/n): '):format(short_hash)) then
      return
    end

    -- Сохраняем незакоммиченные изменения в stash с именем для опознавания.
    -- --untracked-files=all форсирует показ untracked, даже если в конфиге
    -- стоит status.showUntrackedFiles=no (иначе clean -fd удалит их безвозвратно).
    local stashed = false
    local dirty = git(toplevel, { 'status', '--porcelain', '--untracked-files=all' })
    if vim.trim(dirty) ~= '' then
      local branch = vim.trim(git(toplevel, { 'branch', '--show-current' }))
      local head_short = vim.trim(git(toplevel, { 'rev-parse', '--short', 'HEAD' }))
      local stash_msg = ('WIP on %s:%s (before restore to %s)'):format(
        branch,
        head_short,
        short_hash
      )
      git(toplevel, { 'stash', 'push', '--include-untracked', '-m', stash_msg })
      if vim.v.shell_error ~= 0 then
        vim.notify('git stash failed', vim.log.levels.ERROR)
        return
      end
      stashed = true
    end

    -- Сравниваем деревья HEAD и hash для точного определения удаляемых файлов
    local head_files = git_lines(toplevel, { 'ls-tree', '-r', '--name-only', 'HEAD' })
    local hash_files = git_lines(toplevel, { 'ls-tree', '-r', '--name-only', hash })

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
      local result = git(toplevel, { 'checkout', hash, '--', '.' })
      if vim.v.shell_error ~= 0 then
        -- Восстанавливаем спрятанные изменения, чтобы stash не остался «висеть»
        if stashed then
          git(toplevel, { 'stash', 'pop' })
        end
        vim.notify('git checkout failed: ' .. result, vim.log.levels.ERROR)
        return
      end
    end

    if #to_delete > 0 then
      local result = git(toplevel, vim.list_extend({ 'rm', '-f', '--' }, to_delete))
      if vim.v.shell_error ~= 0 then
        vim.notify('git rm failed: ' .. result, vim.log.levels.WARN)
      end
    end

    -- Убираем пустые директории после удаления файлов
    local clean_result = git(toplevel, { 'clean', '-fd' })
    if vim.v.shell_error ~= 0 then
      vim.notify('git clean failed: ' .. clean_result, vim.log.levels.WARN)
    end
    vim.notify('Restored to ' .. short_hash)
    close_missing_buffers(toplevel)
    -- DiffviewClose → хук view_closed обновит nvim-tree и буферы
    vim.cmd('DiffviewClose')
    return
  end

  -- Курсор на коммите в single_file режиме → берём файл из коммита
  if item.files then
    item = item.files[1]
    if not item then
      return
    end
  end

  local hash = item.commit and item.commit.hash
  local short_hash = hash and hash:sub(1, 7) or ''

  if not confirm(('Restore file from commit %s? (y/n): '):format(short_hash)) then
    return
  end

  local restore_ref
  if item.status == 'D' then
    -- Файл удалён в этом коммите → берём версию из родительского коммита
    restore_ref = hash .. '^1'
    -- У корневого коммита нет родителя — даём понятную ошибку вместо cryptic от git
    git(toplevel, { 'rev-parse', '--verify', '--quiet', restore_ref .. '^{commit}' })
    if vim.v.shell_error ~= 0 then
      vim.notify('Cannot restore: commit ' .. short_hash .. ' has no parent', vim.log.levels.ERROR)
      return
    end
  else
    restore_ref = hash
  end

  -- git checkout автоматически создаёт директории если их нет
  local result = git(toplevel, { 'checkout', restore_ref, '--', item.path })
  if vim.v.shell_error ~= 0 then
    vim.notify('Restore failed: ' .. result, vim.log.levels.ERROR)
    return
  end
  -- nvim-tree и буферы обновятся хуком view_leave при выходе из diffview
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
    -- Обновление nvim-tree и буферов при уходе/закрытии diffview (см. refresh_after_diffview)
    view_leave = refresh_after_diffview,
    view_closed = refresh_after_diffview,
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
      { 'n', '<C-p>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
      { 'n', '<C-n>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
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
      { 'n', '<C-p>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
      { 'n', '<C-n>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
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
