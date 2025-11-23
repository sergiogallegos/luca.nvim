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
  local endpoint = is_ollama and "/api/chat" or "/chat/completions"
  local url = agent_config.base_url .. endpoint
  
  -- Build headers
  local headers = {
    ["Content-Type"] = "application/json",
  }
  
  -- Add Authorization header only if API key is provided
  if agent_config.api_key then
    headers["Authorization"] = "Bearer " .. agent_config.api_key
  end
  
  -- Build request body - different format for Ollama vs OpenAI
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
  else
    -- OpenAI-compatible API format
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
  
  -- Check cache
  local context = require("luca.context").get_context()
  local cache_key = cache.generate_key(context, message)
  local cached = cache.get(cache_key)
  if cached then
    vim.notify("Using cached response", vim.log.levels.INFO)
    if callback then
      callback(cached)
    end
    return
  end
  
  -- Trim context if needed
  if config.tokens and config.tokens.enable_trimming then
    context = tokens.trim_context(context, config.tokens.max_context_tokens)
  end
  
  -- Add LSP info if enabled
  if config.context.use_lsp then
    local lsp = require("luca.lsp")
    local ast_info = lsp.get_ast_info()
    if ast_info then
      context.lsp_info = lsp.format_lsp_context(ast_info)
    end
  end
  
  local history = require("luca.history").get_current()
  
  -- Build messages
  local messages = {}
  
  -- Add system message with context
  if context then
    local system_message = "You are a helpful coding assistant for Neovim. "
    if context.buffer then
      system_message = system_message .. "\nCurrent file: " .. context.buffer.path
      system_message = system_message .. "\nFile content:\n" .. context.buffer.content
    end
    if context.lsp_info then
      system_message = system_message .. "\n\nLSP Information:\n" .. context.lsp_info
    end
    if context.files and #context.files > 0 then
      system_message = system_message .. "\n\nRelevant files:\n"
      for _, file in ipairs(context.files) do
        system_message = system_message .. file.path .. "\n" .. file.content .. "\n\n"
      end
    end
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
  
  -- Make request
  make_request(
    current_agent,
    messages,
    function(chunk)
      statusline.update(current_agent, agent_config.model, "streaming")
      require("luca.ui").stream_update(chunk)
    end,
    function(full_response)
      statusline.update(current_agent, agent_config.model, "idle")
      
      -- Cache response
      cache.set(cache_key, full_response)
      
      require("luca.history").add_entry(message, full_response)
      if callback then
        callback(full_response)
      end
    end
  )
end

return M

