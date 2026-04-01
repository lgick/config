require("workspace-diagnostics").setup({
  workspace_files = function()
    local gitPath = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if not gitPath or gitPath == "" or gitPath:match("fatal") then
      return {}
    end

    -- Собираем только JS/TS файлы, игнорируя лишнее
    local cmd = string.format(
      "git -C %s ls-files | grep -E '\\.(js|jsx|ts|tsx)$' | grep -v 'node_modules' | grep -v 'dist'",
      gitPath
    )
    local files = vim.fn.systemlist(cmd)

    local absolute_files = {}
    for _, file in ipairs(files) do
      table.insert(absolute_files, gitPath .. "/" .. file)
    end

    return absolute_files
  end,
})
