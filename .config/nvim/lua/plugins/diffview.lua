local actions = require('diffview.config').actions

local function open_file()
  local view = require('diffview.lib').get_current_view()

  if not view or not view.panel:is_focused() then
    return
  end

  if view.panel.single_file == true then
    actions.select_entry()
  else
    local item = view.panel:get_item_at_cursor()

    if not item or item.files then
      return
    end

    actions.select_entry()
  end
end

local function restore_with_confirm()
  local answer = vim.fn.input('Restore this file? (y/n): ')

  vim.cmd('redraw!')
  vim.api.nvim_echo({}, false, {})

  if answer:lower() == 'y' then
    vim.schedule(function()
      actions.restore_entry()
    end)
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
    disable_defaults = true, -- Disable the default keymaps
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
      { 'n', 'R', restore_with_confirm, { desc = 'Restore file to state from selected entry' } },
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
      { 'n', 'R', restore_with_confirm, { desc = 'Restore file to state from selected entry' } },
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
