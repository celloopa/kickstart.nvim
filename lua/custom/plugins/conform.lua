return {
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      opts.formatters_by_ft.elixir = { 'elixir-ls' }
      opts.formatters_by_ft.astro = { 'astro-ls', 'prettier' }
      opts.formatters_by_ft.php = { 'pretty-php' }
      opts.formatters_by_ft.javascript = { 'prettier', 'prettierd', stop_after_first = true }
      opts.formatters_by_ft.html = { 'html-beautifier' }
      opts.formatters_by_ft.typescript = { 'ts_standard' }
      opts.formatters_by_ft.go = { 'goimports', 'gofupmt' }
      opts.formatters_by_ft.rust = { 'rustfmt', lsp_format = 'fallback' }
      opts.formatters_by_ft.python = function(bufnr)
        if require('conform').get_formatter_info('ruff_format', bufnr).available then
          return { 'ruff_format' }
        else
          return { 'isort', 'black' }
        end
      end
    end,
  },
}
