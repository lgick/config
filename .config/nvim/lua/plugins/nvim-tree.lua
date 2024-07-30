return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    local function custom_attach(bufnr)
      local api = require "nvim-tree.api"
      local keymap = vim.keymap

      local function opts(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- custom mappings
      keymap.set('n', 'o', api.node.open.edit, opts('Open'))
      keymap.set('n', '<C-m>', api.node.open.edit)
      keymap.set('n', 's', api.node.open.vertical, opts('Open Vertical'))
      keymap.set('n', 'i', api.node.open.horizontal, opts('Open Horizontal'))
      keymap.set('n', 't', api.node.open.tab, opts('Open Tab'))

      keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
      keymap.set('n', 'C', api.tree.change_root_to_node, opts('Change Root'))
      keymap.set('n', 'h', api.tree.toggle_hidden_filter, opts('Toggle Dotfiles'))
      keymap.set('n', 'H', api.tree.toggle_gitignore_filter, opts('Toggle Git Ignore'))
      keymap.set('n', 'X', api.tree.collapse_all, opts('Collapse All'))
      keymap.set('n', 'E', api.tree.expand_all, opts('Expand All'))
      keymap.set('n', 'q', api.tree.close, opts('Close'))
      keymap.set('n', 'R', api.tree.reload, opts('Refresh'))

      keymap.set('n', 'a', api.fs.create, opts('Create File'))
      keymap.set('n', 'c', api.fs.copy.node, opts('Copy'))
      keymap.set('n', 'x', api.fs.cut, opts('Cut'))
      keymap.set('n', 'p', api.fs.paste, opts('Paste'))
      keymap.set('n', 'd', api.fs.remove, opts('Delete'))
      keymap.set('n', 'r', api.fs.rename, opts('Rename'))
      keymap.set('n', 'u', api.fs.rename_full, opts('Rename Full Path'))

      keymap.set('n', 'f', api.live_filter.start, opts('Filter Start'))
      keymap.set('n', 'F', api.live_filter.clear, opts('Filter Clear'))
    end


    nvimtree.setup({
      on_attach = custom_attach,
      view = {
        width = 35,
        relativenumber = false,
      },
      -- change folder arrow icons
      renderer = {
        indent_markers = {
          enable = true,
        },
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "", -- arrow when folder is closed
              arrow_open = "", -- arrow when folder is open
            },
          },
        },
      },
      -- disable window_picker for
      -- explorer to work well with
      -- window splits
      actions = {
        open_file = {
          window_picker = {
            enable = false,
          },
        },
      },
      filters = {
        dotfiles = true,
        custom = {
          ".DS_Store",
          "*.pyc",
          "*.o",
          "*.obj",
          "*.svn",
          "*.swp",
          "*.class",
          "*.hg",
          "*.tmp",
          "*.zip",
        },
      },
      git = {
        ignore = false,
      },
    })
  end,
}
