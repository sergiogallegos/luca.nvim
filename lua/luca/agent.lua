local M = {}

local agents = {}
local current_agent = nil

local http = require("luca.http")

local function make_request(provider, messages, on_chunk, on_complete)
  local config = require("luca").config()
  local agent_config = config.agents.providers[provider]
  
  if not agent_config then
    vim.notify("Agent not configured: " .. provider, vim.log.levels.ERROR)
    return
  end
  
  -- Determine API endpoint based on provider type
  local is_ollama = agent_config.base_url and agent_config.base_url:match("ollama") or provider == "ollama"
  local is_anthropic = agent_config.base_url and agent_config.base_url:match("anthropic") or provider == "claude" or provider:match("anthropic")
  local is_gemini = agent_config.base_url and agent_config.base_url:match("gemini") or provider == "gemini" or provider:match("google")
  local is_local = is_ollama or (agent_config.base_url and agent_config.base_url:match("localhost")) or (agent_config.base_url and agent_config.base_url:match("127%.0%.0%.1"))
  
  -- Check if API key is required (Ollama and other local providers don't need it)
  local requires_api_key = agent_config.requires_api_key
  if requires_api_key == nil then
    -- Auto-detect: local providers don't need API keys
    requires_api_key = not is_local
  end
  
  if requires_api_key and not agent_config.api_key then
    vim.notify("No API key configured for " .. provider, vim.log.levels.ERROR)
    return
  end
  
  -- Determine endpoint based on provider
  local endpoint
  if is_ollama then
    endpoint = "/api/chat"
  elseif is_anthropic then
    endpoint = "/v1/messages"
  elseif is_gemini then
    endpoint = "/v1beta/models/" .. agent_config.model .. ":streamGenerateContent"
  else
    endpoint = "/chat/completions"  -- OpenAI-compatible
  end
  
  local url = agent_config.base_url .. endpoint
  
  -- Build headers
  local headers = {
    ["Content-Type"] = "application/json",
  }
  
  -- Add Authorization header based on provider
  if agent_config.api_key then
    if is_anthropic then
      headers["x-api-key"] = agent_config.api_key
      headers["anthropic-version"] = "2023-06-01"
    elseif is_gemini then
      headers["Authorization"] = "Bearer " .. agent_config.api_key
    else
      headers["Authorization"] = "Bearer " .. agent_config.api_key
    end
  end
  
  -- Build request body - different format for different providers
  local request_body
  if is_ollama then
    -- Ollama API format
    request_body = {
      model = agent_config.model,
      messages = messages,
      stream = true,
    }
    -- Ollama uses different parameter names
    if agent_config.temperature ~= nil then
      request_body.temperature = agent_config.temperature
    end
    if agent_config.num_predict ~= nil then
      request_body.num_predict = agent_config.num_predict
    elseif agent_config.max_tokens ~= nil then
      request_body.num_predict = agent_config.max_tokens
    end
    if agent_config.top_p ~= nil then
      request_body.top_p = agent_config.top_p
    end
  elseif is_anthropic then
    -- Anthropic Claude API format
    request_body = {
      model = agent_config.model,
      messages = messages,
      max_tokens = agent_config.max_tokens or 4096,
      stream = true,
    }
    if agent_config.temperature ~= nil then
      request_body.temperature = agent_config.temperature
    end
    if agent_config.top_p ~= nil then
      request_body.top_p = agent_config.top_p
    end
  elseif is_gemini then
    -- Google Gemini API format (simplified)
    -- Note: Gemini API format is more complex, this is a basic implementation
    request_body = {
      contents = {},  -- Would need to convert messages format
    }
    -- For now, fall back to OpenAI format for Gemini
    request_body = {
      model = agent_config.model,
      messages = messages,
      stream = true,
    }
  else
    -- OpenAI-compatible API format (OpenAI, DeepSeek, etc.)
    request_body = {
      model = agent_config.model,
      messages = messages,
      stream = true,
    }
    -- Add optional parameters
    if agent_config.temperature ~= nil then
      request_body.temperature = agent_config.temperature
    end
    if agent_config.max_tokens ~= nil then
      request_body.max_tokens = agent_config.max_tokens
    end
    if agent_config.top_p ~= nil then
      request_body.top_p = agent_config.top_p
    end
    if agent_config.frequency_penalty ~= nil then
      request_body.frequency_penalty = agent_config.frequency_penalty
    end
    if agent_config.presence_penalty ~= nil then
      request_body.presence_penalty = agent_config.presence_penalty
    end
  end
  
  local body = vim.json.encode(request_body)
  
  -- Use HTTP client for streaming request (with Ollama support)
  http.stream_request(url, headers, body, on_chunk, on_complete, is_ollama)
end

function M.setup(config)
  agents = config.providers or {}
  current_agent = config.default or "openai"
end

function M.set_agent(name)
  if agents[name] then
    current_agent = name
    vim.notify("Switched to agent: " .. name, vim.log.levels.INFO)
  else
    vim.notify("Agent not found: " .. name, vim.log.levels.ERROR)
  end
end

function M.get_current_agent()
  return current_agent
end

function M.list_agents()
  return vim.tbl_keys(agents)
end

function M.send_message(message, callback)
  local statusline = require("luca.statusline")
  local cache = require("luca.cache")
  local tokens = require("luca.tokens")
  local config = require("luca").config()
  local agent_config = config.agents.providers[current_agent]
  
  -- Update statusline
  statusline.update(current_agent, agent_config.model, "thinking")
  
  -- Get context quickly - MINIMAL context for speed
  -- Only get current buffer, skip all slow operations
  local context = {}
  
  -- Only get buffer context (fast)
  if config.context and config.context.include_buffer then
    context.buffer = require("luca.context").get_buffer_context()
  end
  
  -- DISABLED by default for speed - project file scanning is too slow
  -- Users can enable in config if they really need it
  -- if config.context and config.context.include_tree and config.context.max_files and config.context.max_files > 0 then
  --   -- This is slow, skip it
  -- end
  
  -- DISABLED by default - LSP queries can be slow
  -- if config.context.use_lsp then
  --   local lsp = require("luca.lsp")
  --   local ast_info = lsp.get_ast_info()
  --   if ast_info then
  --     context.lsp_info = lsp.format_lsp_context(ast_info)
  --   end
  -- end
  
  -- Load memory files (fast - just file reads)
  local memory = require("luca.memory")
  local memory_context = memory.get_memory_context()
  if memory_context then
    -- Store for later use in system message
    context.memory_context = memory_context
  end
  
  -- Check cache
  local cache_key = cache.generate_key(context, message)
  local cached = cache.get(cache_key)
  if cached then
    vim.notify("Using cached response", vim.log.levels.INFO)
    if callback then
      callback(cached)
    end
    return
  end
  
  local history = require("luca.history").get_current()
  
  -- Build messages
  local messages = {}
  
  -- Add system message with context (minimal for speed)
  if context then
    local system_message = "You are a helpful coding assistant for Neovim. "
    
    -- Add memory files (project rules) - fast operation
    if context.memory_context then
      system_message = system_message .. "\n\n" .. context.memory_context
    end
    
    -- Add current buffer (fast)
    if context.buffer and context.buffer.path and context.buffer.path ~= "" then
      system_message = system_message .. "\n\nCurrent file: " .. context.buffer.path
      -- Only include buffer content if it's not too large (for speed)
      if #context.buffer.content < 10000 then
        system_message = system_message .. "\nFile content:\n" .. context.buffer.content
      else
        system_message = system_message .. "\nFile content: (file too large, showing first 5000 chars)\n" .. context.buffer.content:sub(1, 5000)
      end
    end
    
    -- Skip LSP info and project files for speed
    -- Users can enable these in config if needed, but they're slow
    
    table.insert(messages, { role = "system", content = system_message })
  end
  
  -- Add tools if available
  local tools_module = require("luca.tools")
  local tools_list = tools_module.format_tools_for_agent()
  if #tools_list > 0 then
    -- Tools would be added to request body if agent supports function calling
  end
  
  -- Add history
  if history and #history > 0 then
    for _, entry in ipairs(history) do
      table.insert(messages, { role = "user", content = entry.user })
      if entry.assistant then
        table.insert(messages, { role = "assistant", content = entry.assistant })
      end
    end
  end
  
  -- Add current message
  table.insert(messages, { role = "user", content = message })
  
  -- Store in session
  local sessions = require("luca.sessions")
  sessions.add_message("user", message)
  
  -- Make request
  make_request(
    current_agent,
    messages,
    function(chunk)
      statusline.update(current_agent, agent_config.model, "streaming")
      -- Direct call without vim.schedule for better performance
      require("luca.ui").stream_update(chunk)
    end,
    function(full_response)
      statusline.update(current_agent, agent_config.model, "idle")
      
      -- Reset streaming state
      require("luca.ui").reset_streaming()
      
      -- Cache response
      cache.set(cache_key, full_response)
      
      require("luca.history").add_entry(message, full_response)
      
      -- Store in session
      local sessions = require("luca.sessions")
      sessions.add_message("assistant", full_response)
      
      -- Note: Code change detection and Y/N prompt is now handled in ui.lua send_message callback
      
      if callback then
        callback(full_response)
      end
    end
  )
end

return M

