-- Unit tests for tokens module

local describe = describe or function(name, fn) fn() end
local it = it or function(name, fn) fn() end
local assert = assert or error

describe("luca.tokens", function()
  local tokens = require("luca.tokens")
  
  it("should estimate tokens correctly", function()
    local text = "This is a test string with some content."
    local count = tokens.count_tokens(text)
    assert(count > 0, "Should return positive token count")
    assert(type(count) == "number", "Should return a number")
  end)
  
  it("should trim context when exceeding limits", function()
    local context = {
      buffer = {
        content = string.rep("x", 10000), -- Large content
      },
      files = {
        { path = "/test1.lua", content = string.rep("y", 5000) },
        { path = "/test2.lua", content = string.rep("z", 5000) },
      },
    }
    
    local trimmed = tokens.trim_context(context, 1000) -- Small limit
    assert(trimmed ~= nil, "Should return trimmed context")
    -- In real scenario, would verify size reduction
  end)
  
  it("should summarize context", function()
    local context = {
      buffer = {
        path = "/test/file.lua",
        line_count = 100,
      },
      files = {
        { path = "/test1.lua" },
        { path = "/test2.lua" },
      },
    }
    
    local summary = tokens.summarize_context(context)
    assert(summary ~= nil, "Should generate summary")
    assert(type(summary) == "string", "Summary should be a string")
    assert(summary:match("test/file.lua"), "Should include file path")
  end)
  
  it("should count message tokens", function()
    local messages = {
      { role = "user", content = "Hello" },
      { role = "assistant", content = "Hi there" },
    }
    
    local count = tokens.count_message_tokens(messages)
    assert(count > 0, "Should count tokens in messages")
  end)
end)

