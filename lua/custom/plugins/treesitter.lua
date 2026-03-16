return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      local extras = {
        'astro',
        'css',
        'elixir',
        'go',
        'javascript',
        'python',
        'typescript',
      }

      for _, parser in ipairs(extras) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end

      opts.auto_install = true
      opts.highlight = vim.tbl_deep_extend('force', opts.highlight or {}, {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      })
      opts.indent = vim.tbl_deep_extend('force', opts.indent or {}, {
        enable = true,
        disable = { 'ruby' },
      })
    end,
  },
}
