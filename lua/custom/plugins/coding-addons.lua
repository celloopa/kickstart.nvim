return {
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    init = function()
      vim.keymap.set('n', '<leader>ee', 'oif err != nil {<CR>}<Esc>Oreturn err<Esc>', {
        noremap = true,
        desc = 'Go [E][E]rrors',
      })
    end,
    opts = {},
  },
  {
    'wuelnerdotexe/vim-astro',
    init = function()
      vim.g.astro_typescript = 'enable'
      vim.g.astro_stylus = 'enable'
    end,
  },
  {
    'rafamadriz/friendly-snippets',
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load()
      require('luasnip.loaders.from_vscode').lazy_load { paths = { vim.fn.stdpath 'config' .. '/snippets' } }
      require('luasnip').filetype_extend('astro', { 'typescript', 'html' })
    end,
  },
  {
    'virchau13/tree-sitter-astro',
  },
  {
    'tversteeg/registers.nvim',
    cmd = 'Registers',
    config = true,
    keys = {
      { '"', mode = { 'n', 'v' } },
      { '<C-R>', mode = 'i' },
      { '<leader>rg', '<cmd>Registers<CR>', desc = '[R]e[G]isters' },
    },
    name = 'registers',
  },
  {
    'luckasRanarison/tailwind-tools.nvim',
    name = 'tailwind-tools',
    enabled = false,
    build = ':UpdateRemotePlugins',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-telescope/telescope.nvim', -- optional
      'neovim/nvim-lspconfig', -- optional
    },
    opts = {}, -- your configuration
  },
}
