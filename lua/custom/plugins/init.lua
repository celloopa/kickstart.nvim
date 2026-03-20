-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {
      keymaps = {
        ['o'] = {
          mode = 'n',
          desc = 'New entry below',
          callback = function()
            vim.cmd 'normal! o'
          end,
        },
        ['O'] = {
          mode = 'n',
          desc = 'New entry above',
          callback = function()
            vim.cmd 'normal! O'
          end,
        },
        ['gp'] = 'actions.preview',
        ['<C-p>'] = false,
      },
    },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '-', '<CMD>Oil<CR>', desc = 'Open parent directory' },
    },
  },
}
