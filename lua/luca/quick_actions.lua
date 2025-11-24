local M = {}

-- Quick Actions Menu - Grammar, translate, optimize, etc. like ChatGPT.nvim

local actions = {
  grammar_correction = {
    description = "Fix grammar and spelling",
    prompt = "Please correct the grammar and spelling in the following text:\n\n{{input}}",
  },
  translate = {
    description = "Translate to another language",
    prompt = "Please translate the following text to {{argument}}. Maintain the same tone and style:\n\n{{input}}",
    args = {
      argument = {
        type = "string",
        optional = false,
        default = "English",
        prompt = "Target language: ",
      },
    },
  },
  keywords = {
    description = "Extract keywords",
    prompt = "Please extract the main keywords from the following text:\n\n{{input}}",
  },
  docstring = {
    description = "Generate docstring",
    prompt = "Please generate a comprehensive docstring for the following code:\n\n{{input}}",
  },
  add_tests = {
    description = "Add unit tests",
    prompt = "Please generate comprehensive unit tests for the following code. Detect the test framework from the project structure:\n\n{{input}}",
  },
  optimize_code = {
    description = "Optimize code performance",
    prompt = "Please optimize the performance of the following code while maintaining correctness:\n\n{{input}}",
  },
  summarize = {
    description = "Summarize text",
    prompt = "Please provide a concise summary of the following text:\n\n{{input}}",
  },
  fix_bugs = {
    description = "Fix bugs",
    prompt = "Please identify and fix any bugs in the following code:\n\n{{input}}",
  },
  explain_code = {
    description = "Explain code",
    prompt = "Please explain what this code does, how it works, and any important details:\n\n{{input}}",
  },
  code_readability = {
    description = "Analyze code readability",
    prompt = "Please analyze the readability of the following code and suggest improvements:\n\n{{input}}",
  },
}

function M.show_menu()
  local width = 50
  local height = #vim.tbl_keys(actions) + 4
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "luca-quick-actions")
  
  local action_list = {}
  local action_names = {}
  for name, action in pairs(actions) do
    table.insert(action_names, name)
    table.insert(action_list, { name = name, action = action })
  end
  
  table.sort(action_list, function(a, b) return a.name < b.name end)
  
  local lines = { "Quick Actions:", "" }
  for i, item in ipairs(action_list) do
    table.insert(lines, string.format("%d. %s - %s", i, item.name, item.action.description))
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
    title = " Quick Actions ",
    style = "minimal",
  })
  
  -- Add keymaps
  for i, item in ipairs(action_list) do
    vim.api.nvim_buf_set_keymap(bufnr, "n", tostring(i), "", {
      callback = function()
        vim.api.nvim_win_close(winid, true)
        M.run_action(item.name, item.action)
      end,
    })
  end
  
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "", {
    callback = function()
      vim.api.nvim_win_close(winid, true)
    end,
  })
end

function M.run_action(action_name, action)
  -- Get selected text or current buffer
  local input = ""
  local bufnr = vim.api.nvim_get_current_buf()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  
  if start_line > 0 and end_line > 0 then
    -- Visual selection
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
    input = table.concat(lines, "\n")
  else
    -- Current buffer or function
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    input = table.concat(lines, "\n")
  end
  
  if input == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end
  
  -- Build prompt with template variables
  local prompt = action.prompt
  prompt = prompt:gsub("{{input}}", input)
  prompt = prompt:gsub("{{filetype}}", vim.bo.filetype or "")
  prompt = prompt:gsub("{{filepath}}", vim.api.nvim_buf_get_name(bufnr) or "")
  
  -- Handle arguments
  local args = {}
  if action.args then
    for arg_name, arg_config in pairs(action.args) do
      if not arg_config.optional or arg_config.default then
        local value = arg_config.default
        if not arg_config.optional then
          -- Prompt for required argument
          vim.ui.input({
            prompt = arg_config.prompt or (arg_name .. ": "),
            default = arg_config.default or "",
          }, function(input_value)
            if input_value then
              args[arg_name] = input_value
              prompt = prompt:gsub("{{" .. arg_name .. "}}", input_value)
              M.execute_action(action_name, prompt)
            end
          end)
          return  -- Wait for input
        else
          args[arg_name] = value
          prompt = prompt:gsub("{{" .. arg_name .. "}}", tostring(value))
        end
      end
    end
  end
  
  M.execute_action(action_name, prompt)
end

function M.execute_action(action_name, prompt)
  -- Open chat if not open
  local ui = require("luca.ui")
  if not ui.get_chat_winid() or not vim.api.nvim_win_is_valid(ui.get_chat_winid()) then
    ui.open()
  end
  
  -- Add action message to chat
  ui.append_to_chat("You", "[Action: " .. action_name .. "] " .. prompt)
  
  -- Send to agent
  local agent = require("luca.agent")
  agent.send_message(prompt, function(response)
    ui.append_to_chat("Luca", response)
  end)
end

function M.list_actions()
  return actions
end

return M

