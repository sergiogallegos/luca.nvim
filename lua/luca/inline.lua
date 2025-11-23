local M = {}

-- Inline Chat (hover) - highlight code and get instant explanation

local hover_winid = nil
local hover_bufnr = nil

function M.show_hover()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  
  -- Get visual selection if available
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local has_selection = start_line > 0 and end_line > 0
  
  local selected_text = ""
  if has_selection then
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
    selected_text = table.concat(lines, "\n")
  else
    -- Get current line or function
    local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, line - 5), line + 5, false)
    selected_text = table.concat(lines, "\n")
  end
  
  -- Get LSP context
  local lsp = require("luca.lsp")
  local context = lsp.get_context_at_position(bufnr, line - 1, col - 1)
  
  -- Create quick explanation request
  local agent = require("luca.agent")
  local message = "Please provide a brief explanation of this code:\n\n" .. selected_text
  
  if context and context.hover then
    message = message .. "\n\nLSP Context: " .. vim.inspect(context.hover)
  end
  
  -- Show loading indicator
  M.show_loading()
  
  -- Send request (with shorter timeout for quick responses)
  agent.send_message(message, function(response)
    M.show_explanation(response, selected_text)
  end)
end

function M.show_loading()
  local width = 50
  local height = 3
  local col = vim.fn.col(".") + 5
  local row = vim.fn.line(".")
  
  hover_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(hover_bufnr, "luca-hover")
  
  vim.api.nvim_buf_set_lines(hover_bufnr, 0, -1, false, { "💭 Thinking..." })
  
  hover_winid = vim.api.nvim_open_win(hover_bufnr, false, {
    relative = "cursor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    style = "minimal",
  })
end

function M.show_explanation(explanation, code)
  if not hover_bufnr or not vim.api.nvim_buf_is_valid(hover_bufnr) then
    return
  end
  
  -- Truncate if too long
  local lines = vim.split(explanation, "\n")
  if #lines > 15 then
    lines = vim.list_slice(lines, 1, 15)
    table.insert(lines, "...")
  end
  
  vim.api.nvim_buf_set_lines(hover_bufnr, 0, -1, false, lines)
  
  if hover_winid and vim.api.nvim_win_is_valid(hover_winid) then
    local height = math.min(#lines + 2, 20)
    vim.api.nvim_win_set_height(hover_winid, height)
  end
  
  -- Add close keymap
  vim.api.nvim_buf_set_keymap(hover_bufnr, "n", "q", "", {
    callback = function()
      M.close_hover()
    end,
  })
  
  -- Auto-close after 10 seconds
  vim.defer_fn(function()
    M.close_hover()
  end, 10000)
end

function M.close_hover()
  if hover_winid and vim.api.nvim_win_is_valid(hover_winid) then
    vim.api.nvim_win_close(hover_winid, true)
  end
  hover_winid = nil
  hover_bufnr = nil
end

return M

