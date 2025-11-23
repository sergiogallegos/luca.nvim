local M = {}

-- Caching system for responses and context

local cache = {}
local cache_config = {
  enabled = true,
  max_size = 100,
  ttl = 3600, -- 1 hour in seconds
}

function M.setup(config)
  cache_config = vim.tbl_deep_extend("force", cache_config, config or {})
end

function M.get(key)
  if not cache_config.enabled then
    return nil
  end
  
  local entry = cache[key]
  if not entry then
    return nil
  end
  
  -- Check TTL
  if os.time() - entry.timestamp > cache_config.ttl then
    cache[key] = nil
    return nil
  end
  
  return entry.value
end

function M.set(key, value)
  if not cache_config.enabled then
    return
  end
  
  -- Evict old entries if cache is full
  if #vim.tbl_keys(cache) >= cache_config.max_size then
    local oldest_key = nil
    local oldest_time = math.huge
    
    for k, v in pairs(cache) do
      if v.timestamp < oldest_time then
        oldest_time = v.timestamp
        oldest_key = k
      end
    end
    
    if oldest_key then
      cache[oldest_key] = nil
    end
  end
  
  cache[key] = {
    value = value,
    timestamp = os.time(),
  }
end

function M.generate_key(context, message)
  -- Generate cache key from context and message
  local key_parts = {}
  
  if context and context.buffer then
    table.insert(key_parts, context.buffer.path)
  end
  
  table.insert(key_parts, message)
  
  return table.concat(key_parts, "|")
end

function M.clear()
  cache = {}
end

function M.get_stats()
  local keys = vim.tbl_keys(cache)
  return {
    size = #keys,
    max_size = cache_config.max_size,
    enabled = cache_config.enabled,
  }
end

return M

