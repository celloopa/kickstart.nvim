-- ~/.config/nvim/lua/custom/configs/sessions.lua ------------------
local obs = require 'obsidian'
local Path = require 'plenary.path'
local M = {}

local WORKSPACE_CONFIG = {
  main = {
    project = {
      folder = 'Projects',
      template = 'design-project',
      file_name = function(title)
        return title .. '.md'
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
        return string.format('%s-%s.md', title, os.date '%Y-%m-%d')
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
        return title .. '.md'
      end,
      vars = function()
        return {}
      end,
    },
    session = {
      folder = 'Devlogs',
      template = 'Devlog Entry',
      file_name = function(title)
        return string.format('%s %s.md', os.date '%Y-%m-%d', title)
      end,
      vars = function()
        return {}
      end,
    },
    step = {
      folder = 'Projects',
      template = 'Implementation Step',
      file_name = function(title)
        return title .. '.md'
      end,
      vars = function()
        return {}
      end,
    },
  },
}

local function current_workspace_config()
  local client = obs.get_client()
  local workspace = client.current_workspace and client.current_workspace.name or 'main'
  return WORKSPACE_CONFIG[workspace] or WORKSPACE_CONFIG.main
end

local function escape_substitution(value)
  return tostring(value):gsub('\\', '\\\\'):gsub('/', '\\/'):gsub('&', '\\&')
end

-- -----------------------------------------------------------------
-- helper that inserts template & does {{…}} substitutions
local function open_and_fill(abs_path, template, vars)
  Path:new(abs_path):parent():mkdir { parents = true }
  vim.cmd('edit ' .. vim.fn.fnameescape(tostring(abs_path)))

  if vim.fn.line '$' == 1 and vim.fn.getline(1) == '' then
    -- drop the template
    local ok = pcall(vim.cmd, { cmd = 'ObsidianTemplate', args = { template } })
    if not ok then
      vim.notify("Template '" .. template .. "' not found", vim.log.levels.WARN)
    end

    -- do placeholder replacement
    for k, v in pairs(vars) do
      vim.cmd(('%%s/{{%s}}/%s/ge'):format(k, escape_substitution(v)))
    end
  end
end

-- -----------------------------------------------------------------
-- public helpers
local function new_note(kind, title)
  local client = obs.get_client()
  local config = current_workspace_config()[kind]

  if not config then
    vim.notify("No '" .. kind .. "' note config for this workspace", vim.log.levels.WARN)
    return
  end

  local dir = client.dir / config.folder
  open_and_fill(dir / config.file_name(title), config.template, config.vars(title))
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

-- -----------------------------------------------------------------
-- user commands
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
