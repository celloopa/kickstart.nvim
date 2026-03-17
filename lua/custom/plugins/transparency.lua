return {
  'xiyaowong/transparent.nvim',
  lazy = false,
  priority = 1001,
  init = function()
    vim.g.transparent_enabled = true
  end,
  opts = {
    extra_groups = {
      'NormalFloat',
      'FloatBorder',
    },
  },
}
