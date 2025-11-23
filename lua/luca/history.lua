local M = {}

local history = {}
local current_index = 0
local storage_path = nil

local function load_history()
  if not storage_path then
    return
  end
  
  local ok, data = pcall(function()
    local file = io.open(storage_path, "r")
    if not file then
      return {}
    end
    local content = file:read("*all")
    file:close()
    return vim.json.decode(content) or {}
  end)
  
  if ok then
    history = data
  else
    history = {}
  end
end

local function save_history()
  if not storage_path then
    return
  end
  
  -- Ensure directory exists
  local dir = vim.fn.fnamemodify(storage_path, ":h")
  vim.fn.mkdir(dir, "p")
  
  local ok, err = pcall(function()
    local file = io.open(storage_path, "w")
    if not file then
      return
    end
    file:write(vim.json.encode(history))
    file:close()
  end)
  
  if not ok then
    vim.notify("Failed to save history: " .. tostring(err), vim.log.levels.WARN)
  end
end

function M.setup(config)
  storage_path = config.storage_path
  if config.enabled then
    load_history()
  end
end

function M.add_entry(user_message, assistant_message)
  table.insert(history, {
    user = user_message,
    assistant = assistant_message,
    timestamp = os.time(),
  })
  
  local config = require("luca").config()
  if #history > config.history.max_entries then
    table.remove(history, 1)
  end
  
  save_history()
end

function M.get_current()
  return history
end

function M.get_entry(index)
  if index > 0 and index <= #history then
    return history[index]
  end
  return nil
end

function M.clear()
  history = {}
  save_history()
end

local history_index = 0

function M.show()
  -- Create a floating window to show history
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.7)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "luca-history")
  
  local lines = {}
  for i, entry in ipairs(history) do
    table.insert(lines, string.format("=== Entry %d ===", i))
    table.insert(lines, "You: " .. entry.user)
    table.insert(lines, "Luca: " .. entry.assistant)
    table.insert(lines, "")
  end
  
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    title = " Chat History ",
    style = "minimal",
  })
  
  vim.api.nvim_win_set_option(winid, "wrap", true)
end

function M.navigate_prev()
  if #history == 0 then
    return
  end
  history_index = math.max(1, history_index - 1)
  local entry = history[history_index]
  if entry then
    require("luca.ui").append_to_chat("You", entry.user)
    require("luca.ui").append_to_chat("Luca", entry.assistant)
  end
end

function M.navigate_next()
  if #history == 0 then
    return
  end
  history_index = math.min(#history, history_index + 1)
  local entry = history[history_index]
  if entry then
    require("luca.ui").append_to_chat("You", entry.user)
    require("luca.ui").append_to_chat("Luca", entry.assistant)
  end
end

return M

