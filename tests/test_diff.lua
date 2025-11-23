-- Unit tests for diff module

local describe = describe or function(name, fn) fn() end
local it = it or function(name, fn) fn() end
local assert = assert or error

describe("luca.diff", function()
  local diff = require("luca.diff")
  
  it("should parse unified diff", function()
    local diff_text = [[
--- a/file.lua
+++ b/file.lua
@@ -1,3 +1,3 @@
-old line
+new line
 same line
]]
    
    local hunks = diff.parse_unified_diff(diff_text)
    assert(#hunks > 0, "Should parse diff hunks")
    assert(hunks[1].file ~= nil, "Should extract file path")
  end)
  
  it("should handle multiple hunks", function()
    local diff_text = [[
@@ -1,2 +1,2 @@
 hunk1
@@ -5,2 +5,2 @@
 hunk2
]]
    
    local hunks = diff.parse_unified_diff(diff_text)
    assert(#hunks == 2, "Should parse multiple hunks")
  end)
end)

