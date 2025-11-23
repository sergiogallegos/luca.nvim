local M = {}

-- Tooling API for function calling support

local tools = {}

function M.register_tool(name, description, handler)
  tools[name] = {
    description = description,
    handler = handler,
  }
end

function M.list_tools()
  return tools
end

function M.call_tool(name, arguments)
  if not tools[name] then
    return nil, "Tool not found: " .. name
  end
  
  local ok, result = pcall(tools[name].handler, arguments)
  if not ok then
    return nil, result
  end
  
  return result, nil
end

function M.format_tools_for_agent()
  local formatted = {}
  for name, tool in pairs(tools) do
    table.insert(formatted, {
      type = "function",
      function = {
        name = name,
        description = tool.description,
        parameters = tool.parameters or {},
      },
    })
  end
  return formatted
end

-- Built-in tools
function M.setup_builtin_tools()
  -- Run diagnostics
  M.register_tool("run_diagnostics", "Run diagnostics on the current buffer", function(args)
    local bufnr = vim.api.nvim_get_current_buf()
    vim.lsp.buf.document_symbol()
    return { success = true, message = "Diagnostics run" }
  end)
  
  -- Search files
  M.register_tool("search_files", "Search for files in the project", function(args)
    local pattern = args.pattern or ""
    local cwd = vim.fn.getcwd()
    local results = {}
    
    -- Use vim.fn.globpath for file search
    local files = vim.fn.globpath(cwd, "**/" .. pattern, false, true)
    for _, file in ipairs(files) do
      if #results < 10 then -- Limit results
        table.insert(results, file)
      end
    end
    
    return { files = results, count = #results }
  end, {
    type = "object",
    properties = {
      pattern = { type = "string", description = "File pattern to search" },
    },
  })
  
  -- Get file content
  M.register_tool("get_file_content", "Get the content of a file", function(args)
    local filepath = args.filepath
    if not filepath then
      return nil, "filepath is required"
    end
    
    local file = io.open(filepath, "r")
    if not file then
      return nil, "Could not open file: " .. filepath
    end
    
    local content = file:read("*all")
    file:close()
    
    return { content = content, filepath = filepath }
  end, {
    type = "object",
    properties = {
      filepath = { type = "string", description = "Path to the file" },
    },
    required = { "filepath" },
  })
  
  -- Run tests
  M.register_tool("run_tests", "Run tests in the project", function(args)
    local cwd = vim.fn.getcwd()
    local test_cmd = nil
    
    if vim.fn.filereadable(cwd .. "/package.json") then
      test_cmd = "npm test"
    elseif vim.fn.filereadable(cwd .. "/pytest.ini") or vim.fn.filereadable(cwd .. "/pyproject.toml") then
      test_cmd = "pytest"
    elseif vim.fn.filereadable(cwd .. "/go.mod") then
      test_cmd = "go test ./..."
    end
    
    if not test_cmd then
      return nil, "Could not detect test framework"
    end
    
    -- Run in terminal
    vim.cmd("split")
    vim.cmd("terminal " .. test_cmd)
    
    return { success = true, command = test_cmd }
  end)
  
  -- Execute shell command (safe mode)
  M.register_tool("execute_command", "Execute a shell command safely", function(args)
    local command = args.command
    if not command then
      return nil, "command is required"
    end
    
    -- Safety check - only allow certain commands
    local allowed_commands = { "git", "npm", "yarn", "python", "node", "go", "cargo" }
    local cmd_base = command:match("^(%w+)")
    local allowed = false
    
    for _, allowed_cmd in ipairs(allowed_commands) do
      if cmd_base == allowed_cmd then
        allowed = true
        break
      end
    end
    
    if not allowed then
      return nil, "Command not allowed in safe mode: " .. cmd_base
    end
    
    local handle = io.popen(command)
    if not handle then
      return nil, "Failed to execute command"
    end
    
    local output = handle:read("*all")
    handle:close()
    
    return { output = output, success = true }
  end, {
    type = "object",
    properties = {
      command = { type = "string", description = "Command to execute" },
    },
    required = { "command" },
  })
end

function M.setup()
  M.setup_builtin_tools()
end

return M

