local M = {}

-- Token limits and context trimming

local function estimate_tokens(text)
  -- Rough estimation: ~4 characters per token
  return math.ceil(#text / 4)
end

function M.trim_context(context, max_tokens)
  max_tokens = max_tokens or 4000
  
  if not context then
    return context
  end
  
  local total_tokens = 0
  local trimmed = {
    buffer = context.buffer,
    files = {},
  }
  
  -- Count buffer tokens
  if context.buffer then
    total_tokens = total_tokens + estimate_tokens(context.buffer.content)
  end
  
  -- Add files until we hit the limit
  if context.files then
    for _, file in ipairs(context.files) do
      local file_tokens = estimate_tokens(file.content)
      
      if total_tokens + file_tokens <= max_tokens then
        table.insert(trimmed.files, file)
        total_tokens = total_tokens + file_tokens
      else
        -- Truncate file content if needed
        local remaining = max_tokens - total_tokens
        if remaining > 100 then -- Only if we have meaningful space
          local truncated = file.content:sub(1, remaining * 4)
          table.insert(trimmed.files, {
            path = file.path,
            content = truncated .. "\n... (truncated)",
          })
        end
        break
      end
    end
  end
  
  return trimmed
end

function M.summarize_context(context)
  -- Create a summary of context to save tokens
  local summary = {}
  
  if context.buffer then
    table.insert(summary, string.format("Current file: %s (%d lines)", 
      context.buffer.path, context.buffer.line_count))
  end
  
  if context.files and #context.files > 0 then
    table.insert(summary, string.format("Relevant files: %d", #context.files))
    for _, file in ipairs(context.files) do
      table.insert(summary, "  - " .. file.path)
    end
  end
  
  return table.concat(summary, "\n")
end

function M.count_tokens(text)
  return estimate_tokens(text)
end

function M.count_message_tokens(messages)
  local total = 0
  for _, msg in ipairs(messages) do
    total = total + estimate_tokens(msg.content or "")
  end
  return total
end

return M

