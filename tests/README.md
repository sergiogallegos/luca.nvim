# luca.nvim Test Suite

## Running Tests

```lua
-- In Neovim
:lua require("tests.run_tests").run_all()
```

Or from command line:
```bash
nvim --headless -c "lua require('tests.run_tests').run_all()" -c "qa"
```

## Test Structure

Tests are organized by module:
- `test_cache.lua` - Cache functionality
- `test_tokens.lua` - Token counting and trimming
- `test_patch.lua` - Code patch parsing
- `test_commands.lua` - Commands palette
- `test_tools.lua` - Tooling API
- `test_diff.lua` - Diff parsing

## Adding Tests

Create a new test file following the pattern:
```lua
local describe = describe or function(name, fn) fn() end
local it = it or function(name, fn) fn() end
local assert = assert or error

describe("module.name", function()
  it("should do something", function()
    -- Test code
    assert(condition, "Error message")
  end)
end)
```

## Test Coverage

Current test coverage includes:
- ✅ Cache operations
- ✅ Token estimation and trimming
- ✅ Code block parsing
- ✅ Command handling
- ✅ Tool registration
- ✅ Diff parsing

## Future Improvements

- Integration tests with mock HTTP
- UI component tests
- End-to-end workflow tests
- Performance benchmarks

