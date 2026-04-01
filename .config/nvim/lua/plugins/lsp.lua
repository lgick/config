require("mason").setup()
require("mason-lspconfig").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    "ts_ls",
    "html",
    "cssls",
    "stylua",
    "prettierd",
    "eslint-lsp",
    "lua_ls",
    "tailwindcss-language-server",
    "graphql",
    "nginx_language_server",
    "nginx-config-formatter",
    "tree-sitter-cli",
  },
  auto_update = false,
  run_on_start = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    -- === ПРЯМАЯ И ГАРАНТИРОВАННАЯ ОТПРАВКА ФАЙЛОВ В TS_LS ===
    if client and client.name == "ts_ls" then
      -- Даем серверу 2 секунды на чтение jsconfig.json
      vim.defer_fn(function()
        local gitPath = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if not gitPath or gitPath == "" or gitPath:match("fatal") then
          return
        end

        -- Получаем список файлов (только JS, исключая node_modules)
        local cmd = string.format(
          "git -C %s ls-files | grep -E '\\.(js|jsx)$' | grep -v 'node_modules' | grep -v 'dist'",
          gitPath
        )
        local files = vim.fn.systemlist(cmd)
        local count = 0

        for _, file in ipairs(files) do
          local abs_path = gitPath .. "/" .. file

          -- Проверяем, существует ли файл и можно ли его прочитать
          if vim.fn.filereadable(abs_path) == 1 then
            local uri = vim.uri_from_fname(abs_path)
            local lines = vim.fn.readfile(abs_path)
            local text = table.concat(lines, "\n")

            -- Имитируем для ts_ls открытие файла (именно так работают IDE)
            client.rpc.notify("textDocument/didOpen", {
              textDocument = {
                uri = uri,
                languageId = "javascript",
                version = 0,
                text = text,
              },
            })
            count = count + 1
          end
        end
        print("✅ УСПЕХ: В ts_ls принудительно загружено " .. count .. " файлов!")
      end, 2000)
    end

    -- твои стандартные горячие клавиши
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)

    vim.keymap.set({ "n", "x" }, "<leader>mm", function()
      require("snacks").picker.code_actions()
    end, { noremap = true, silent = true })

    vim.keymap.set("n", "<leader>ml", function()
      vim.lsp.buf.format({ timeout_ms = 10000 })
    end)

    vim.keymap.set("n", "<leader>mt", function()
      require("trouble").open("diagnostics", { fold_open = "", fold_closed = "" })
    end, opts)
  end,
})
