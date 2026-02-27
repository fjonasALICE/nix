-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Enable spell checking for markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
  end,
})

-- Customize spell check highlight colors (runs after colorscheme loads)
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Misspelled words: red undercurl
    vim.api.nvim_set_hl(0, "SpellBad", { undercurl = true, sp = "#ff6b6b" })
    -- Words that should be capitalized: orange undercurl
    vim.api.nvim_set_hl(0, "SpellCap", { undercurl = true, sp = "#f7b731" })
    -- Rare words: cyan undercurl
    vim.api.nvim_set_hl(0, "SpellRare", { undercurl = true, sp = "#4ecdc4" })
    -- Wrong region words: magenta undercurl
    vim.api.nvim_set_hl(0, "SpellLocal", { undercurl = true, sp = "#a55eea" })
  end,
})

-- Apply immediately for current colorscheme
vim.api.nvim_set_hl(0, "SpellBad", { undercurl = true, sp = "#ff6b6b" })

