require("mason").setup()
require("mason-lspconfig").setup {
    ensure_installed = { "html", "tsserver", "cssls", "lua_ls" },
}
