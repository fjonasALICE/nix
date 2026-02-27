return {
  "jghauser/follow-md-links.nvim",
  ft = "markdown",
  config = function()
    -- The plugin automatically maps <cr> in normal mode to follow links
    -- Optionally add backspace to go back to previous file
    vim.keymap.set("n", "<bs>", ":edit #<cr>", { silent = true, desc = "Go back to previous file" })
  end,
}

