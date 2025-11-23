local M = {}

local patch = require("luca.patch")

-- Apply code suggestions/patches
function M.apply_suggestion(suggestion)
  return patch.apply_suggestion(suggestion, { open_files = true })
end

function M.preview_suggestion(suggestion)
  patch.show_preview(suggestion)
end

-- Create a new file
function M.create_file(path, content)
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  
  local file = io.open(path, "w")
  if file then
    file:write(content)
    file:close()
    vim.cmd("edit " .. path)
    vim.notify("Created file: " .. path, vim.log.levels.INFO)
  else
    vim.notify("Failed to create file: " .. path, vim.log.levels.ERROR)
  end
end

-- Refactor code
function M.refactor(instructions)
  -- Send refactor request to agent
  local message = "Please refactor the following code according to these instructions: " .. instructions
  require("luca.agent").send_message(message, function(response)
    M.apply_suggestion(response)
  end)
end

-- Git operations
function M.git_commit(message)
  local cmd = string.format('git commit -m "%s"', message:gsub('"', '\\"'))
  local handle = io.popen(cmd)
  if handle then
    local output = handle:read("*all")
    handle:close()
    vim.notify("Git commit: " .. output, vim.log.levels.INFO)
  else
    vim.notify("Failed to commit", vim.log.levels.ERROR)
  end
end

function M.git_diff()
  local handle = io.popen("git diff")
  if handle then
    local diff = handle:read("*all")
    handle:close()
    
    -- Show diff in a new buffer
    local bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(bufnr, "luca-git-diff")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(diff, "\n"))
    vim.cmd("split")
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", "diff")
  end
end

-- Run tests
function M.run_tests()
  local cwd = vim.fn.getcwd()
  local test_cmd = nil
  
  -- Detect test framework
  if vim.fn.filereadable(cwd .. "/package.json") then
    test_cmd = "npm test"
  elseif vim.fn.filereadable(cwd .. "/pytest.ini") or vim.fn.filereadable(cwd .. "/pyproject.toml") then
    test_cmd = "pytest"
  elseif vim.fn.filereadable(cwd .. "/go.mod") then
    test_cmd = "go test ./..."
  end
  
  if not test_cmd then
    vim.notify("Could not detect test framework", vim.log.levels.WARN)
    return
  end
  
  -- Run tests in terminal
  vim.cmd("split")
  vim.cmd("terminal " .. test_cmd)
end

return M

