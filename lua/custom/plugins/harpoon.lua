return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
  config = function()
    local harpoon = require 'harpoon'
    harpoon.setup {}

    -- Basic telescope configuration
    local conf = require('telescope.config').values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table {
            results = file_paths,
          },
          previewer = conf.file_previewer {},
          sorter = conf.generic_sorter {},
        })
        :find()
    end

    -- Setting a keymap to use the toggle_telescope function
    vim.keymap.set('n', '<leader>ne', function()
      toggle_telescope(harpoon:list())
    end, { desc = 'Open harpoon window' })
    vim.keymap.set('n', '<C-h>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'open deletable UI' })
    vim.keymap.set('n', '<leader>nn', function()
      harpoon:list():add()
    end, { desc = 'Add a file to harpoon' })
    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set('n', '<C-S-p>', function()
      harpoon:list():prev()
    end, { desc = 'prev harpoon buffer' })
    vim.keymap.set('n', '<C-S-N>', function()
      harpoon:list():next()
    end, { desc = 'next harpoon buffer' })
    -- Clear the Ctrl+Backspace mapping
    vim.keymap.set('n', '<C-BS>', '<Nop>', { desc = 'disabled harpoon mapping' })
  end,
}
