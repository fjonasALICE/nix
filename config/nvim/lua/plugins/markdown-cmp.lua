-- Disable completion (blink.cmp) for markdown files
return {
  "saghen/blink.cmp",
  opts = {
    enabled = function()
      -- Disable completion entirely for markdown buffers
      return vim.bo.buftype ~= "prompt" and vim.bo.filetype ~= "markdown"
    end,
  },
}
