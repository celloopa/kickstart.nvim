local obsidian = require 'custom.configs.obsidian'

return {
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*',
    lazy = true,
    ft = 'markdown',
    cmd = {
      'Obsidian',
      'ObsidianDailyAppend',
      'ObsidianTasksHere',
      'ObsidianTasksDaily',
      'ObsidianTasksVault',
      'ObsidianPropertiesHere',
      'ObsidianNewProject',
      'ObsidianNewSession',
      'ObsidianNewStep',
    },
    keys = {
      { '<leader>zn', '<cmd>Obsidian search<CR>', desc = 'Search / new note' },
      { '<leader>zo', '<cmd>Obsidian quick_switch<CR>', desc = 'Quick switch notes' },
      { '<leader>zw', '<cmd>Obsidian workspace<CR>', desc = 'Switch workspace' },
      {
        '<leader>zv',
        function()
          require('custom.configs.obsidian').open_workspace_root()
        end,
        desc = 'Browse current vault',
      },
      { '<leader>za', '<cmd>ObsidianDailyAppend<CR>', desc = 'Append to daily note' },
      { '<leader>zc', '<cmd>Obsidian toc<CR>', desc = 'Note table of contents' },
      { '<leader>zL', '<cmd>Obsidian links<CR>', desc = 'List note links' },
      { '<leader>zO', '<cmd>Obsidian open<CR>', desc = 'Open in Obsidian app' },
      { '<leader>zk', '<cmd>ObsidianTasksHere<CR>', desc = 'Show note tasks' },
      { '<leader>zK', '<cmd>ObsidianTasksDaily<CR>', desc = 'Show daily tasks' },
      { '<leader>zT', '<cmd>ObsidianTasksVault<CR>', desc = 'Show vault tasks' },
      { '<leader>zp', '<cmd>ObsidianPropertiesHere<CR>', desc = 'Show note properties' },
      {
        '<leader>zf',
        function()
          require('custom.configs.obsidian').toggle_frontmatter()
        end,
        desc = 'Toggle frontmatter fold',
      },
      { '<leader>zt', '<cmd>Obsidian template<CR>', desc = 'Insert template' },
      {
        '<leader>zd',
        function()
          require('custom.configs.obsidian').open_daily 'today'
        end,
        desc = 'Daily note: today',
      },
      {
        '<leader>zy',
        function()
          require('custom.configs.obsidian').open_daily 'yesterday'
        end,
        desc = 'Daily note: yesterday',
      },
      {
        '<leader>zm',
        function()
          require('custom.configs.obsidian').open_daily 'tomorrow'
        end,
        desc = 'Daily note: tomorrow',
      },
      { '<leader>zb', '<cmd>Obsidian backlinks<CR>', desc = 'Show backlinks' },
      { '<leader>zr', '<cmd>ObsidianNewProject<CR>', desc = 'New project note' },
      { '<leader>zs', '<cmd>ObsidianNewSession<CR>', desc = 'New session note' },
      { '<leader>zx', '<cmd>ObsidianNewStep<CR>', desc = 'New implementation step' },
      { '<leader>ze', mode = 'v', '<cmd>Obsidian extract_note<CR>', desc = 'Extract note from selection' },
      { '<leader>zl', mode = 'v', '<cmd>Obsidian link<CR>', desc = 'Link selection' },
    },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = obsidian.opts,
    config = obsidian.setup,
  },
}
