local M = {}

-- Enhanced diff handling with hunk-by-hunk acceptance

function M.parse_unified_diff(diff_text)
  local hunks = {}
  local current_hunk = nil
  local current_file = nil
  
  for line in diff_text:gmatch("[^\n]+") do
    -- File header
    if line:match("^---") or line:match("^%+%+%+") then
      if line:match("^%+%+%+") then
        current_file = line:match("^%+%+%+ (.+)")
      end
    -- Hunk header
    elseif line:match("^@@") then
      if current_hunk then
        table.insert(hunks, current_hunk)
      end
      local start_old, count_old, start_new, count_new = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
      current_hunk = {
        file = current_file,
        start_old = tonumber(start_old),
        count_old = tonumber(count_old) or 1,
        start_new = tonumber(start_new),
        count_new = tonumber(count_new) or 1,
        lines = {},
      }
    -- Hunk content
    elseif current_hunk then
      table.insert(current_hunk.lines, line)
    end
  end
  
  if current_hunk then
    table.insert(hunks, current_hunk)
  end
  
  return hunks
end

function M.show_diff_preview(diff_text, filepath)
  local hunks = M.parse_unified_diff(diff_text)
  
  if #hunks == 0 then
    -- Fallback: show as regular diff
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)
    
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "luca-diff-preview")
    
    local lines = vim.split(diff_text, "\n")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "filetype", "diff")
    
    local winid = vim.api.nvim_open_win(bufnr, true, {
      relative = "editor",
      width = width,
      height = height,
      col = col,
      row = row,
      border = "rounded",
      title = " Diff Preview ",
      style = "minimal",
    })
    
    local config = require("luca").config()
    vim.api.nvim_buf_set_keymap(bufnr, "n", config.keymaps.apply_suggestion, "", {
      callback = function()
        -- Apply entire diff
        M.apply_diff(diff_text, filepath)
        vim.api.nvim_win_close(winid, true)
      end,
    })
    
    vim.api.nvim_buf_set_keymap(bufnr, "n", config.keymaps.reject_suggestion, "", {
      callback = function()
        vim.api.nvim_win_close(winid, true)
      end,
    })
    
    return
  end
  
  -- Show hunk-by-hunk preview
  local hunk_index = 1
  
  local function show_hunk()
    if hunk_index > #hunks then
      vim.notify("All hunks processed", vim.log.levels.INFO)
      return
    end
    
    local hunk = hunks[hunk_index]
    local width = math.floor(vim.o.columns * 0.7)
    local height = math.min(20, #hunk.lines + 6)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)
    
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "luca-hunk-" .. hunk_index)
    
    local lines = {
      string.format("Hunk %d of %d", hunk_index, #hunks),
      string.format("File: %s", hunk.file or filepath or "current file"),
      "",
    }
    for _, line in ipairs(hunk.lines) do
      table.insert(lines, line)
    end
    table.insert(lines, "")
    table.insert(lines, "[a]ccept [r]eject [n]ext [p]revious [q]uit")
    
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "filetype", "diff")
    
    local winid = vim.api.nvim_open_win(bufnr, true, {
      relative = "editor",
      width = width,
      height = height,
      col = col,
      row = row,
      border = "rounded",
      title = string.format(" Hunk %d/%d ", hunk_index, #hunks),
      style = "minimal",
    })
    
    -- Keymaps
    vim.api.nvim_buf_set_keymap(bufnr, "n", "a", "", {
      callback = function()
        M.apply_hunk(hunk, filepath)
        vim.api.nvim_win_close(winid, true)
        hunk_index = hunk_index + 1
        show_hunk()
      end,
    })
    
    vim.api.nvim_buf_set_keymap(bufnr, "n", "r", "", {
      callback = function()
        vim.api.nvim_win_close(winid, true)
        hunk_index = hunk_index + 1
        show_hunk()
      end,
    })
    
    vim.api.nvim_buf_set_keymap(bufnr, "n", "n", "", {
      callback = function()
        vim.api.nvim_win_close(winid, true)
        hunk_index = hunk_index + 1
        show_hunk()
      end,
    })
    
    vim.api.nvim_buf_set_keymap(bufnr, "n", "p", "", {
      callback = function()
        vim.api.nvim_win_close(winid, true)
        hunk_index = math.max(1, hunk_index - 1)
        show_hunk()
      end,
    })
    
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "", {
      callback = function()
        vim.api.nvim_win_close(winid, true)
      end,
    })
  end
  
  show_hunk()
end

function M.apply_hunk(hunk, filepath)
  -- Apply a single hunk to a file
  filepath = filepath or vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  
  if not filepath or filepath == "" then
    vim.notify("No file to apply hunk to", vim.log.levels.ERROR)
    return false
  end
  
  local file = io.open(filepath, "r")
  if not file then
    vim.notify("Could not open file: " .. filepath, vim.log.levels.ERROR)
    return false
  end
  
  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()
  
  -- Apply hunk (simplified - in production use proper diff algorithm)
  local new_lines = {}
  local hunk_line_idx = 1
  
  for i = 1, #lines do
    if i < hunk.start_old then
      table.insert(new_lines, lines[i])
    elseif i >= hunk.start_old and i < hunk.start_old + hunk.count_old then
      -- Skip old lines, insert new ones
      while hunk_line_idx <= #hunk.lines do
        local hunk_line = hunk.lines[hunk_line_idx]
        if hunk_line:match("^%+") then
          table.insert(new_lines, hunk_line:sub(2))
        elseif hunk_line:match("^-") then
          -- Skip this line (deleted)
        end
        hunk_line_idx = hunk_line_idx + 1
      end
    else
      table.insert(new_lines, lines[i])
    end
  end
  
  -- Write back
  file = io.open(filepath, "w")
  if file then
    file:write(table.concat(new_lines, "\n"))
    file:close()
    vim.notify("Applied hunk to " .. filepath, vim.log.levels.INFO)
    return true
  end
  
  return false
end

function M.apply_diff(diff_text, filepath)
  -- Apply entire diff (fallback)
  local hunks = M.parse_unified_diff(diff_text)
  for _, hunk in ipairs(hunks) do
    M.apply_hunk(hunk, filepath or hunk.file)
  end
end

return M

