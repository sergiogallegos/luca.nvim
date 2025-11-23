local M = {}

-- Different UI modes: floating, sidebar, minimal

local current_mode = "floating"
local sidebar_winid = nil
local sidebar_bufnr = nil

function M.set_mode(mode)
  current_mode = mode
  vim.notify("Switched to " .. mode .. " mode", vim.log.levels.INFO)
end

function M.get_mode()
  return current_mode
end

function M.create_sidebar(config)
  local width = math.floor(vim.o.columns * (config.sidebar_width or 0.3))
  local height = vim.o.lines - 2
  
  -- Create sidebar buffer
  sidebar_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(sidebar_bufnr, "luca-sidebar")
  vim.api.nvim_buf_set_option(sidebar_bufnr, "filetype", "luca-chat")
  vim.api.nvim_buf_set_option(sidebar_bufnr, "buftype", "nofile")
  
  -- Create sidebar window (split)
  vim.cmd("vsplit")
  sidebar_winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(sidebar_winid, sidebar_bufnr)
  vim.api.nvim_win_set_width(sidebar_winid, width)
  
  -- Configure sidebar
  vim.api.nvim_win_set_option(sidebar_winid, "wrap", true)
  vim.api.nvim_win_set_option(sidebar_winid, "number", false)
  
  return sidebar_winid, sidebar_bufnr
end

function M.create_minimal_window(config)
  local width = 40
  local height = 5
  local col = vim.o.columns - width - 5
  local row = vim.o.lines - height - 5
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "luca-minimal")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "luca-input")
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "single",
    title = " Luca ",
    style = "minimal",
  })
  
  return winid, bufnr
end

function M.close_sidebar()
  if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    vim.api.nvim_win_close(sidebar_winid, true)
  end
  sidebar_winid = nil
  sidebar_bufnr = nil
end

return M

