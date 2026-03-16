local M = {}

local function date_offset(days)
  return os.date('%Y-%m-%d', os.time() + (days * 86400))
end

local function follow_link_or_gf()
  if require('obsidian.api').cursor_link() then
    return '<cmd>Obsidian follow_link<CR>'
  end

  return 'gf'
end

local function current_workspace()
  local buf_path = vim.api.nvim_buf_get_name(0)
  if buf_path ~= '' then
    local workspace = require('obsidian.api').find_workspace(buf_path)
    if workspace then
      return workspace
    end
  end

  return Obsidian.workspace
end

local function current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
  return row, line
end

local function list_prefix(line)
  local indent, bullet = line:match('^(%s*)([-*+])%s+%[[^%]]%]%s*')
  if bullet then return indent, bullet end

  indent, bullet = line:match('^(%s*)([-*+])%s+')
  if bullet then return indent, bullet end

  return line:match('^(%s*)') or '', '-'
end

local function start_insert_at_eol(row)
  local line = vim.fn.getline(row)
  vim.api.nvim_win_set_cursor(0, { row, #line })
  vim.cmd 'startinsert'
end

function M.toggle_checkbox_and_insert()
  vim.cmd { cmd = 'Obsidian', args = { 'toggle_checkbox' } }
  local row = vim.api.nvim_win_get_cursor(0)[1]
  start_insert_at_eol(row)
end

function M.new_checkbox_below()
  local row, line = current_line()
  local indent, bullet = list_prefix(line)
  local checkbox = string.format('%s%s [ ] ', indent, bullet)

  vim.api.nvim_buf_set_lines(0, row, row, false, { checkbox })
  vim.api.nvim_win_set_cursor(0, { row + 1, #checkbox })
  vim.cmd 'startinsert'
end

function M.open_workspace_root()
  vim.cmd('Oil ' .. vim.fn.fnameescape(tostring(current_workspace().root)))
end

function M.set_note_keymaps(bufnr)
  vim.keymap.set('n', 'gf', follow_link_or_gf, {
    expr = true,
    noremap = false,
    buffer = bufnr,
    desc = 'Follow note link or use gf',
  })
  vim.keymap.set('n', '<leader>ch', M.toggle_checkbox_and_insert, {
    buffer = bufnr,
    desc = 'Toggle checkbox + insert',
  })
  vim.keymap.set('n', '<leader>cn', M.new_checkbox_below, {
    buffer = bufnr,
    desc = 'New checkbox + insert',
  })
end

function M.opts()
  return {
    legacy_commands = false,

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
          return date_offset(1)
        end,
        yesterday = function()
          return date_offset(-1)
        end,
        now = function()
          return os.date '%Y-%m-%d-%H:%M'
        end,
      },
    },

    daily_notes = {
      date_format = '%Y-%m-%d',
    },

    checkbox = {
      order = { ' ', 'x' },
      create_new = true,
    },
  }
end

function M.setup(_, opts)
  require('obsidian').setup(opts)
  require 'custom.configs.sessions'

  local group = vim.api.nvim_create_augroup('custom-obsidian', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'ObsidianNoteEnter',
    callback = function(ev)
      M.set_note_keymaps(ev.buf)
    end,
  })

  local km = vim.keymap.set
  km('n', '<leader>zn', '<cmd>Obsidian search<CR>', { desc = 'Search / new note' })
  km('n', '<leader>zo', '<cmd>Obsidian quick_switch<CR>', { desc = 'Quick switch notes' })
  km('n', '<leader>zw', '<cmd>Obsidian workspace<CR>', { desc = 'Switch workspace' })
  km('n', '<leader>zv', M.open_workspace_root, { desc = 'Browse current vault' })
  km('n', '<leader>zc', '<cmd>Obsidian toc<CR>', { desc = 'Note table of contents' })
  km('n', '<leader>zL', '<cmd>Obsidian links<CR>', { desc = 'List note links' })
  km('n', '<leader>zO', '<cmd>Obsidian open<CR>', { desc = 'Open in Obsidian app' })
  km('v', '<leader>ze', '<cmd>Obsidian extract_note<CR>', { desc = 'Extract note from selection' })
  km('n', '<leader>zt', '<cmd>Obsidian template<CR>', { desc = 'Insert template' })
  km('n', '<leader>zd', '<cmd>Obsidian today<CR>', { desc = 'Daily note: today' })
  km('n', '<leader>zy', '<cmd>Obsidian yesterday<CR>', { desc = 'Daily note: yesterday' })
  km('n', '<leader>zm', '<cmd>Obsidian tomorrow<CR>', { desc = 'Daily note: tomorrow' })
  km('v', '<leader>zl', '<cmd>Obsidian link<CR>', { desc = 'Link selection' })
  km('n', '<leader>zb', '<cmd>Obsidian backlinks<CR>', { desc = 'Show backlinks' })
  km('n', '<leader>zr', '<cmd>ObsidianNewProject<CR>', { desc = 'New project note' })
  km('n', '<leader>zs', '<cmd>ObsidianNewSession<CR>', { desc = 'New session note' })
  km('n', '<leader>zx', '<cmd>ObsidianNewStep<CR>', { desc = 'New implementation step' })
end

return M
