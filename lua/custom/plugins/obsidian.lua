local obsidian = require 'custom.configs.obsidian'

return {
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*',
    lazy = true,
    ft = 'markdown',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = obsidian.opts,
    config = obsidian.setup,
  },
}
