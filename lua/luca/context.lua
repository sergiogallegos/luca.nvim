local M = {}

local context_cache = {}

local function get_buffer_context()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  return {
    path = path,
    content = content,
    line_count = #lines,
  }
end

local function get_project_files(max_files)
  max_files = max_files or 10
  local files = {}
  
  -- Get current working directory
  local cwd = vim.fn.getcwd()
  
  -- Limit search to avoid slowness - only search in common directories
  local search_dirs = { ".", "src", "lib", "lua" }
  local patterns = { "*.lua", "*.py", "*.js", "*.ts", "*.go", "*.rs", "*.java", "*.cpp", "*.c", "*.h" }
  
  for _, search_dir in ipairs(search_dirs) do
    if #files >= max_files then
      break
    end
    
    for _, pattern in ipairs(patterns) do
      if #files >= max_files then
        break
      end
      
      local search_path = search_dir == "." and pattern or search_dir .. "/**/" .. pattern
      local found_files = vim.fn.globpath(cwd, search_path, false, true)
      
      for _, filepath in ipairs(found_files) do
        if #files >= max_files then
          break
        end
        
        -- Skip if file is too large (>50KB to be faster)
        local file = io.open(filepath, "r")
        if file then
          local content = file:read("*all")
          file:close()
          
          -- Only include files under 50KB to avoid token limits and improve speed
          if #content < 50000 then
            table.insert(files, {
              path = filepath,
              content = content,
            })
          end
        end
      end
    end
  end
  
  return files
end

function M.setup(config)
  M.config = config
end

function M.get_buffer_context()
  return get_buffer_context()
end

function M.get_context()
  local context = {
    buffer = nil,
    files = {},
  }
  
  if M.config.include_buffer then
    context.buffer = get_buffer_context()
  end
  
  if M.config.include_tree then
    context.files = get_project_files(M.config.max_files)
  end
  
  return context
end

function M.update_cache()
  context_cache = M.get_context()
end

function M.get_cached()
  return context_cache
end

return M

