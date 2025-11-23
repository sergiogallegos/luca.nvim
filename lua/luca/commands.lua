local M = {}

-- Commands Palette - Cursor-style "/" commands

local commands = {
  refactor = {
    description = "Refactor the selected code or current function",
    handler = function()
      local agent = require("luca.agent")
      local context = require("luca.context").get_context()
      local message = "Please refactor the following code to improve its structure, readability, and maintainability while preserving functionality:\n\n"
      
      if context and context.buffer then
        message = message .. context.buffer.content
      else
        -- Get visual selection or current function
        local bufnr = vim.api.nvim_get_current_buf()
        local start_line = vim.fn.line("'<")
        local end_line = vim.fn.line("'>")
        if start_line > 0 and end_line > 0 then
          local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
          message = message .. table.concat(lines, "\n")
        else
          -- Get current function (simplified - would need LSP for better detection)
          local cursor_line = vim.fn.line(".")
          local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, cursor_line - 10), cursor_line + 10, false)
          message = message .. table.concat(lines, "\n")
        end
      end
      
      require("luca.ui").open()
      vim.defer_fn(function()
        agent.send_message(message, function(response)
          require("luca.ui").append_to_chat("Luca", response)
        end)
      end, 100)
    end,
  },
  
  explain = {
    description = "Explain the selected code or current function",
    handler = function()
      local agent = require("luca.agent")
      local message = "Please explain what this code does, how it works, and any important details:\n\n"
      
      local bufnr = vim.api.nvim_get_current_buf()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      if start_line > 0 and end_line > 0 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
        message = message .. table.concat(lines, "\n")
      else
        local cursor_line = vim.fn.line(".")
        local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, cursor_line - 20), cursor_line + 20, false)
        message = message .. table.concat(lines, "\n")
      end
      
      require("luca.ui").open()
      vim.defer_fn(function()
        agent.send_message(message, function(response)
          require("luca.ui").append_to_chat("Luca", response)
        end)
      end, 100)
    end,
  },
  
  fix = {
    description = "Fix bugs in the selected code",
    handler = function()
      local agent = require("luca.agent")
      local message = "Please identify and fix any bugs in the following code:\n\n"
      
      local bufnr = vim.api.nvim_get_current_buf()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      if start_line > 0 and end_line > 0 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
        message = message .. table.concat(lines, "\n")
      else
        local cursor_line = vim.fn.line(".")
        local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, cursor_line - 30), cursor_line + 30, false)
        message = message .. table.concat(lines, "\n")
      end
      
      require("luca.ui").open()
      vim.defer_fn(function()
        agent.send_message(message, function(response)
          require("luca.ui").append_to_chat("Luca", response)
        end)
      end, 100)
    end,
  },
  
  optimize = {
    description = "Optimize performance of the selected code",
    handler = function()
      local agent = require("luca.agent")
      local message = "Please optimize the performance of the following code while maintaining correctness:\n\n"
      
      local bufnr = vim.api.nvim_get_current_buf()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      if start_line > 0 and end_line > 0 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
        message = message .. table.concat(lines, "\n")
      else
        local cursor_line = vim.fn.line(".")
        local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, cursor_line - 30), cursor_line + 30, false)
        message = message .. table.concat(lines, "\n")
      end
      
      require("luca.ui").open()
      vim.defer_fn(function()
        agent.send_message(message, function(response)
          require("luca.ui").append_to_chat("Luca", response)
        end)
      end, 100)
    end,
  },
  
  test = {
    description = "Generate unit tests for the selected code",
    handler = function()
      local agent = require("luca.agent")
      local context = require("luca.context").get_context()
      local message = "Please generate comprehensive unit tests for the following code. Detect the test framework from the project structure:\n\n"
      
      if context and context.buffer then
        message = message .. context.buffer.content
      else
        local bufnr = vim.api.nvim_get_current_buf()
        local start_line = vim.fn.line("'<")
        local end_line = vim.fn.line("'>")
        if start_line > 0 and end_line > 0 then
          local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
          message = message .. table.concat(lines, "\n")
        else
          local cursor_line = vim.fn.line(".")
          local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, cursor_line - 50), cursor_line + 50, false)
          message = message .. table.concat(lines, "\n")
        end
      end
      
      require("luca.ui").open()
      vim.defer_fn(function()
        agent.send_message(message, function(response)
          require("luca.ui").append_to_chat("Luca", response)
        end)
      end, 100)
    end,
  },
  
  review = {
    description = "Review code for best practices and improvements",
    handler = function()
      local agent = require("luca.agent")
      local context = require("luca.context").get_context()
      local message = "Please review the following code for best practices, potential issues, security concerns, and suggest improvements:\n\n"
      
      if context and context.buffer then
        message = message .. context.buffer.content
      else
        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        message = message .. table.concat(lines, "\n")
      end
      
      require("luca.ui").open()
      vim.defer_fn(function()
        agent.send_message(message, function(response)
          require("luca.ui").append_to_chat("Luca", response)
        end)
      end, 100)
    end,
  },
  
  doc = {
    description = "Generate documentation for the selected code",
    handler = function()
      local agent = require("luca.agent")
      local context = require("luca.context").get_context()
      local message = "Please generate comprehensive documentation (docstrings, comments, README sections) for the following code:\n\n"
      
      if context and context.buffer then
        message = message .. context.buffer.content
      else
        local bufnr = vim.api.nvim_get_current_buf()
        local start_line = vim.fn.line("'<")
        local end_line = vim.fn.line("'>")
        if start_line > 0 and end_line > 0 then
          local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
          message = message .. table.concat(lines, "\n")
        else
          local cursor_line = vim.fn.line(".")
          local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, cursor_line - 50), cursor_line + 50, false)
          message = message .. table.concat(lines, "\n")
        end
      end
      
      require("luca.ui").open()
      vim.defer_fn(function()
        agent.send_message(message, function(response)
          require("luca.ui").append_to_chat("Luca", response)
        end)
      end, 100)
    end,
  },
}

function M.show_palette()
  local width = 50
  local height = #vim.tbl_keys(commands) + 4
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "luca-commands")
  
  local cmd_list = {}
  local cmd_names = {}
  for name, cmd in pairs(commands) do
    table.insert(cmd_names, name)
    table.insert(cmd_list, string.format("/%s - %s", name, cmd.description))
  end
  table.sort(cmd_list)
  table.sort(cmd_names)
  
  local lines = { "Commands Palette:", "" }
  for i, line in ipairs(cmd_list) do
    table.insert(lines, string.format("%d. %s", i, line))
  end
  table.insert(lines, "")
  table.insert(lines, "Press number to select, q to cancel")
  
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    title = " Commands ",
    style = "minimal",
  })
  
  -- Add keymaps
  for i = 1, #cmd_names do
    vim.api.nvim_buf_set_keymap(bufnr, "n", tostring(i), "", {
      callback = function()
        vim.api.nvim_win_close(winid, true)
        commands[cmd_names[i]].handler()
      end,
    })
  end
  
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "", {
    callback = function()
      vim.api.nvim_win_close(winid, true)
    end,
  })
end

function M.handle_command(input)
  -- Handle "/command" style input
  if input:match("^/") then
    local cmd_name = input:match("^/(%w+)")
    if cmd_name and commands[cmd_name] then
      commands[cmd_name].handler()
      return true
    else
      vim.notify("Unknown command: " .. cmd_name, vim.log.levels.WARN)
      M.show_palette()
      return true
    end
  end
  return false
end

return M

