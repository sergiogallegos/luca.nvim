local M = {}

local chat_bufnr = nil
local chat_winid = nil
local input_bufnr = nil
local input_winid = nil

-- Track streaming state
local streaming_text = ""
local streaming_line_idx = nil

-- Track pending changes for Y/N prompt
local pending_changes_prompt = nil

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
  
  -- Settings window toggle (like ChatGPT.nvim)
  vim.api.nvim_buf_set_keymap(chat_bufnr, "n", "<C-o>", "", {
    callback = function()
      require("luca.settings").toggle()
    end,
  })
  
  -- Help window toggle (like ChatGPT.nvim)
  vim.api.nvim_buf_set_keymap(chat_bufnr, "n", "<C-h>", "", {
    callback = function()
      require("luca.help").toggle()
    end,
  })
  
  -- Session management (like ChatGPT.nvim)
  vim.api.nvim_buf_set_keymap(chat_bufnr, "n", "<C-p>", "", {
    callback = function()
      M.show_sessions_list()
    end,
  })
  
  vim.api.nvim_buf_set_keymap(chat_bufnr, "n", "<C-n>", "", {
    callback = function()
      require("luca.sessions").new_session()
      M.append_to_chat("System", "New session started")
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
  
  -- Check if we're in prompt mode and handle Y/N
  if pending_changes_prompt then
    local trimmed = message:match("^%s*(.-)%s*$")  -- Trim whitespace
    if trimmed == "Y" or trimmed == "y" or trimmed == "N" or trimmed == "n" or trimmed == "" then
      if M.handle_apply_prompt(trimmed) then
        return  -- Prompt handled, don't send as message
      end
    end
  end
  
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
  
  -- Reset streaming state
  M.reset_streaming()
  
  -- Send to agent
  require("luca.agent").send_message(message, function(response)
    -- Reset streaming state
    M.reset_streaming()
    
    -- Check if response contains code changes
    local inline_diff = require("luca.inline_diff")
    local current_file = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
    local has_changes = false
    
    if current_file and current_file ~= "" then
      if response:match("```") or response:match("^diff ") or response:match("^---") then
        has_changes = true
        -- Show inline diff
        vim.schedule(function()
          inline_diff.process_ai_response(response, current_file)
        end)
      end
    end
    
    -- Append response to chat
    M.append_to_chat("Luca", response)
    
    -- Show Y/N prompt if changes detected
    if has_changes then
      vim.schedule(function()
        M.show_apply_prompt(current_file)
      end)
    end
  end)
end

-- Throttle streaming updates to improve performance
local last_update_time = 0
local update_throttle_ms = 50  -- Update at most every 50ms

function M.stream_update(text)
  if not chat_bufnr or not vim.api.nvim_buf_is_valid(chat_bufnr) then
    return
  end
  
  -- Skip empty chunks
  if not text or text == "" then
    return
  end
  
  -- Accumulate streaming text (do this immediately, not in schedule)
  streaming_text = streaming_text .. text
  
  -- Throttle UI updates for better performance
  local current_time = vim.loop.now()
  if current_time - last_update_time < update_throttle_ms then
    return  -- Skip this update, will be handled by next one
  end
  last_update_time = current_time
  
  -- Use vim.schedule for UI updates to avoid blocking
  vim.schedule(function()
    if not chat_bufnr or not vim.api.nvim_buf_is_valid(chat_bufnr) then
      return
    end
    
    -- Get last line
    local line_count = vim.api.nvim_buf_line_count(chat_bufnr)
    local last_line = vim.api.nvim_buf_get_lines(chat_bufnr, line_count - 1, line_count, false)[1] or ""
    
    -- Check if it's a Luca message, if not, start a new one
    if not last_line:match("^🤖") or streaming_line_idx == nil then
      -- Start new Luca message
      streaming_text = text  -- Reset accumulated text
      M.append_to_chat("Luca", "")
      line_count = vim.api.nvim_buf_line_count(chat_bufnr)
      streaming_line_idx = line_count - 1
      last_line = vim.api.nvim_buf_get_lines(chat_bufnr, streaming_line_idx, streaming_line_idx + 1, false)[1] or ""
    end
    
    -- Split accumulated text by newlines to handle multi-line content properly
    local lines = vim.split(streaming_text, "\n", { plain = true })
    
    if #lines == 1 then
      -- Single line, update directly
      local updated_line = "🤖 Luca: " .. streaming_text
      vim.api.nvim_buf_set_lines(chat_bufnr, streaming_line_idx, streaming_line_idx + 1, false, { updated_line })
    else
      -- Multiple lines: update first line, then add remaining lines
      local first_line = "🤖 Luca: " .. lines[1]
      local remaining_lines = {}
      for i = 2, #lines do
        table.insert(remaining_lines, "  " .. lines[i])
      end
      
      -- Update first line
      vim.api.nvim_buf_set_lines(chat_bufnr, streaming_line_idx, streaming_line_idx + 1, false, { first_line })
      
      -- Add remaining lines if they don't exist yet
      local current_line_count = vim.api.nvim_buf_line_count(chat_bufnr)
      if current_line_count <= streaming_line_idx + 1 then
        -- Add new lines
        vim.api.nvim_buf_set_lines(chat_bufnr, streaming_line_idx + 1, streaming_line_idx + 1, false, remaining_lines)
      else
        -- Update existing lines
        local end_idx = math.min(streaming_line_idx + #remaining_lines, current_line_count - 1)
        vim.api.nvim_buf_set_lines(chat_bufnr, streaming_line_idx + 1, end_idx + 1, false, remaining_lines)
      end
    end
    
    -- Scroll to bottom
    if chat_winid and vim.api.nvim_win_is_valid(chat_winid) then
      local final_line_count = vim.api.nvim_buf_line_count(chat_bufnr)
      vim.api.nvim_win_set_cursor(chat_winid, { final_line_count, 0 })
    end
  end)
end

-- Reset streaming state (called when response is complete)
function M.reset_streaming()
  streaming_text = ""
  streaming_line_idx = nil
  last_update_time = 0
end

function M.get_chat_winid()
  return chat_winid
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

function M.show_sessions_list()
  local sessions = require("luca.sessions")
  local session_list = sessions.list_sessions()
  local current_id = sessions.get_current_session_id()
  
  if #session_list == 0 then
    vim.notify("No sessions available", vim.log.levels.WARN)
    return
  end
  
  local width = 50
  local height = #session_list + 5
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "luca-sessions")
  
  local lines = { "Sessions:", "" }
  for i, session in ipairs(session_list) do
    local marker = session.id == current_id and "✓ " or "  "
    table.insert(lines, string.format("%s%d. %s (%d messages)", marker, i, session.name, session.message_count))
  end
  table.insert(lines, "")
  table.insert(lines, "Press number to switch, n for new, q to cancel")
  
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    title = " Sessions ",
    style = "minimal",
  })
  
  -- Add keymaps
  for i = 1, #session_list do
    vim.api.nvim_buf_set_keymap(bufnr, "n", tostring(i), "", {
      callback = function()
        sessions.set_session(session_list[i].id)
        vim.api.nvim_win_close(winid, true)
        M.append_to_chat("System", "Switched to: " .. session_list[i].name)
        -- Reload session messages into chat
        M.reload_session_messages()
      end,
    })
  end
  
  vim.api.nvim_buf_set_keymap(bufnr, "n", "n", "", {
    callback = function()
      vim.api.nvim_win_close(winid, true)
      sessions.new_session()
      M.append_to_chat("System", "New session started")
    end,
  })
  
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "", {
    callback = function()
      vim.api.nvim_win_close(winid, true)
    end,
  })
end

function M.reload_session_messages()
  if not chat_bufnr or not vim.api.nvim_buf_is_valid(chat_bufnr) then
    return
  end
  
  -- Clear chat buffer
  vim.api.nvim_buf_set_lines(chat_bufnr, 0, -1, false, {})
  
  -- Load session messages
  local sessions = require("luca.sessions")
  local messages = sessions.get_messages()
  
  for _, msg in ipairs(messages) do
    if msg.role == "user" then
      M.append_to_chat("You", msg.content)
    elseif msg.role == "assistant" then
      M.append_to_chat("Luca", msg.content)
    end
  end
end

-- Show Y/N prompt for applying changes
function M.show_apply_prompt(target_file)
  if not chat_bufnr or not vim.api.nvim_buf_is_valid(chat_bufnr) then
    return
  end
  
  -- Store the target file for the prompt
  pending_changes_prompt = target_file
  
  -- Add prompt to chat
  M.append_to_chat("System", "Code changes detected. Apply changes? (Y/n): ")
  
  -- Focus input window
  if input_winid and vim.api.nvim_win_is_valid(input_winid) then
    vim.api.nvim_set_current_win(input_winid)
  end
end

-- Handle Y/N prompt response (called from send_message when prompt is active)
function M.handle_apply_prompt(choice)
  if not pending_changes_prompt then
    return false  -- Not in prompt mode
  end
  
  local inline_diff = require("luca.inline_diff")
  local bufnr = vim.fn.bufnr(pending_changes_prompt)
  
  if bufnr == -1 then
    -- File not open, open it first
    vim.cmd("edit " .. pending_changes_prompt)
    bufnr = vim.api.nvim_get_current_buf()
  end
  
  if choice == "Y" or choice == "y" or choice == "" then
    -- Accept changes (empty choice defaults to Y)
    inline_diff.accept_all_changes(bufnr)
    M.append_to_chat("System", "Changes applied ✓")
  else
    -- Reject changes
    inline_diff.reject_all_changes(bufnr)
    M.append_to_chat("System", "Changes rejected ✗")
  end
  
  -- Clear prompt state
  pending_changes_prompt = nil
  return true  -- Handled the prompt
end

return M

