return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    local function custom_attach(bufnr)
      local api = require("nvim-tree.api")
      local keymap = vim.keymap

      local function opts(desc)
        return {
          desc = "nvim-tree: " .. desc,
          buffer = bufnr,
          noremap = true,
          silent = true,
          nowait = true,
        }
      end

      -- custom mappings
      keymap.set("n", "o", api.node.open.edit, opts("Open"))
      keymap.set("n", "O", api.node.run.system, opts("Run System"))
      keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
      keymap.set("n", "s", api.node.open.vertical, opts("Open Vertical"))
      keymap.set("n", "i", api.node.open.horizontal, opts("Open Horizontal"))
      keymap.set("n", "t", api.node.open.tab, opts("Open Tab"))

      keymap.set("n", "?", api.tree.toggle_help, opts("Help"))
      keymap.set("n", "C", api.tree.change_root_to_node, opts("Change Root"))
      keymap.set("n", "I", api.tree.toggle_custom_filter, opts("Toggle Custom Filter"))
      keymap.set("n", "X", api.tree.collapse_all, opts("Collapse All"))
      keymap.set("n", "E", api.tree.expand_all, opts("Expand All"))
      keymap.set("n", "q", api.tree.close, opts("Close"))
      keymap.set("n", "R", api.tree.reload, opts("Refresh"))

      keymap.set("n", "a", api.fs.create, opts("Create File"))
      keymap.set("n", "c", api.fs.copy.node, opts("Copy"))
      keymap.set("n", "x", api.fs.cut, opts("Cut"))
      keymap.set("n", "p", api.fs.paste, opts("Paste"))
      keymap.set("n", "d", api.fs.remove, opts("Delete"))
      keymap.set("n", "r", api.fs.rename, opts("Rename"))
      keymap.set("n", "u", api.fs.rename_full, opts("Rename Full Path"))
    end

    nvimtree.setup({
      on_attach = custom_attach,
      hijack_cursor = true,
      view = {
        relativenumber = false,
        width = {
          min = 25, -- Минимальная ширина окна
          max = 40, -- Максимальная ширина окна
        },
        adaptive_size = true, -- Автоматическое изменение ширины окна
        side = "left", -- Позиция окна (left/right)
      },

      -- change folder arrow icons
      renderer = {
        highlight_git = "name",
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "▶", -- arrow when folder is closed
              arrow_open = "▼", -- arrow when folder is open
            },
            git = {
              ignored = "",
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
          quit_on_open = true, -- После открытия файла, закроет nvim-tree
        },
      },
      filters = {
        custom = {
          "^%.",
          "^_",
          ".gitignore",
          "package-lock.json",
          "node_modules",
          "^.git$",
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
