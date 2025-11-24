local M = {}

-- Settings Window - Toggle settings like ChatGPT.nvim

local settings_winid = nil
local settings_bufnr = nil

local settings_items = {
  {
    key = "temperature",
    label = "Temperature",
    type = "number",
    min = 0,
    max = 2,
    step = 0.1,
    get_value = function()
      local config = require("luca").config()
      local agent = require("luca.agent")
      local current_agent = agent.get_current_agent()
      local agent_config = config.agents.providers[current_agent]
      return agent_config and agent_config.temperature or 0.7
    end,
    set_value = function(value)
      local config = require("luca").config()
      local agent = require("luca.agent")
      local current_agent = agent.get_current_agent()
      if config.agents.providers[current_agent] then
        config.agents.providers[current_agent].temperature = tonumber(value)
      end
    end,
  },
  {
    key = "max_tokens",
    label = "Max Tokens",
    type = "number",
    min = 1,
    max = 32000,
    step = 100,
    get_value = function()
      local config = require("luca").config()
      local agent = require("luca.agent")
      local current_agent = agent.get_current_agent()
      local agent_config = config.agents.providers[current_agent]
      return agent_config and agent_config.max_tokens or "unlimited"
    end,
    set_value = function(value)
      local config = require("luca").config()
      local agent = require("luca.agent")
      local current_agent = agent.get_current_agent()
      if config.agents.providers[current_agent] then
        if value == "unlimited" or value == "" then
          config.agents.providers[current_agent].max_tokens = nil
        else
          config.agents.providers[current_agent].max_tokens = tonumber(value)
        end
      end
    end,
  },
  {
    key = "top_p",
    label = "Top P",
    type = "number",
    min = 0,
    max = 1,
    step = 0.1,
    get_value = function()
      local config = require("luca").config()
      local agent = require("luca.agent")
      local current_agent = agent.get_current_agent()
      local agent_config = config.agents.providers[current_agent]
      return agent_config and agent_config.top_p or 1.0
    end,
    set_value = function(value)
      local config = require("luca").config()
      local agent = require("luca.agent")
      local current_agent = agent.get_current_agent()
      if config.agents.providers[current_agent] then
        config.agents.providers[current_agent].top_p = tonumber(value)
      end
    end,
  },
  {
    key = "model",
    label = "Model",
    type = "string",
    get_value = function()
      local config = require("luca").config()
      local agent = require("luca.agent")
      local current_agent = agent.get_current_agent()
      local agent_config = config.agents.providers[current_agent]
      return agent_config and agent_config.model or "gpt-4"
    end,
    set_value = function(value)
      local config = require("luca").config()
      local agent = require("luca.agent")
      local current_agent = agent.get_current_agent()
      if config.agents.providers[current_agent] then
        config.agents.providers[current_agent].model = value
      end
    end,
  },
  {
    key = "agent",
    label = "Agent",
    type = "select",
    get_value = function()
      local agent = require("luca.agent")
      return agent.get_current_agent()
    end,
    set_value = function(value)
      local agent = require("luca.agent")
      agent.set_agent(value)
    end,
    options = function()
      local agent = require("luca.agent")
      return agent.list_agents()
    end,
  },
}

function M.toggle()
  if settings_winid and vim.api.nvim_win_is_valid(settings_winid) then
    M.close()
  else
    M.open()
  end
end

function M.open()
  -- Get chat window from ui module
  local chat_winid = nil
  local ok, ui = pcall(require, "luca.ui")
  if ok then
    chat_winid = ui.get_chat_winid()
  end
  
  if not chat_winid or not vim.api.nvim_win_is_valid(chat_winid) then
    -- Fallback: try to find chat window by buffer name
    local chat_bufnr = vim.fn.bufnr("luca-chat")
    if chat_bufnr ~= -1 then
      local wins = vim.fn.win_findbuf(chat_bufnr)
      if #wins > 0 then
        chat_winid = wins[1]
      end
    end
  end
  
  if not chat_winid or not vim.api.nvim_win_is_valid(chat_winid) then
    vim.notify("Chat window must be open to show settings", vim.log.levels.WARN)
    return
  end
  
  local chat_config = vim.api.nvim_win_get_config(chat_winid)
  local width = 40
  local height = #settings_items + 4
  local col = chat_config.col[false] + chat_config.width - width - 2
  local row = chat_config.row[false] + 2
  
  settings_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(settings_bufnr, "luca-settings")
  
  M.update_content()
  
  settings_winid = vim.api.nvim_open_win(settings_bufnr, false, {
    relative = "win",
    win = chat_winid,
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    title = " Settings ",
    style = "minimal",
  })
  
  vim.api.nvim_win_set_option(settings_winid, "wrap", false)
  
  -- Add keymaps
  vim.api.nvim_buf_set_keymap(settings_bufnr, "n", "<CR>", "", {
    callback = function()
      M.edit_selected_setting()
    end,
  })
  
  vim.api.nvim_buf_set_keymap(settings_bufnr, "n", "q", "", {
    callback = function()
      M.close()
    end,
  })
  
  vim.api.nvim_buf_set_keymap(settings_bufnr, "n", "<Esc>", "", {
    callback = function()
      M.close()
    end,
  })
end

function M.update_content()
  if not settings_bufnr or not vim.api.nvim_buf_is_valid(settings_bufnr) then
    return
  end
  
  local lines = { "Settings:", "" }
  for i, item in ipairs(settings_items) do
    local value = item.get_value()
    if item.type == "select" and item.options then
      local opts = item.options()
      value = value .. " (" .. table.concat(opts, ", ") .. ")"
    end
    table.insert(lines, string.format("%d. %s: %s", i, item.label, tostring(value)))
  end
  table.insert(lines, "")
  table.insert(lines, "Press Enter to edit, q to close")
  
  vim.api.nvim_buf_set_lines(settings_bufnr, 0, -1, false, lines)
end

function M.edit_selected_setting()
  local line = vim.fn.line(".")
  local item_index = line - 2  -- Account for header and blank line
  
  if item_index < 1 or item_index > #settings_items then
    return
  end
  
  local item = settings_items[item_index]
  local current_value = item.get_value()
  
  if item.type == "select" and item.options then
    -- Show options selector
    local opts = item.options()
    local width = 30
    local height = #opts + 4
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)
    
    local bufnr = vim.api.nvim_create_buf(false, true)
    local lines = { "Select " .. item.label .. ":", "" }
    for i, opt in ipairs(opts) do
      local marker = opt == current_value and "✓ " or "  "
      table.insert(lines, marker .. opt)
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
      title = " Select " .. item.label .. " ",
      style = "minimal",
    })
    
    for i = 1, #opts do
      vim.api.nvim_buf_set_keymap(bufnr, "n", tostring(i), "", {
        callback = function()
          item.set_value(opts[i])
          vim.api.nvim_win_close(winid, true)
          M.update_content()
        end,
      })
    end
    
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "", {
      callback = function()
        vim.api.nvim_win_close(winid, true)
      end,
    })
  else
    -- Text input for string/number
    vim.ui.input({
      prompt = item.label .. ": ",
      default = tostring(current_value),
    }, function(input)
      if input then
        item.set_value(input)
        M.update_content()
      end
    end)
  end
end

function M.close()
  if settings_winid and vim.api.nvim_win_is_valid(settings_winid) then
    vim.api.nvim_win_close(settings_winid, true)
  end
  settings_winid = nil
  settings_bufnr = nil
end

return M

