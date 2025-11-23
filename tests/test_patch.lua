-- Unit tests for patch module

local describe = describe or function(name, fn) fn() end
local it = it or function(name, fn) fn() end
local assert = assert or error

describe("luca.patch", function()
  local patch = require("luca.patch")
  
  it("should parse code blocks", function()
    local text = [[
Here is some code:
```lua
local x = 1
print(x)
```
That's the code.
]]
    
    local blocks = patch.parse_code_blocks(text)
    assert(#blocks > 0, "Should parse code blocks")
    assert(blocks[1].language == "lua", "Should detect language")
    assert(blocks[1].content:match("local x"), "Should extract content")
  end)
  
  it("should parse file paths", function()
    local text = [[
file: /path/to/file.lua
Or ```/another/path.py
]]
    
    local paths = patch.parse_file_paths(text)
    assert(#paths > 0, "Should parse file paths")
  end)
  
  it("should handle multiple code blocks", function()
    local text = [[
```lua
code1
```
```python
code2
```
]]
    
    local blocks = patch.parse_code_blocks(text)
    assert(#blocks == 2, "Should parse multiple blocks")
  end)
  
  it("should handle unclosed code blocks", function()
    local text = [[
```lua
code without closing
]]
    
    local blocks = patch.parse_code_blocks(text)
    -- Should handle gracefully
    assert(blocks ~= nil, "Should not crash on unclosed blocks")
  end)
end)

