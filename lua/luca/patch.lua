local M = {}

-- Parse and apply code patches/suggestions from AI responses

function M.parse_code_blocks(text)
  local code_blocks = {}
  local current_block = nil
  local in_block = false
  local language = nil
  
  for line in text:gmatch("[^\n]+") do
    -- Check for code block start
    local lang_match = line:match("^```(%w*)")
    if lang_match then
      in_block = true
      language = lang_match ~= "" and lang_match or nil
      current_block = { language = language, lines = {} }
    -- Check for code block end
    elseif line == "```" and in_block then
      if current_block then
        current_block.content = table.concat(current_block.lines, "\n")
        table.insert(code_blocks, current_block)
      end
      in_block = false
      current_block = nil
      language = nil
    -- Add line to current block
    elseif in_block and current_block then
      table.insert(current_block.lines, line)
    end
  end
  
  -- Handle unclosed block
  if in_block and current_block then
    current_block.content = table.concat(current_block.lines, "\n")
    table.insert(code_blocks, current_block)
  end
  
  return code_blocks
end

function M.parse_file_paths(text)
  local file_paths = {}
  
  -- Look for file path patterns in the text
  -- Pattern: file: path/to/file or ```path/to/file
  for path in text:gmatch("file:%s*([^\n]+)") do
    table.insert(file_paths, path:match("^%s*(.-)%s*$"))
  end
  
  for path in text:gmatch("```([^\n]+%.%w+)") do
    if not path:match("^%w+$") then -- Not just a language identifier
      table.insert(file_paths, path)
    end
  end
  
  return file_paths
end

function M.apply_to_file(filepath, content)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  if dir ~= "." then
    vim.fn.mkdir(dir, "p")
  end
  
  local file = io.open(filepath, "w")
  if file then
    file:write(content)
    file:close()
    return true
  end
  return false
end

function M.apply_suggestion(suggestion, options)
  options = options or {}
  local code_blocks = M.parse_code_blocks(suggestion)
  local file_paths = M.parse_file_paths(suggestion)
  
  if #code_blocks == 0 then
    vim.notify("No code blocks found in suggestion", vim.log.levels.WARN)
    return false
  end
  
  -- If file paths are specified, apply to those files
  if #file_paths > 0 then
    for i, path in ipairs(file_paths) do
      if code_blocks[i] then
        if M.apply_to_file(path, code_blocks[i].content) then
          vim.notify("Applied to: " .. path, vim.log.levels.INFO)
          if options.open_files then
            vim.cmd("edit " .. path)
          end
        else
          vim.notify("Failed to apply to: " .. path, vim.log.levels.ERROR)
        end
      end
    end
  else
    -- Apply to current buffer
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.split(code_blocks[1].content, "\n")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.notify("Applied suggestion to current buffer", vim.log.levels.INFO)
  end
  
  return true
end

function M.show_preview(suggestion)
  -- Check if suggestion contains a diff
  if suggestion:match("^diff ") or suggestion:match("^---") then
    local diff = require("luca.diff")
    local filepath = M.parse_file_paths(suggestion)[1]
    diff.show_diff_preview(suggestion, filepath)
    return
  end
  
  -- Show preview in a floating window
  local code_blocks = M.parse_code_blocks(suggestion)
  
  if #code_blocks == 0 then
    return
  end
  
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.7)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "luca-preview")
  
  local lines = vim.split(code_blocks[1].content, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  -- Set filetype if language is detected
  if code_blocks[1].language then
    vim.api.nvim_buf_set_option(bufnr, "filetype", code_blocks[1].language)
  end
  
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    title = " Preview Suggestion ",
    style = "minimal",
  })
  
  -- Add keymaps
  local config = require("luca").config()
  vim.api.nvim_buf_set_keymap(bufnr, "n", config.keymaps.apply_suggestion, "", {
    callback = function()
      M.apply_suggestion(suggestion, { open_files = true })
      vim.api.nvim_win_close(winid, true)
    end,
  })
  
  vim.api.nvim_buf_set_keymap(bufnr, "n", config.keymaps.reject_suggestion, "", {
    callback = function()
      vim.api.nvim_win_close(winid, true)
    end,
  })
end

return M

