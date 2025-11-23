local M = {}

-- Code Review Mode with inline comments

local review_bufnr = nil
local review_winid = nil
local review_comments = {}

function M.start_review(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  -- Get file content and LSP info
  local lsp = require("luca.lsp")
  local ast_info = lsp.get_ast_info(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- Create review request
  local agent = require("luca.agent")
  local message = string.format(
    "Please review the following code file. Provide inline comments and suggestions for improvements:\n\n%s",
    content
  )
  
  if ast_info then
    message = message .. "\n\nLSP Information:\n" .. lsp.format_lsp_context(ast_info)
  end
  
  -- Send to agent
  agent.send_message(message, function(response)
    M.parse_review_response(response, bufnr)
  end)
  
  vim.notify("Starting code review...", vim.log.levels.INFO)
end

function M.parse_review_response(response, bufnr)
  -- Parse review comments from AI response
  review_comments = {}
  
  -- Look for line number patterns: "Line 10:", "L10:", etc.
  for line_num, comment in response:gmatch("Line%s+(%d+):%s*(.-)\n") do
    table.insert(review_comments, {
      line = tonumber(line_num) - 1, -- 0-indexed
      comment = comment,
    })
  end
  
  -- Also look for markdown-style comments
  for line_num, comment in response:gmatch("```lua:line:(%d+)\n(.-)```") do
    table.insert(review_comments, {
      line = tonumber(line_num) - 1,
      comment = comment,
    })
  end
  
  -- Show review in floating window
  M.show_review(bufnr)
end

function M.show_review(bufnr)
  local width = math.floor(vim.o.columns * 0.4)
  local height = math.floor(vim.o.lines * 0.7)
  local col = vim.o.columns - width - 5
  local row = math.floor((vim.o.lines - height) / 2)
  
  review_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(review_bufnr, "luca-review")
  vim.api.nvim_buf_set_option(review_bufnr, "filetype", "markdown")
  
  local lines = { "# Code Review", "" }
  for _, comment in ipairs(review_comments) do
    table.insert(lines, string.format("## Line %d", comment.line + 1))
    table.insert(lines, comment.comment)
    table.insert(lines, "")
  end
  
  vim.api.nvim_buf_set_lines(review_bufnr, 0, -1, false, lines)
  
  review_winid = vim.api.nvim_open_win(review_bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    title = " Code Review ",
    style = "minimal",
  })
  
  -- Add keymaps
  vim.api.nvim_buf_set_keymap(review_bufnr, "n", "q", "", {
    callback = function()
      M.close_review()
    end,
  })
  
  -- Set virtual text annotations on original buffer
  M.add_inline_comments(bufnr)
end

function M.add_inline_comments(bufnr)
  local ns = vim.api.nvim_create_namespace("luca_review")
  
  for _, comment in ipairs(review_comments) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, comment.line, 0, {
      virt_text = { { "💬 Review", "Comment" } },
      virt_text_pos = "eol",
    })
  end
end

function M.close_review()
  if review_winid and vim.api.nvim_win_is_valid(review_winid) then
    vim.api.nvim_win_close(review_winid, true)
  end
  review_winid = nil
  review_bufnr = nil
  review_comments = {}
end

return M

