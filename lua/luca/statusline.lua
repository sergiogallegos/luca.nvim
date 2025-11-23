local M = {}

local statusline_component = nil

function M.setup()
  -- Create statusline component
  statusline_component = {
    agent = nil,
    model = nil,
    status = "idle", -- idle, thinking, streaming
  }
end

function M.update(agent_name, model_name, status)
  statusline_component.agent = agent_name
  statusline_component.model = model_name
  statusline_component.status = status or "idle"
  
  -- Trigger statusline update (schedule to avoid fast event context error)
  vim.schedule(function()
    vim.cmd("redrawstatus")
  end)
end

function M.get_component()
  if not statusline_component then
    return ""
  end
  
  local parts = {}
  
  if statusline_component.agent then
    table.insert(parts, "🤖 " .. statusline_component.agent)
  end
  
  if statusline_component.model then
    table.insert(parts, statusline_component.model)
  end
  
  if statusline_component.status == "thinking" then
    table.insert(parts, "💭")
  elseif statusline_component.status == "streaming" then
    table.insert(parts, "⚡")
  end
  
  return table.concat(parts, " ")
end

-- Statusline integration function
function M.integrate()
  -- This can be called from user's statusline config
  -- Example: require("luca.statusline").get_component()
  return M.get_component()
end

return M

