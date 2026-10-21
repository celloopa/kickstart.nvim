local M = {}
local workspace = require 'custom.configs.obsidian_workspace'

local function date_offset(days)
  return os.date('%Y-%m-%d', os.time() + (days * 86400))
end

local function template_timestamp(ctx)
  local path
  if ctx and ctx.destination_path then
    path = tostring(ctx.destination_path)
  else
    path = vim.api.nvim_buf_get_name(0)
  end

  local year, month, day = tostring(path):match('(%d%d%d%d)%-(%d%d)%-(%d%d)')
  if year and month and day then
    return os.time {
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = 12,
    }
  end

  return os.time()
end

local function week_start_timestamp(ctx)
  local timestamp = template_timestamp(ctx)
  local weekday = tonumber(os.date('%w', timestamp))
  local days_since_monday = (weekday + 6) % 7

  return timestamp - (days_since_monday * 86400)
end

local function week_start_date(timestamp)
  local weekday = tonumber(os.date('%w', timestamp))
  local days_since_monday = (weekday + 6) % 7

  return os.date('%Y-%m-%d', timestamp - (days_since_monday * 86400))
end

local function daily_dir(ctx)
  if ctx and ctx.destination_path then
    local path = vim.fs.normalize(vim.fn.fnamemodify(tostring(ctx.destination_path), ':p'))
    local dir = vim.fs.dirname(path)
    if dir then
      return dir
    end
  end

  local current = workspace.current(0)
  if current then
    local opts = current.opts or Obsidian.opts
    local folder = opts.daily_notes and opts.daily_notes.folder or Obsidian.opts.daily_notes.folder
    if folder then
      return vim.fs.normalize(tostring(current.root / folder))
    end
  end
end

local function date_from_daily_path(path)
  local year, month, day = vim.fs.basename(path):match('^(%d%d%d%d)%-(%d%d)%-(%d%d)%.md$')
  if not year then
    return
  end

  return string.format('%s-%s-%s', year, month, day),
    os.time {
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = 12,
    }
end

local function section_lines(path, heading_pattern)
  local lines = vim.fn.readfile(path)
  local start_idx

  for idx, line in ipairs(lines) do
    if line:match(heading_pattern) then
      start_idx = idx + 1
      break
    end
  end

  if not start_idx then
    return
  end

  local result = {}
  for idx = start_idx, #lines do
    local line = lines[idx]
    if line:match '^##%s+' then
      break
    end
    result[#result + 1] = line
  end

  while result[1] == '' do
    table.remove(result, 1)
  end
  while result[#result] == '' do
    table.remove(result)
  end

  if #result == 0 then
    return
  end

  return table.concat(result, '\n')
end

local function persisted_daily_section(ctx, same_period, heading_pattern)
  local dir = daily_dir(ctx)
  if not dir or vim.fn.isdirectory(dir) == 0 then
    return '- [ ] '
  end

  local target_date = os.date('%Y-%m-%d', template_timestamp(ctx))
  local latest_date
  local latest_path

  for name, type_name in vim.fs.dir(dir) do
    if type_name == 'file' then
      local path = vim.fs.joinpath(dir, name)
      local date, timestamp = date_from_daily_path(path)
      if date and date < target_date and same_period(timestamp) and (not latest_date or date > latest_date) then
        latest_date = date
        latest_path = path
      end
    end
  end

  if not latest_path then
    return '- [ ] '
  end

  return section_lines(latest_path, heading_pattern) or '- [ ] '
end

local function persisted_week_section(ctx)
  local week_start = os.date('%Y-%m-%d', week_start_timestamp(ctx))

  return persisted_daily_section(ctx, function(timestamp)
    return week_start_date(timestamp) == week_start
  end, '^##%s+Week')
end

local function persisted_month_section(ctx)
  local month = os.date('%Y-%m', template_timestamp(ctx))

  return persisted_daily_section(ctx, function(timestamp)
    return os.date('%Y-%m', timestamp) == month
  end, '^##%s+%a+%s+%d%d%d%d$')
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
  vim.cmd 'startinsert!'
end

function M.wrap_visual_in_code_block(lang)
  local start_row = vim.fn.line "'<"
  local end_row = vim.fn.line "'>"

  lang = lang or prompt_language()

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

function M.apply_note_buffer(bufnr)
  bufnr = bufnr or 0

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local filetype = vim.bo[bufnr].filetype
  if filetype ~= 'markdown' and filetype ~= 'quarto' then
    return
  end

  local current_workspace = workspace.sync(bufnr)
  if not current_workspace then
    return
  end

  M.set_note_window_options(bufnr)
  M.set_note_keymaps(bufnr)
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
        date = function(ctx, suffix)
          return os.date(suffix or Obsidian.opts.templates.date_format, template_timestamp(ctx))
        end,
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
        week = function(ctx)
          return os.date('%G-W%V', template_timestamp(ctx))
        end,
        week_start = function(ctx)
          return os.date('%Y-%m-%d', week_start_timestamp(ctx))
        end,
        month = function(ctx)
          return os.date('%Y-%m', template_timestamp(ctx))
        end,
        month_name = function(ctx)
          return os.date('%B %Y', template_timestamp(ctx))
        end,
        week_persist = persisted_week_section,
        month_persist = persisted_month_section,
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
      M.apply_note_buffer(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'ObsidianNoteEnter',
    callback = function(ev)
      M.apply_note_buffer(ev.buf)
    end,
  })

  vim.schedule(function()
    M.apply_note_buffer(0)
  end)

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
