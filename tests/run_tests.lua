-- Test runner for luca.nvim

local M = {}

local tests = {
  "test_cache",
  "test_tokens",
  "test_patch",
  "test_commands",
  "test_tools",
  "test_diff",
}

function M.run_all()
  print("Running luca.nvim tests...")
  print("=" .. string.rep("=", 50))
  
  local passed = 0
  local failed = 0
  
  for _, test_name in ipairs(tests) do
    print("\nRunning " .. test_name .. "...")
    local ok, err = pcall(function()
      require("tests." .. test_name)
    end)
    
    if ok then
      print("✓ " .. test_name .. " passed")
      passed = passed + 1
    else
      print("✗ " .. test_name .. " failed: " .. tostring(err))
      failed = failed + 1
    end
  end
  
  print("\n" .. string.rep("=", 52))
  print(string.format("Results: %d passed, %d failed", passed, failed))
  
  if failed == 0 then
    print("All tests passed! ✓")
  else
    print("Some tests failed ✗")
  end
  
  return failed == 0
end

return M

