return {
  {
    'epwalsh/obsidian.nvim',
    version = '*',
    lazy = true,
    ft = 'markdown',
    dependencies = { 'nvim-lua/plenary.nvim' },

    opts = {
      workspaces = {
        {
          name = 'main',
          path = '~/Documents/cello-main/',
          overrides = {
            notes_subdir = vim.NIL,
            new_notes_location = 'current_dir',
            templates = {
              folder = 'Templates',
            },
            daily_notes = {
              folder = 'Dailies',
              date_format = '%Y-%m-%d',
              template = '6.journal-template',
            },
          },
        },
        {
          name = 'dev',
          path = '~/Documents/cello-dev-vault/',
          overrides = {
            notes_subdir = 'Notes',
            new_notes_location = 'current_dir',
            templates = {
              folder = 'Templates',
            },
            daily_notes = {
              folder = 'Daily',
              date_format = '%Y-%m-%d',
              template = 'Daily Note',
            },
          },
        },
      },

      notes_subdir = vim.NIL,
      new_notes_location = 'current_dir',

      templates = {
        folder = 'Templates',
        date_format = '%Y-%m-%d',
        time_format = '%H:%M',
        substitutions = {
          today = function()
            return os.date '%Y-%m-%d'
          end,
          tomorrow = function()
            return os.date('%Y-%m-%d', os.time() + 86400)
          end,
          yesterday = function()
            return os.date('%Y-%m-%d', os.time() - 86400)
          end,
          now = function()
            return os.date '%Y-%m-%d-%H:%M'
          end,
        },
      },

      daily_notes = {
        date_format = '%Y-%m-%d',
      },

      mappings = {
        ['<cr>'] = {
          action = function()
            return require('obsidian').util.smart_action()
          end,
          opts = { buffer = true, expr = true, desc = 'Smart task/link action' },
        },

        -- gf passthrough (your original)
        ['gf'] = {
          action = function()
            return require('obsidian').util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },

        -- toggle on this line, then go to EOL + insert
        ['<leader>ch'] = {
          action = function()
            require('obsidian').util.toggle_checkbox()
            local row = vim.api.nvim_win_get_cursor(0)[1]
            local line = vim.fn.getline(row)
            vim.api.nvim_win_set_cursor(0, { row, #line })
            vim.cmd 'startinsert'
          end,
          opts = { buffer = true, desc = 'Toggle checkbox + insert' },
        },

        -- open new line, insert checkbox, then go to EOL + insert
        ['<leader>cn'] = {
          action = function()
            local bufnr = 0
            local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
            local line = vim.fn.getline(row)
            local indent = line:match '^%s*' or ''
            local bullet = line:match '^%s*([%-%*+])%s+' or '-'
            local ck = string.format('%s%s [ ] ', indent, bullet)
            vim.api.nvim_buf_set_lines(bufnr, row, row, false, { ck })
            vim.api.nvim_win_set_cursor(0, { row + 1, #ck })
            vim.cmd 'startinsert'
          end,
          opts = { buffer = true, desc = 'New checkbox + insert' },
        },
      },

      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },
    },

    config = function(_, opts)
      -- let obsidian.nvim do its thing
      require('obsidian').setup(opts)
      require 'custom.configs.sessions'

      -- Let render-markdown.nvim handle concealment instead of managing it here
      -- your other non-Obsidian keymaps
      local km = vim.keymap.set
      km('n', '<leader>zn', vim.cmd.ObsidianSearch, { desc = 'Search / new note' })
      km('n', '<leader>zo', vim.cmd.ObsidianQuickSwitch, { desc = 'Quick switch notes' })
      km('n', '<leader>zw', vim.cmd.ObsidianWorkspace, { desc = 'Switch workspace' })
      km('n', '<leader>zc', vim.cmd.ObsidianTOC, { desc = 'Note table of contents' })
      km('n', '<leader>zL', vim.cmd.ObsidianLinks, { desc = 'List note links' })
      km('n', '<leader>zO', vim.cmd.ObsidianOpen, { desc = 'Open in Obsidian app' })
      km('v', '<leader>ze', vim.cmd.ObsidianExtractNote, { desc = 'Extract note from selection' })
      km('n', '<leader>zt', vim.cmd.ObsidianTemplate, { desc = 'Insert template' })
      km('n', '<leader>zd', vim.cmd.ObsidianToday, { desc = 'Daily note: today' })
      km('n', '<leader>zy', vim.cmd.ObsidianYesterday, { desc = 'Daily note: yesterday' })
      km('n', '<leader>zm', vim.cmd.ObsidianTomorrow, { desc = 'Daily note: tomorrow' })
      km('v', '<leader>zl', vim.cmd.ObsidianLink, { desc = 'Link selection' })
      km('n', '<leader>zb', vim.cmd.ObsidianBacklinks, { desc = 'Show backlinks' })
      km('n', '<leader>zr', '<cmd>ObsidianNewProject<CR>', { desc = 'New project note' })
      km('n', '<leader>zs', '<cmd>ObsidianNewSession<CR>', { desc = 'New session note' })
      km('n', '<leader>zx', '<cmd>ObsidianNewStep<CR>', { desc = 'New implementation step' })
    end,
  },
}
