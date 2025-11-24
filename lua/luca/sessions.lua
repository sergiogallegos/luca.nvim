local M = {}

-- Session Management - Multiple chat sessions like ChatGPT.nvim

local sessions = {}
local current_session_id = nil
local session_counter = 0

function M.setup()
  -- Initialize with default session
  M.new_session()
end

function M.new_session()
  session_counter = session_counter + 1
  local session_id = "session_" .. session_counter
  
  sessions[session_id] = {
    id = session_id,
    name = "Session " .. session_counter,
    messages = {},
    created_at = os.time(),
  }
  
  current_session_id = session_id
  return session_id
end

function M.get_current_session()
  if not current_session_id then
    M.new_session()
  end
  return sessions[current_session_id]
end

function M.get_current_session_id()
  if not current_session_id then
    M.new_session()
  end
  return current_session_id
end

function M.set_session(session_id)
  if sessions[session_id] then
    current_session_id = session_id
    return true
  end
  return false
end

function M.list_sessions()
  local session_list = {}
  for id, session in pairs(sessions) do
    table.insert(session_list, {
      id = id,
      name = session.name,
      message_count = #session.messages,
      created_at = session.created_at,
    })
  end
  -- Sort by creation time (newest first)
  table.sort(session_list, function(a, b) return a.created_at > b.created_at end)
  return session_list
end

function M.add_message(role, content)
  local session = M.get_current_session()
  table.insert(session.messages, {
    role = role,
    content = content,
    timestamp = os.time(),
  })
end

function M.get_messages()
  local session = M.get_current_session()
  return session.messages
end

function M.clear_current_session()
  local session = M.get_current_session()
  session.messages = {}
end

function M.delete_session(session_id)
  if sessions[session_id] then
    sessions[session_id] = nil
    if current_session_id == session_id then
      -- Switch to first available session or create new one
      local session_list = M.list_sessions()
      if #session_list > 0 then
        current_session_id = session_list[1].id
      else
        M.new_session()
      end
    end
    return true
  end
  return false
end

function M.rename_session(session_id, new_name)
  if sessions[session_id] then
    sessions[session_id].name = new_name
    return true
  end
  return false
end

return M

