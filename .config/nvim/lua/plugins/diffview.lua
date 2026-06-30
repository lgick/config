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

-- Надёжная перезагрузка nvim-tree.
-- nvim-tree.reload_explorer обновляет модель данных всегда, но РИСУЕТ только
-- если окно дерева видно (view.is_visible()). После restore фокус в панели
-- diffview (часто в отдельной вкладке) → дерево не перерисовывается, узел
-- (напр. восстановленный .stylua.toml) не виден до ручного R. Поэтому:
--   1) reload сразу/с задержкой — отрисует, если дерево видно прямо сейчас;
--   2) одноразовый BufEnter на буфере NvimTree_* — ГАРАНТИРУЕТ перерисовку,
--      когда пользователь вернётся к дереву (вход в окно не делает reload сам).
local nvt_group = vim.api.nvim_create_augroup('DiffviewNvimTreeReload', { clear = true })
local function reload_nvim_tree()
  local ok, api = pcall(require, 'nvim-tree.api')
  if not ok then
    return
  end

  local function reload()
    pcall(api.tree.reload)
  end

  vim.schedule(reload) -- если дерево видно сейчас — отрисуется сразу
  vim.defer_fn(reload, 100) -- после settle git-статуса / диффвью

  -- перерисовать при следующем входе в окно дерева
  pcall(vim.api.nvim_clear_autocmds, { group = nvt_group })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = nvt_group,
    pattern = 'NvimTree_*',
    once = true,
    callback = reload,
  })
end

-- Закрывает буферы файлов, которых больше нет на диске (после restore)
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

-- Восстановление файла в file_panel (git diff, без истории коммитов)
local function restore_file_with_confirm()
  local view = require('diffview.lib').get_current_view()

  if not view or not view.panel:is_focused() then
    return
  end

  -- Курсор должен стоять на файле, а не на заголовке/группе
  local item = view.panel:get_item_at_cursor()
  if not item or item.files then
    return
  end

  local answer = vim.fn.input('Restore file? (y/n): ')

  vim.cmd('redraw!')
  vim.api.nvim_echo({}, false, {})

  if answer:lower() == 'y' then
    vim.schedule(function()
      actions.restore_entry()
      vim.cmd('checktime') -- обновляем открытые буферы, изменившиеся на диске
      reload_nvim_tree()
    end)
  end
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
  if not toplevel then
    vim.notify('Cannot determine repo toplevel', vim.log.levels.ERROR)
    return
  end

  -- Курсор на коммите в режиме истории проекта → восстановить весь проект
  if item.files and not view.panel.single_file then
    local hash = item.commit and item.commit.hash
    if not hash then return end

    local short_hash = hash:sub(1, 7)
    local answer = vim.fn.input(('Restore project from commit %s? (y/n): '):format(short_hash))
    vim.cmd('redraw!')
    vim.api.nvim_echo({}, false, {})

    if answer:lower() ~= 'y' then return end

    -- Сохраняем незакоммиченные изменения в stash с именем для опознавания.
    -- --untracked-files=all форсирует показ untracked, даже если в конфиге
    -- стоит status.showUntrackedFiles=no (иначе clean -fd удалит их безвозвратно).
    local stashed = false
    local dirty = vim.fn.system({ 'git', '-C', toplevel, 'status', '--porcelain', '--untracked-files=all' })
    if vim.trim(dirty) ~= '' then
      local branch = vim.trim(vim.fn.system({ 'git', '-C', toplevel, 'branch', '--show-current' }))
      local head_short = vim.trim(vim.fn.system({ 'git', '-C', toplevel, 'rev-parse', '--short', 'HEAD' }))
      local stash_msg = ('WIP on %s:%s (before restore to %s)'):format(branch, head_short, short_hash)
      vim.fn.system({ 'git', '-C', toplevel, 'stash', 'push', '--include-untracked', '-m', stash_msg })
      if vim.v.shell_error ~= 0 then
        vim.notify('git stash failed', vim.log.levels.ERROR)
        return
      end
      stashed = true
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
        -- Восстанавливаем спрятанные изменения, чтобы stash не остался «висеть»
        if stashed then
          vim.fn.system({ 'git', '-C', toplevel, 'stash', 'pop' })
        end
        vim.notify('git checkout failed: ' .. result, vim.log.levels.ERROR)
        return
      end
    end

    if #to_delete > 0 then
      local result = vim.fn.system(vim.list_extend({ 'git', '-C', toplevel, 'rm', '-f', '--' }, to_delete))
      if vim.v.shell_error ~= 0 then
        vim.notify('git rm failed: ' .. result, vim.log.levels.WARN)
      end
    end

    -- Убираем пустые директории после удаления файлов
    local clean_result = vim.fn.system({ 'git', '-C', toplevel, 'clean', '-fd' })
    if vim.v.shell_error ~= 0 then
      vim.notify('git clean failed: ' .. clean_result, vim.log.levels.WARN)
    end
    vim.notify('Restored to ' .. short_hash)
    vim.cmd('DiffviewClose')
    close_missing_buffers(toplevel)
    -- Перезагружаем открытые буферы и nvim-tree (файлы обновились на диске)
    vim.schedule(function()
      vim.cmd('checktime')
      reload_nvim_tree()
    end)
    return
  end

  -- Курсор на коммите в single_file режиме → берём файл из коммита
  if item.files then
    item = item.files[1]
    if not item then return end
  end

  local hash = item.commit and item.commit.hash
  local short_hash = hash and hash:sub(1, 7) or ''

  local answer = vim.fn.input(('Restore file from commit %s? (y/n): '):format(short_hash))
  vim.cmd('redraw!')
  vim.api.nvim_echo({}, false, {})

  if answer:lower() ~= 'y' then return end

  local restore_ref
  if item.status == 'D' then
    -- Файл удалён в этом коммите → берём версию из родительского коммита
    restore_ref = hash .. '^1'
    -- У корневого коммита нет родителя — даём понятную ошибку вместо cryptic от git
    vim.fn.system({ 'git', '-C', toplevel, 'rev-parse', '--verify', '--quiet', restore_ref .. '^{commit}' })
    if vim.v.shell_error ~= 0 then
      vim.notify('Cannot restore: commit ' .. short_hash .. ' has no parent', vim.log.levels.ERROR)
      return
    end
  else
    restore_ref = hash
  end

  -- git checkout автоматически создаёт директории если их нет
  local result = vim.fn.system({ 'git', '-C', toplevel, 'checkout', restore_ref, '--', item.path })
  if vim.v.shell_error ~= 0 then
    vim.notify('Restore failed: ' .. result, vim.log.levels.ERROR)
    return
  end

  -- Обновляем открытые буферы (изменившиеся на диске) и nvim-tree.
  -- Голый checktime безопаснее bufnr(path): bufnr трактует путь как паттерн.
  vim.schedule(function()
    vim.cmd('checktime')
    reload_nvim_tree()
  end)
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
      reload_nvim_tree()
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
