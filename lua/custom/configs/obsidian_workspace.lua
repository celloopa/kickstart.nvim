local M = {}

local function normalize(path)
  if not path or path == '' then
    return
  end

  return vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
end

local function add_candidate(paths, seen, path)
  local normalized = normalize(path)
  if normalized and not seen[normalized] then
    seen[normalized] = true
    paths[#paths + 1] = normalized
  end
end

function M.for_path(path)
  local normalized = normalize(path)
  if not normalized then
    return
  end

  local note_workspace = require('obsidian.api').find_workspace(normalized)
  if note_workspace then
    return note_workspace
  end

  for _, workspace in ipairs(Obsidian.workspaces or {}) do
    local root = vim.fs.normalize(tostring(workspace.root))
    if normalized == root or vim.startswith(normalized, root .. '/') then
      return workspace
    end
  end
end

function M.candidates(bufnr)
  bufnr = bufnr or 0

  local paths = {}
  local seen = {}
  local buf_path = vim.api.nvim_buf_get_name(bufnr)
  add_candidate(paths, seen, buf_path)

  if vim.bo[bufnr].filetype == 'oil' then
    local ok, oil = pcall(require, 'oil')
    if ok then
      local dir = oil.get_current_dir(bufnr)
      local entry = oil.get_cursor_entry()
      if dir and entry then
        add_candidate(paths, seen, vim.fs.joinpath(dir, entry.name))
      end
      add_candidate(paths, seen, dir)
    end
  end

  add_candidate(paths, seen, vim.fn.getcwd())

  return paths
end

function M.current(bufnr)
  for _, path in ipairs(M.candidates(bufnr)) do
    local workspace = M.for_path(path)
    if workspace then
      return workspace
    end
  end

  return Obsidian.workspace
end

function M.sync(bufnr)
  local workspace = M.current(bufnr)
  if workspace and Obsidian.workspace ~= workspace then
    require('obsidian.workspace').set(workspace)
  end

  return workspace
end

return M
