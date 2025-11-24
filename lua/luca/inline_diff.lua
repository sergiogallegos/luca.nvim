local M = {}

-- Inline diff visualization with accept/reject functionality (Cursor-style)

local pending_changes = {}  -- Track pending changes per buffer
local namespace_id = vim.api.nvim_create_namespace("luca_inline_diff")

-- Highlight groups for diff (define once, use many times)
local function setup_highlights()
  vim.api.nvim_set_hl(0, "LucaDiffAdd", { fg = "#00ff00", bg = "#004400", bold = true })
  vim.api.nvim_set_hl(0, "LucaDiffDelete", { fg = "#ff0000", bg = "#440000", bold = true })
  vim.api.nvim_set_hl(0, "LucaDiffChange", { fg = "#ffff00", bg = "#444400", bold = true })
  vim.api.nvim_set_hl(0, "LucaDiffText", { fg = "#ffffff", bg = "#0000ff", bold = true })
end

-- Setup highlights on load
setup_highlights()

-- Parse diff-like changes from AI response
function M.parse_changes(text, current_file)
  local changes = {
    additions = {},
    deletions = {},
    modifications = {},
    full_replacement = nil,  -- Store full file content for code blocks
  }
  
  -- Try to parse unified diff format
  if text:match("^diff ") or text:match("^---") then
    local diff = require("luca.diff")
    local hunks = diff.parse_unified_diff(text)
    for _, hunk in ipairs(hunks) do
      if hunk.file == current_file or not hunk.file then
        for _, line in ipairs(hunk.lines) do
          if line:match("^%+") then
            table.insert(changes.additions, {
              line = line:sub(2),
              line_num = hunk.start_old + #changes.additions,
            })
          elseif line:match("^-") then
            table.insert(changes.deletions, {
              line = line:sub(2),
              line_num = hunk.start_old + #changes.deletions,
            })
          end
        end
      end
    end
    return changes
  end
  
  -- Try to parse code blocks with context
  local code_blocks = require("luca.patch").parse_code_blocks(text)
  if #code_blocks > 0 then
    -- Store full replacement content for easier application
    changes.full_replacement = code_blocks[1].content
    
    -- Also compute line-by-line diff for visualization
    local bufnr = vim.fn.bufnr(current_file)
    if bufnr == -1 then
      bufnr = vim.api.nvim_get_current_buf()
    end
    
    local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local new_lines = vim.split(code_blocks[1].content, "\n")
    
    -- Simple line-by-line diff for visualization
    local i = 1
    local j = 1
    while i <= #new_lines or j <= #current_lines do
      if i <= #new_lines and j <= #current_lines then
        if new_lines[i] ~= current_lines[j] then
          -- Modified line
          table.insert(changes.deletions, { line = current_lines[j], line_num = j })
          table.insert(changes.additions, { line = new_lines[i], line_num = j })
          i = i + 1
          j = j + 1
        else
          i = i + 1
          j = j + 1
        end
      elseif i <= #new_lines then
        -- Addition
        table.insert(changes.additions, { line = new_lines[i], line_num = j })
        i = i + 1
        j = j + 1
      elseif j <= #current_lines then
        -- Deletion
        table.insert(changes.deletions, { line = current_lines[j], line_num = j })
        j = j + 1
      end
    end
  end
  
  return changes
end

-- Show inline diff visualization
function M.show_inline_diff(bufnr, changes)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  
  -- Store changes for this buffer
  pending_changes[bufnr] = changes
  
  -- Ensure highlights are set
  setup_highlights()
  
  -- Highlight deletions (red background on the line)
  for _, del in ipairs(changes.deletions) do
    if del.line_num > 0 and del.line_num <= vim.api.nvim_buf_line_count(bufnr) then
      local line_idx = del.line_num - 1
      local line_text = vim.api.nvim_buf_get_lines(bufnr, line_idx, line_idx + 1, false)[1] or ""
      local line_length = #line_text
      
      -- Highlight the entire line with red background
      vim.api.nvim_buf_set_extmark(bufnr, namespace_id, line_idx, 0, {
        hl_group = "LucaDiffDelete",
        end_row = line_idx,
        end_col = line_length,
      })
      
      -- Add virtual text indicator
      vim.api.nvim_buf_set_extmark(bufnr, namespace_id, line_idx, 0, {
        virt_text = { { " - ", "LucaDiffDelete" } },
        virt_text_pos = "overlay",
      })
    end
  end
  
  -- Show additions as virtual text (green) - show after the line
  for _, add in ipairs(changes.additions) do
    local line_num = add.line_num - 1
    if line_num >= 0 and line_num < vim.api.nvim_buf_line_count(bufnr) then
      -- Show addition indicator on the line where it should be inserted
      vim.api.nvim_buf_set_extmark(bufnr, namespace_id, line_num, 0, {
        virt_text = { { "+ " .. add.line, "LucaDiffAdd" } },
        virt_text_pos = "eol",
      })
    elseif line_num >= vim.api.nvim_buf_line_count(bufnr) then
      -- Addition at end of file
      local last_line = vim.api.nvim_buf_line_count(bufnr) - 1
      if last_line >= 0 then
        vim.api.nvim_buf_set_extmark(bufnr, namespace_id, last_line, 0, {
          virt_text = { { "+ " .. add.line, "LucaDiffAdd" } },
          virt_text_pos = "eol",
        })
      end
    end
  end
  
  -- Add keymaps for accept/reject
  local config = require("luca").config()
  vim.api.nvim_buf_set_keymap(bufnr, "n", config.keymaps.apply_suggestion or "<C-a>", "", {
    callback = function()
      M.accept_all_changes(bufnr)
    end,
    desc = "Accept all changes",
  })
  
  vim.api.nvim_buf_set_keymap(bufnr, "n", config.keymaps.reject_suggestion or "<C-r>", "", {
    callback = function()
      M.reject_all_changes(bufnr)
    end,
    desc = "Reject all changes",
  })
  
  vim.notify("Changes previewed. Press <C-a> to accept, <C-r> to reject", vim.log.levels.INFO)
end

-- Accept all changes
function M.accept_all_changes(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local changes = pending_changes[bufnr]
  
  if not changes then
    vim.notify("No pending changes to accept", vim.log.levels.WARN)
    return
  end
  
  -- If we have a full replacement (from code blocks), use it directly
  if changes.full_replacement then
    local new_lines = vim.split(changes.full_replacement, "\n")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  else
    -- Otherwise, apply line-by-line changes
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local new_lines = {}
    
    -- Sort deletions and additions by line number
    local deletions_sorted = {}
    for _, del in ipairs(changes.deletions) do
      table.insert(deletions_sorted, del)
    end
    table.sort(deletions_sorted, function(a, b) return a.line_num < b.line_num end)
    
    local additions_sorted = {}
    for _, add in ipairs(changes.additions) do
      table.insert(additions_sorted, add)
    end
    table.sort(additions_sorted, function(a, b) return a.line_num < b.line_num end)
    
    -- Apply changes
    local del_idx = 1
    local add_idx = 1
    
    for i = 1, #lines do
      -- Check if this line should be deleted
      local should_delete = false
      if del_idx <= #deletions_sorted and deletions_sorted[del_idx].line_num == i then
        should_delete = true
        del_idx = del_idx + 1
      end
      
      if not should_delete then
        table.insert(new_lines, lines[i])
      end
      
      -- Check if we should add lines at this position
      while add_idx <= #additions_sorted and additions_sorted[add_idx].line_num == i do
        table.insert(new_lines, additions_sorted[add_idx].line)
        add_idx = add_idx + 1
      end
    end
    
    -- Handle additions at the end
    while add_idx <= #additions_sorted do
      table.insert(new_lines, additions_sorted[add_idx].line)
      add_idx = add_idx + 1
    end
    
    -- Apply changes
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  end
  
  -- Clear highlights
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  pending_changes[bufnr] = nil
  
  vim.notify("Changes accepted", vim.log.levels.INFO)
end

-- Reject all changes
function M.reject_all_changes(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  -- Clear highlights
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  pending_changes[bufnr] = nil
  
  vim.notify("Changes rejected", vim.log.levels.INFO)
end

-- Process AI response and show inline diff
function M.process_ai_response(response, target_file)
  target_file = target_file or vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  local bufnr = vim.fn.bufnr(target_file)
  
  if bufnr == -1 then
    -- File not open, open it first
    vim.cmd("edit " .. target_file)
    bufnr = vim.api.nvim_get_current_buf()
  end
  
  local changes = M.parse_changes(response, target_file)
  
  if #changes.additions > 0 or #changes.deletions > 0 then
    M.show_inline_diff(bufnr, changes)
  else
    vim.notify("No changes detected in response", vim.log.levels.WARN)
  end
end

return M

