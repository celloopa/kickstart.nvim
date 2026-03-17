local M = {}
local workspace = require 'custom.configs.obsidian_workspace'

local function cli_executable()
  if type(vim.g.obsidian_cli_cmd) == 'string' and vim.g.obsidian_cli_cmd ~= '' then
    return vim.g.obsidian_cli_cmd
  end

  local exepath = vim.fn.exepath 'obsidian'
  if exepath ~= '' then
    return exepath
  end

  for _, path in ipairs {
    '/Applications/Obsidian.app/Contents/MacOS/obsidian',
    '/opt/homebrew/bin/obsidian',
    '/usr/local/bin/obsidian',
    vim.fn.expand '~/.local/bin/obsidian',
  } do
    if vim.uv.fs_stat(path) then
      return path
    end
  end
end

local function current_note_path()
  local current = workspace.current(0)
  local buf_path = vim.api.nvim_buf_get_name(0)
  if not current or buf_path == '' then
    return
  end

  local prefix = tostring(current.root) .. '/'
  if not vim.startswith(buf_path, prefix) then
    return
  end

  return buf_path:sub(#prefix + 1)
end

local function clean_output(text)
  local lines = vim.split(text or '', '\n', { plain = true, trimempty = false })
  local cleaned = {}

  for _, line in ipairs(lines) do
    if line ~= '' and not line:match '^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d Loading updated app package ' and not line:match '^Your Obsidian installer is out of date' then
      cleaned[#cleaned + 1] = line
    end
  end

  return cleaned
end

local function open_scratch(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, title)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'markdown'
end

local function run_cli(args, opts)
  opts = opts or {}
  local executable = cli_executable()
  if not executable then
    vim.notify('Obsidian CLI not found. Set vim.g.obsidian_cli_cmd to the full binary path.', vim.log.levels.ERROR)
    return
  end

  local cmd = vim.list_extend({ executable }, args)
  local result = vim.system(cmd, { text = true, cwd = opts.cwd }):wait()
  local output = clean_output((result.stdout or '') .. '\n' .. (result.stderr or ''))

  if result.code ~= 0 then
    vim.notify(table.concat(output, '\n'), vim.log.levels.ERROR)
    return
  end

  return output
end

function M.daily_append(input)
  local current = workspace.sync(0)
  if not current then
    vim.notify('No active Obsidian workspace', vim.log.levels.WARN)
    return
  end

  local content = input
  if not content or content == '' then
    content = vim.fn.input 'Daily capture: '
  end
  if content == '' then
    return
  end

  if not content:match '^%s*[-*+]' then
    content = '- ' .. content
  end

  local output = run_cli({ 'daily:append', 'content=' .. content }, { cwd = tostring(current.root) })
  if output then
    vim.notify('Appended to daily note', vim.log.levels.INFO)
  end
end

function M.show_tasks(mode)
  local current = workspace.sync(0)
  if not current then
    vim.notify('No active Obsidian workspace', vim.log.levels.WARN)
    return
  end

  local args = { 'tasks', 'verbose' }
  if mode == 'daily' then
    args[#args + 1] = 'daily'
    args[#args + 1] = 'todo'
  elseif mode == 'vault' then
    args[#args + 1] = 'todo'
  else
    local path = current_note_path()
    if path then
      args[#args + 1] = 'path=' .. path
    else
      args[#args + 1] = 'todo'
    end
  end

  local output = run_cli(args, { cwd = tostring(current.root) })
  if output then
    open_scratch('obsidian://tasks', output)
  end
end

function M.show_properties()
  local current = workspace.sync(0)
  local path = current_note_path()
  if not current or not path then
    vim.notify('Open an Obsidian note first', vim.log.levels.WARN)
    return
  end

  local output = run_cli({ 'properties', 'path=' .. path }, { cwd = tostring(current.root) })
  if output then
    open_scratch('obsidian://properties', output)
  end
end

function M.setup()
  vim.api.nvim_create_user_command('ObsidianDailyAppend', function(o)
    M.daily_append(o.args)
  end, { nargs = '?' })

  vim.api.nvim_create_user_command('ObsidianTasksHere', function()
    M.show_tasks 'note'
  end, {})

  vim.api.nvim_create_user_command('ObsidianTasksDaily', function()
    M.show_tasks 'daily'
  end, {})

  vim.api.nvim_create_user_command('ObsidianTasksVault', function()
    M.show_tasks 'vault'
  end, {})

  vim.api.nvim_create_user_command('ObsidianPropertiesHere', function()
    M.show_properties()
  end, {})
end

return M
