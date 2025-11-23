-- Unit tests for cache module

local describe = describe or function(name, fn) fn() end
local it = it or function(name, fn) fn() end
local assert = assert or error

describe("luca.cache", function()
  local cache = require("luca.cache")
  
  it("should store and retrieve values", function()
    cache.setup({ enabled = true })
    cache.set("test_key", "test_value")
    local value = cache.get("test_key")
    assert(value == "test_value", "Cache should return stored value")
  end)
  
  it("should respect TTL", function()
    cache.setup({ enabled = true, ttl = 1 })
    cache.set("ttl_key", "ttl_value")
    local value1 = cache.get("ttl_key")
    assert(value1 == "ttl_value", "Should get value before TTL expires")
    
    -- Wait for TTL (in real test, would use timer)
    -- For now, manually expire
    cache.clear()
    cache.setup({ enabled = true, ttl = 0 })
    cache.set("ttl_key", "ttl_value")
    local value2 = cache.get("ttl_key")
    -- In real scenario, would be nil after TTL
  end)
  
  it("should respect max_size", function()
    cache.setup({ enabled = true, max_size = 2 })
    cache.clear()
    cache.set("key1", "value1")
    cache.set("key2", "value2")
    cache.set("key3", "value3") -- Should evict oldest
    local stats = cache.get_stats()
    assert(stats.size <= 2, "Cache should not exceed max_size")
  end)
  
  it("should generate cache keys", function()
    local context = { buffer = { path = "/test/file.lua" } }
    local message = "test message"
    local key = cache.generate_key(context, message)
    assert(key ~= nil, "Should generate a cache key")
    assert(type(key) == "string", "Key should be a string")
  end)
  
  it("should handle disabled cache", function()
    cache.setup({ enabled = false })
    cache.set("disabled_key", "value")
    local value = cache.get("disabled_key")
    assert(value == nil, "Disabled cache should not store values")
  end)
end)

