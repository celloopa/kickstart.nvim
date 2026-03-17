local Path = require 'plenary.path'
local M = {}

local function slugify(title)
  local slug = tostring(title or '')
  slug = vim.trim(slug):lower()
  slug = slug:gsub('[%s_]+', '-')
  slug = slug:gsub('[^%w%-]', '')
  slug = slug:gsub('%-+', '-')
  slug = slug:gsub('^%-', ''):gsub('%-$', '')

  if slug == '' then
    return 'untitled'
  end

  return slug
end

local function ensure_value(value, fallback)
  if value == nil or value == '' then
    return fallback or ''
  end
  return value
end

local function read_note(path)
  local ok, note = pcall(require('obsidian.note').from_file, tostring(path))
  if ok then
    return note
  end
end

local function current_note()
  local ok, note = pcall(require('obsidian.note').from_buffer, 0)
  if ok then
    return note
  end
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

local function workspace_templates_dir(workspace)
  if not workspace then
    return
  end

  local config = require 'obsidian.config'
  local opts = config.normalize(workspace.overrides or {}, Obsidian._opts)
  local folder = opts.templates and opts.templates.folder
  if not folder or folder == vim.NIL then
    return
  end

  local path = workspace.root / tostring(folder)
  if path:is_dir() then
    return path
  end
end

local function project_note_path(workspace, project)
  if not workspace or not project then
    return
  end

  return workspace.root / 'Projects' / (slugify(project) .. '.md')
end

local function current_project_context()
  local workspace = current_workspace()
  local note = current_note()
  local metadata = note and note.metadata or {}

  local project = metadata.project
  if type(project) ~= 'string' or project == '' then
    project = nil
  end
  if project then
    project = slugify(project)
  end

  local repo = metadata.repo
  if type(repo) ~= 'string' or repo == '' then
    repo = nil
  end

  if workspace and project and not repo then
    local path = project_note_path(workspace, project)
    if path and path:is_file() then
      local project_note = read_note(path)
      local project_meta = project_note and project_note.metadata or {}
      if type(project_meta.repo) == 'string' and project_meta.repo ~= '' then
        repo = project_meta.repo
      end
    end
  end

  return {
    workspace = workspace,
    project = project,
    project_link = project and string.format('[[Projects/%s|%s]]', project, project) or '',
    repo = repo or '',
  }
end

local WORKSPACE_CONFIG = {
  main = {
    project = {
      folder = 'Projects',
      template = 'design-project',
      file_name = function(title)
        return slugify(title) .. '.md'
      end,
      vars = function(title)
        return {
          project = title,
          start = os.date '%Y-%m-%d@%H:%M',
        }
      end,
    },
    session = {
      folder = 'Sessions',
      template = 'design-session',
      file_name = function(title)
        return string.format('%s-%s.md', slugify(title), os.date '%Y-%m-%d')
      end,
      vars = function(title)
        return {
          project = title,
          start = os.date '%Y-%m-%d@%H-%M',
        }
      end,
    },
  },
  dev = {
    project = {
      folder = 'Projects',
      template = 'Project Note',
      file_name = function(title)
        return slugify(title) .. '.md'
      end,
      vars = function(title)
        return {
          project = slugify(title),
          repo = '',
        }
      end,
    },
    session = {
      folder = 'Devlogs',
      template = 'Devlog Entry',
      file_name = function(title, context)
        local parts = { os.date '%Y-%m-%d' }
        if context.project then
          parts[#parts + 1] = context.project
        end
        parts[#parts + 1] = slugify(title)
        return table.concat(parts, '-') .. '.md'
      end,
      vars = function(_, context)
        return {
          project = ensure_value(context.project),
          repo = ensure_value(context.repo),
        }
      end,
    },
    step = {
      folder = 'Projects',
      template = 'Implementation Step',
      file_name = function(title, context)
        if context.project then
          return string.format('%s-%s.md', context.project, slugify(title))
        end
        return slugify(title) .. '.md'
      end,
      vars = function(_, context)
        return {
          project = ensure_value(context.project),
          project_link = ensure_value(context.project_link),
          repo = ensure_value(context.repo),
        }
      end,
    },
  },
}

local function current_workspace_config()
  local workspace = current_workspace()
  workspace = workspace and workspace.name or 'main'
  return WORKSPACE_CONFIG[workspace] or WORKSPACE_CONFIG.main
end

local function append_index_entry(index_path, heading, entry)
  if not index_path or not index_path:is_file() then
    return
  end

  local lines = {}
  for line in io.lines(tostring(index_path)) do
    lines[#lines + 1] = line
  end

  for _, line in ipairs(lines) do
    if line == entry then
      return
    end
  end

  local heading_line
  for i, line in ipairs(lines) do
    if line == heading then
      heading_line = i
      break
    end
  end

  if not heading_line then
    return
  end

  for i = heading_line + 1, #lines do
    if lines[i]:match '^%- Add .- here%.$' then
      table.remove(lines, i)
      break
    end
  end

  while lines[heading_line + 1] == '' do
    table.remove(lines, heading_line + 1)
  end

  local insert_at = heading_line + 1

  while insert_at <= #lines do
    if lines[insert_at]:match '^## ' then
      break
    end
    if not lines[insert_at]:match '^%- ' then
      break
    end
    insert_at = insert_at + 1
  end

  table.insert(lines, insert_at, entry)

  for i, line in ipairs(lines) do
    if line:match '^updated:%s' then
      lines[i] = 'updated: ' .. os.date '%Y-%m-%d'
      break
    end
  end

  vim.fn.writefile(lines, tostring(index_path))
end

local function open_and_fill(workspace, abs_path, template, vars)
  Path:new(abs_path):parent():mkdir { parents = true }
  vim.cmd('edit ' .. vim.fn.fnameescape(tostring(abs_path)))

  if vim.fn.line '$' == 1 and vim.fn.getline(1) == '' then
    local templates_dir = workspace_templates_dir(workspace)
    local substitutions = vim.deepcopy(Obsidian.opts.templates.substitutions or {})
    Obsidian.opts.templates.substitutions = vim.tbl_extend('force', substitutions, vars)

    local ok, err = pcall(require('obsidian.templates').insert_template, {
      type = 'insert_template',
      template_name = template,
      templates_dir = templates_dir,
      location = require('obsidian.api').get_active_window_cursor_location(),
      partial_note = require('obsidian.note').from_buffer(0),
    })
    Obsidian.opts.templates.substitutions = substitutions

    if not ok then
      vim.notify(tostring(err), vim.log.levels.WARN)
    end
  end

  return abs_path
end

local function new_note(kind, title)
  local config = current_workspace_config()[kind]
  local context = current_project_context()

  if not config then
    vim.notify("No '" .. kind .. "' note config for this workspace", vim.log.levels.WARN)
    return
  end

  local workspace = ensure_value(context.workspace, current_workspace())
  local dir = workspace.root / config.folder
  local vars = config.vars(title, context)
  vars.title = title
  local path = open_and_fill(workspace, dir / config.file_name(title, context), config.template, vars)

  if workspace.name == 'dev' then
    if kind == 'project' then
      append_index_entry(
        workspace.root / 'Projects' / 'Projects Index.md',
        '## Active',
        string.format('- [[Projects/%s|%s]]', path.stem, title)
      )
    elseif kind == 'session' then
      append_index_entry(
        workspace.root / 'Devlogs' / 'Devlog Index.md',
        '## Current month',
        string.format('- [[Devlogs/%s|%s]]', path.stem, title)
      )
    end
  end
end

function M.new_project(title)
  new_note('project', title)
end

function M.new_session(title)
  new_note('session', title)
end

function M.new_step(title)
  new_note('step', title)
end

M.slugify = slugify

vim.api.nvim_create_user_command('ObsidianNewProject', function(o)
  local title = (#o.args > 0) and o.args or vim.fn.input 'Project note title: '
  if title ~= '' then
    M.new_project(title)
  end
end, { nargs = '?' })

vim.api.nvim_create_user_command('ObsidianNewSession', function(o)
  local title = (#o.args > 0) and o.args or vim.fn.input 'Session note title: '
  if title ~= '' then
    M.new_session(title)
  end
end, { nargs = '?' })

vim.api.nvim_create_user_command('ObsidianNewStep', function(o)
  local title = (#o.args > 0) and o.args or vim.fn.input 'Implementation step title: '
  if title ~= '' then
    M.new_step(title)
  end
end, { nargs = '?' })

return M
