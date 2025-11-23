local M = {}

local chat_bufnr = nil
local chat_winid = nil
local input_bufnr = nil
local input_winid = nil

local window = require("luca.window")
local theme = require("luca.theme")
local modes = require("luca.modes")

local function create_floating_window(config)
  -- Adapt border based on theme
  local adapted_border = theme.adapt_border(config)
  
  local width = math.floor(vim.o.columns * config.width)
  local input_height = 3  -- Fixed small height for input
  
  -- Calculate positions and chat height
  local col = 0
  local chat_row = 0
  local input_row = 0
  local chat_height = 0
  
  if config.position == "right" then
    col = vim.o.columns - width - 2  -- Position on right side
    chat_row = 2  -- Start near top
    -- Move input window up to avoid statusline (leave ~3 lines for statusline)
    input_row = vim.o.lines - input_height - 3  -- Up from bottom to avoid statusline
    -- Calculate chat height to fill space between top and input, with small gap
    local gap = 2  -- Small gap between chat and input windows
    local max_chat_height = input_row - chat_row - gap
    local desired_chat_height = math.floor(vim.o.lines * config.height)
    -- Use the maximum available height (fill space down to input window)
    chat_height = math.min(desired_chat_height, max_chat_height)
    -- But ensure we use most of the available space
    chat_height = math.max(chat_height, max_chat_height - 2)  -- Use almost all space, leave small gap
    -- Ensure minimum height for usability
    chat_height = math.max(chat_height, 10)
  elseif config.position == "center" then
    col = math.floor((vim.o.columns - width) / 2)
    chat_height = math.floor(vim.o.lines * config.height)
    chat_row = math.floor((vim.o.lines - chat_height - input_height) / 2)
    input_row = chat_row + chat_height
  elseif config.position == "top" then
    col = math.floor((vim.o.columns - width) / 2)
    chat_height = math.floor(vim.o.lines * config.height)
    chat_row = 1
    input_row = chat_row + chat_height
  elseif config.position == "bottom" then
    col = math.floor((vim.o.columns - width) / 2)
    chat_height = math.floor(vim.o.lines * config.height)
    input_row = vim.o.lines - input_height - 1
    chat_row = input_row - chat_height
  elseif config.position == "left" then
    col = 2  -- Position on left side
    chat_height = math.floor(vim.o.lines * config.height)
    chat_row = math.floor((vim.o.lines - chat_height - input_height) / 2)
    input_row = chat_row + chat_height
  end
  
  -- Create chat buffer (check if it exists first and delete it)
  local existing_chat_buf = vim.fn.bufnr("luca-chat")
  if existing_chat_buf ~= -1 and vim.api.nvim_buf_is_valid(existing_chat_buf) then
    vim.api.nvim_buf_delete(existing_chat_buf, { force = true })
  end
  
  chat_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(chat_bufnr, "luca-chat")
  vim.api.nvim_buf_set_option(chat_bufnr, "filetype", "luca-chat")
  vim.api.nvim_buf_set_option(chat_bufnr, "buftype", "nofile")
  
  -- Create chat window using window manager
  chat_winid = window.create_resizable_window(config, chat_bufnr, {
    width = width,
    height = chat_height,
    col = col,
    row = chat_row,
    border = adapted_border,
    title = config.title,
    winblend = config.winblend,
    resizable = true,
  })
  
  -- Configure chat window
  vim.api.nvim_win_set_option(chat_winid, "wrap", true)
  vim.api.nvim_win_set_option(chat_winid, "number", false)
  vim.api.nvim_win_set_option(chat_winid, "relativenumber", false)
  vim.api.nvim_win_set_option(chat_winid, "cursorline", false)
  
  -- Create input buffer (check if it exists first and delete it)
  local existing_input_buf = vim.fn.bufnr("luca-input")
  if existing_input_buf ~= -1 and vim.api.nvim_buf_is_valid(existing_input_buf) then
    vim.api.nvim_buf_delete(existing_input_buf, { force = true })
  end
  
  input_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(input_bufnr, "luca-input")
  vim.api.nvim_buf_set_option(input_bufnr, "filetype", "luca-input")
  vim.api.nvim_buf_set_option(input_bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(input_bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(input_bufnr, "swapfile", false)
  
  -- Suppress write errors for this buffer
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = input_bufnr,
    callback = function()
      -- Silently ignore write attempts
    end,
  })
  
  -- Create input window (positioned right below chat window)
  input_winid = vim.api.nvim_open_win(input_bufnr, false, {
    relative = "editor",
    width = width,
    height = input_height,
    col = col,
    row = input_row,
    border = adapted_border,
    title = " Input ",
    style = "minimal",
  })
  
  -- Set winblend option after window creation
  if config.winblend then
    vim.api.nvim_win_set_option(input_winid, "winblend", config.winblend)
  end
  
  -- Configure input window
  vim.api.nvim_win_set_option(input_winid, "wrap", true)
  
  -- Set keymaps
  local luca_config = require("luca").config()
  vim.api.nvim_buf_set_keymap(input_bufnr, "i", luca_config.keymaps.send, "", {
    callback = function()
      M.send_message()
    end,
  })
  
  vim.api.nvim_buf_set_keymap(input_bufnr, "n", luca_config.keymaps.close, "", {
    callback = function()
      M.close()
    end,
  })
  
  -- Also close with Esc
  vim.api.nvim_buf_set_keymap(input_bufnr, "n", "<Esc>", "", {
    callback = function()
      M.close()
    end,
  })
  
  -- Close chat window with Esc too
  vim.api.nvim_buf_set_keymap(chat_bufnr, "n", "<Esc>", "", {
    callback = function()
      M.close()
    end,
  })
  
  -- Add keymaps for chat buffer
  vim.api.nvim_buf_set_keymap(chat_bufnr, "n", "<C-a>", "", {
    callback = function()
      M.show_agent_selector()
    end,
  })
  
  vim.api.nvim_buf_set_keymap(chat_bufnr, "n", luca_config.keymaps.history_prev, "", {
    callback = function()
      require("luca.history").navigate_prev()
    end,
  })
  
  vim.api.nvim_buf_set_keymap(chat_bufnr, "n", luca_config.keymaps.history_next, "", {
    callback = function()
      require("luca.history").navigate_next()
    end,
  })
  
  -- Focus input window
  vim.api.nvim_set_current_win(input_winid)
end

function M.setup(config)
  -- Store config for later use
  M.config = config
end

function M.toggle()
  -- Toggle chat window
  if chat_winid and vim.api.nvim_win_is_valid(chat_winid) then
    M.close()
  else
    M.open()
  end
end

function M.open()
  local luca_config = require("luca").config()
  local current_mode = modes.get_mode()
  
  -- Check if already open - if so, just focus input
  if chat_winid and vim.api.nvim_win_is_valid(chat_winid) then
    if input_winid and vim.api.nvim_win_is_valid(input_winid) then
      vim.api.nvim_set_current_win(input_winid)
    end
    return
  end
  
  -- Create window based on mode
  if current_mode == "sidebar" then
    chat_winid, chat_bufnr = modes.create_sidebar(luca_config.ui)
    -- Create input in sidebar
    input_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(input_bufnr, "filetype", "luca-input")
    -- Input handling would be different for sidebar
  elseif current_mode == "minimal" then
    chat_winid, chat_bufnr = modes.create_minimal_window(luca_config.ui)
    input_bufnr = chat_bufnr
  else
    -- Default floating mode
    create_floating_window(luca_config.ui)
  end
  
  -- Initialize chat with welcome message and current agent info
  local agent = require("luca.agent")
  local current_agent = agent.get_current_agent()
  M.append_to_chat("Luca", "Hello! How can I help you today?")
  M.append_to_chat("System", "Current agent: " .. current_agent .. " (Press <C-a> to switch)")
end

function M.close()
  -- Close windows first
  if chat_winid and vim.api.nvim_win_is_valid(chat_winid) then
    vim.api.nvim_win_close(chat_winid, true)
  end
  if input_winid and vim.api.nvim_win_is_valid(input_winid) then
    vim.api.nvim_win_close(input_winid, true)
  end
  
  -- Delete buffers to prevent "buffer already exists" error
  if chat_bufnr and vim.api.nvim_buf_is_valid(chat_bufnr) then
    vim.api.nvim_buf_delete(chat_bufnr, { force = true })
  end
  if input_bufnr and vim.api.nvim_buf_is_valid(input_bufnr) then
    vim.api.nvim_buf_delete(input_bufnr, { force = true })
  end
  
  -- Clear references
  chat_bufnr = nil
  chat_winid = nil
  input_bufnr = nil
  input_winid = nil
end

function M.append_to_chat(sender, message)
  if not chat_bufnr or not vim.api.nvim_buf_is_valid(chat_bufnr) then
    return
  end
  
  local lines = vim.split(message, "\n")
  local prefix = sender == "Luca" and "🤖 " or "👤 "
  local formatted_lines = { prefix .. sender .. ": " .. lines[1] }
  
  for i = 2, #lines do
    table.insert(formatted_lines, "  " .. lines[i])
  end
  
  vim.api.nvim_buf_set_lines(chat_bufnr, -1, -1, false, formatted_lines)
  vim.api.nvim_buf_set_lines(chat_bufnr, -1, -1, false, { "" })
  
  -- Scroll to bottom
  if chat_winid and vim.api.nvim_win_is_valid(chat_winid) then
    local line_count = vim.api.nvim_buf_line_count(chat_bufnr)
    vim.api.nvim_win_set_cursor(chat_winid, { line_count, 0 })
  end
end

function M.get_input()
  if not input_bufnr or not vim.api.nvim_buf_is_valid(input_bufnr) then
    return ""
  end
  
  local lines = vim.api.nvim_buf_get_lines(input_bufnr, 0, -1, false)
  local text = table.concat(lines, "\n")
  
  -- Clear input
  vim.api.nvim_buf_set_lines(input_bufnr, 0, -1, false, { "" })
  
  return text
end

function M.send_message()
  local message = M.get_input()
  if message == "" or message == "\n" then
    return
  end
  
  -- Check for command palette commands
  local commands = require("luca.commands")
  if commands.handle_command(message) then
    return
  end
  
  -- Add user message to chat
  M.append_to_chat("You", message)
  
  -- Send to agent
  require("luca.agent").send_message(message, function(response)
    M.append_to_chat("Luca", response)
  end)
end

function M.stream_update(text)
  if not chat_bufnr or not vim.api.nvim_buf_is_valid(chat_bufnr) then
    return
  end
  
  -- Get last line
  local line_count = vim.api.nvim_buf_line_count(chat_bufnr)
  local last_line = vim.api.nvim_buf_get_lines(chat_bufnr, line_count - 1, line_count, false)[1] or ""
  
  -- Check if it's a Luca message
  if not last_line:match("^🤖") then
    M.append_to_chat("Luca", "")
    line_count = vim.api.nvim_buf_line_count(chat_bufnr)
    last_line = vim.api.nvim_buf_get_lines(chat_bufnr, line_count - 1, line_count, false)[1] or ""
  end
  
  -- Update last line with streaming text
  local updated_line = last_line:gsub("🤖 Luca: .*", "🤖 Luca: " .. text)
  vim.api.nvim_buf_set_lines(chat_bufnr, line_count - 1, line_count, false, { updated_line })
  
  -- Scroll to bottom
  if chat_winid and vim.api.nvim_win_is_valid(chat_winid) then
    vim.api.nvim_win_set_cursor(chat_winid, { line_count, 0 })
  end
end

function M.show_agent_selector()
  local agent = require("luca.agent")
  local agents = agent.list_agents()
  local current = agent.get_current_agent()
  
  if #agents == 0 then
    vim.notify("No agents configured", vim.log.levels.WARN)
    return
  end
  
  -- Create selector window
  local width = 40
  local height = #agents + 4
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "luca-agent-selector")
  
  local lines = { "Select Agent:", "" }
  for i, name in ipairs(agents) do
    local marker = name == current and "✓ " or "  "
    table.insert(lines, marker .. name)
  end
  table.insert(lines, "")
  table.insert(lines, "Press number to select, q to cancel")
  
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    title = " Select Agent ",
    style = "minimal",
  })
  
  -- Add keymaps
  for i = 1, #agents do
    vim.api.nvim_buf_set_keymap(bufnr, "n", tostring(i), "", {
      callback = function()
        agent.set_agent(agents[i])
        vim.api.nvim_win_close(winid, true)
        M.append_to_chat("System", "Switched to agent: " .. agents[i])
      end,
    })
  end
  
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "", {
    callback = function()
      vim.api.nvim_win_close(winid, true)
    end,
  })
end

return M

