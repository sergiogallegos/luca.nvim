local M = {}

-- Memory Files Support - .cursor/rules, CLAUDE.md like CodeCompanion.nvim

local memory_files = {
  ".cursor/rules",
  "CLAUDE.md",
  ".claude.md",
  ".cursorrules",
}

function M.load_memory_files()
  local cwd = vim.fn.getcwd()
  local memory_content = {}
  
  for _, pattern in ipairs(memory_files) do
    local file_path = vim.fn.findfile(pattern, cwd .. ";")
    if file_path ~= "" then
      local full_path = vim.fn.fnamemodify(file_path, ":p")
      local file = io.open(full_path, "r")
      if file then
        local content = file:read("*all")
        file:close()
        table.insert(memory_content, {
          path = pattern,
          content = content,
        })
      end
    end
  end
  
  return memory_content
end

function M.get_memory_context()
  local memory_files = M.load_memory_files()
  if #memory_files == 0 then
    return nil
  end
  
  local context = "Memory files (project rules and context):\n\n"
  for _, mem in ipairs(memory_files) do
    context = context .. "=== " .. mem.path .. " ===\n"
    context = context .. mem.content .. "\n\n"
  end
  
  return context
end

function M.has_memory_files()
  local memory_files = M.load_memory_files()
  return #memory_files > 0
end

return M

