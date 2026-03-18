local M = {}
local workspace = require 'custom.configs.obsidian_workspace'

local function date_offset(days)
  return os.date('%Y-%m-%d', os.time() + (days * 86400))
end

local function follow_link_or_gf()
  if require('obsidian.api').cursor_link() then
    return '<cmd>Obsidian follow_link<CR>'
  end

  return 'gf'
end

local function frontmatter_end(bufnr)
  bufnr = bufnr or 0
  if vim.api.nvim_buf_line_count(bufnr) < 2 then
    return
  end

  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
  if first ~= '---' then
    return
  end

  local max_lines = math.min(vim.api.nvim_buf_line_count(bufnr), 80)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 1, max_lines, false)
  for i, line in ipairs(lines) do
    if line == '---' or line == '...' then
      return i + 1
    end
  end
end

function M.frontmatter_foldexpr(lnum)
  local end_line = vim.b.obsidian_frontmatter_end
  if not end_line then
    return '0'
  end

  if lnum == 1 then
    return '>1'
  end
  if lnum < end_line then
    return '1'
  end
  if lnum == end_line then
    return '<1'
  end

  return '0'
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

local function prompt_language(default)
  local lang = vim.fn.input('Code block language: ', default or '')
  return vim.trim(lang)
end

function M.toggle_checkbox()
  vim.cmd { cmd = 'Obsidian', args = { 'toggle_checkbox' } }
end

function M.new_checkbox_below()
  local row, line = current_line()
  local indent, bullet = list_prefix(line)
  local checkbox = string.format('%s%s [ ] ', indent, bullet)

  vim.api.nvim_buf_set_lines(0, row, row, false, { checkbox })
  vim.api.nvim_win_set_cursor(0, { row + 1, #checkbox })
  vim.cmd 'startinsert'
end

function M.wrap_visual_in_code_block(lang)
  lang = lang or prompt_language()
  local start_row = vim.fn.line "'<"
  local end_row = vim.fn.line "'>"

  if start_row == 0 or end_row == 0 then
    return
  end

  if start_row > end_row then
    start_row, end_row = end_row, start_row
  end

  vim.api.nvim_buf_set_lines(0, end_row, end_row, false, { '```' })
  vim.api.nvim_buf_set_lines(0, start_row - 1, start_row - 1, false, { '```' .. lang })
  vim.api.nvim_win_set_cursor(0, { start_row, 0 })
end

function M.new_code_block(lang)
  lang = lang or prompt_language()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = { '```' .. lang, '', '```' }

  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
  vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
  vim.cmd 'startinsert'
end

function M.open_workspace_root()
  local current = workspace.sync(0)
  if not current then
    vim.notify('No Obsidian workspace found from the current buffer, Oil entry, or cwd', vim.log.levels.WARN)
    return
  end

  vim.cmd('Oil ' .. vim.fn.fnameescape(tostring(current.root)))
end

function M.open_daily(which)
  local current = workspace.sync(0)
  if not current then
    vim.notify('No Obsidian workspace found from the current buffer, Oil entry, or cwd', vim.log.levels.WARN)
    return
  end

  vim.cmd { cmd = 'Obsidian', args = { which } }
end

function M.toggle_frontmatter()
  if not vim.b.obsidian_frontmatter_end then
    vim.notify('No frontmatter in this note', vim.log.levels.INFO)
    return
  end

  local view = vim.fn.winsaveview()
  local was_closed = vim.fn.foldclosed(1) ~= -1
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  if was_closed then
    vim.cmd 'silent! normal! zo'
    vim.b.obsidian_frontmatter_hidden = false
  else
    vim.cmd 'silent! normal! zc'
    vim.b.obsidian_frontmatter_hidden = true
  end
  vim.fn.winrestview(view)
end

function M.set_note_keymaps(bufnr)
  vim.keymap.set('n', 'gf', follow_link_or_gf, {
    expr = true,
    noremap = false,
    buffer = bufnr,
    desc = 'Follow note link or use gf',
  })
  vim.keymap.set('n', '<leader>ch', M.toggle_checkbox, {
    buffer = bufnr,
    desc = 'Toggle checkbox',
  })
  vim.keymap.set('x', '<leader>ch', [[:<C-u>'<,'>Obsidian toggle_checkbox<CR>gv]], {
    buffer = bufnr,
    silent = true,
    desc = 'Toggle checkbox',
  })
  vim.keymap.set('n', '<leader>cn', M.new_checkbox_below, {
    buffer = bufnr,
    desc = 'New checkbox + insert',
  })
  vim.keymap.set('x', '<leader>cd', function()
    M.wrap_visual_in_code_block()
  end, {
    buffer = bufnr,
    desc = 'Wrap selection in code block',
  })
  vim.keymap.set('n', '<leader>cc', function()
    M.new_code_block()
  end, {
    buffer = bufnr,
    desc = 'New code block + insert',
  })
end

function M.set_note_window_options(bufnr)
  bufnr = bufnr or 0
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = 'nc'

  local fm_end = frontmatter_end(bufnr)
  vim.b[bufnr].obsidian_frontmatter_end = fm_end

  if fm_end then
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = "v:lua.require'custom.configs.obsidian'.frontmatter_foldexpr(v:lnum)"
    vim.wo.foldenable = true
    vim.wo.foldlevel = 0

    if vim.b[bufnr].obsidian_frontmatter_hidden ~= false then
      vim.schedule(function()
        if vim.api.nvim_get_current_buf() == bufnr then
          vim.cmd 'silent! normal! zM'
        end
      end)
    end
  else
    vim.wo.foldexpr = '0'
    vim.wo.foldmethod = 'manual'
    vim.wo.foldenable = false
  end
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
  require('custom.configs.obsidian_cli').setup()

  local group = vim.api.nvim_create_augroup('custom-obsidian', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = { 'markdown', 'quarto' },
    callback = function(ev)
      local buf_path = vim.api.nvim_buf_get_name(ev.buf)
      if buf_path ~= '' and require('obsidian.api').find_workspace(buf_path) then
        workspace.sync(ev.buf)
        M.set_note_window_options(ev.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'ObsidianNoteEnter',
    callback = function(ev)
      workspace.sync(ev.buf)
      M.set_note_window_options(ev.buf)
      M.set_note_keymaps(ev.buf)
    end,
  })

  local km = vim.keymap.set
  km('n', '<leader>zn', '<cmd>Obsidian search<CR>', { desc = 'Search / new note' })
  km('n', '<leader>zo', '<cmd>Obsidian quick_switch<CR>', { desc = 'Quick switch notes' })
  km('n', '<leader>zw', '<cmd>Obsidian workspace<CR>', { desc = 'Switch workspace' })
  km('n', '<leader>zv', M.open_workspace_root, { desc = 'Browse current vault' })
  km('n', '<leader>za', '<cmd>ObsidianDailyAppend<CR>', { desc = 'Append to daily note' })
  km('n', '<leader>zc', '<cmd>Obsidian toc<CR>', { desc = 'Note table of contents' })
  km('n', '<leader>zL', '<cmd>Obsidian links<CR>', { desc = 'List note links' })
  km('n', '<leader>zO', '<cmd>Obsidian open<CR>', { desc = 'Open in Obsidian app' })
  km('n', '<leader>zk', '<cmd>ObsidianTasksHere<CR>', { desc = 'Show note tasks' })
  km('n', '<leader>zK', '<cmd>ObsidianTasksDaily<CR>', { desc = 'Show daily tasks' })
  km('n', '<leader>zT', '<cmd>ObsidianTasksVault<CR>', { desc = 'Show vault tasks' })
  km('n', '<leader>zp', '<cmd>ObsidianPropertiesHere<CR>', { desc = 'Show note properties' })
  km('v', '<leader>ze', '<cmd>Obsidian extract_note<CR>', { desc = 'Extract note from selection' })
  km('n', '<leader>zf', M.toggle_frontmatter, { desc = 'Toggle frontmatter fold' })
  km('n', '<leader>zt', '<cmd>Obsidian template<CR>', { desc = 'Insert template' })
  km('n', '<leader>zd', function()
    M.open_daily 'today'
  end, { desc = 'Daily note: today' })
  km('n', '<leader>zy', function()
    M.open_daily 'yesterday'
  end, { desc = 'Daily note: yesterday' })
  km('n', '<leader>zm', function()
    M.open_daily 'tomorrow'
  end, { desc = 'Daily note: tomorrow' })
  km('v', '<leader>zl', '<cmd>Obsidian link<CR>', { desc = 'Link selection' })
  km('n', '<leader>zb', '<cmd>Obsidian backlinks<CR>', { desc = 'Show backlinks' })
  km('n', '<leader>zr', '<cmd>ObsidianNewProject<CR>', { desc = 'New project note' })
  km('n', '<leader>zs', '<cmd>ObsidianNewSession<CR>', { desc = 'New session note' })
  km('n', '<leader>zx', '<cmd>ObsidianNewStep<CR>', { desc = 'New implementation step' })
end

return M
