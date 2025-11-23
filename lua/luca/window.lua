local M = {}

-- Window management with resizing support

local windows = {}
local resize_mode = false

function M.create_resizable_window(config, bufnr, opts)
  local width = math.floor(vim.o.columns * (opts.width or config.width))
  local height = math.floor(vim.o.lines * (opts.height or config.height))
  
  local col = 0
  local row = 0
  
  if opts.position == "center" or config.position == "center" then
    col = math.floor((vim.o.columns - width) / 2)
    row = math.floor((vim.o.lines - height) / 2)
  elseif opts.position == "top" or config.position == "top" then
    col = math.floor((vim.o.columns - width) / 2)
    row = 1
  elseif opts.position == "bottom" or config.position == "bottom" then
    col = math.floor((vim.o.columns - width) / 2)
    row = vim.o.lines - height - 1
  elseif opts.position == "right" then
    col = vim.o.columns - width - 1
    row = math.floor((vim.o.lines - height) / 2)
  elseif opts.position == "left" then
    col = 1
    row = math.floor((vim.o.lines - height) / 2)
  end
  
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = opts.border or config.border,
    title = opts.title or "",
    style = "minimal",
  })
  
  -- Set winblend option after window creation (it's not a valid option for nvim_open_win)
  if opts.winblend or config.winblend then
    vim.api.nvim_win_set_option(winid, "winblend", opts.winblend or config.winblend)
  end
  
  -- Store window info
  windows[winid] = {
    bufnr = bufnr,
    config = config,
    opts = opts,
    width = width,
    height = height,
    col = col,
    row = row,
  }
  
  -- Add resize keymaps if enabled
  if opts.resizable ~= false then
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-w>=", "", {
      callback = function()
        M.start_resize(winid)
      end,
    })
  end
  
  return winid
end

function M.start_resize(winid)
  if not windows[winid] then
    return
  end
  
  resize_mode = true
  vim.notify("Resize mode: Use arrow keys to resize, Enter to confirm, Esc to cancel", vim.log.levels.INFO)
  
  local win = windows[winid]
  local original_width = win.width
  local original_height = win.height
  
  local function resize(delta_w, delta_h)
    local new_width = math.max(20, math.min(vim.o.columns - 10, win.width + delta_w))
    local new_height = math.max(5, math.min(vim.o.lines - 10, win.height + delta_h))
    
    win.width = new_width
    win.height = new_height
    
    vim.api.nvim_win_set_width(winid, new_width)
    vim.api.nvim_win_set_height(winid, new_height)
  end
  
  -- Create temporary keymaps
  local function cleanup()
    resize_mode = false
    vim.api.nvim_buf_del_keymap(win.bufnr, "n", "<Left>")
    vim.api.nvim_buf_del_keymap(win.bufnr, "n", "<Right>")
    vim.api.nvim_buf_del_keymap(win.bufnr, "n", "<Up>")
    vim.api.nvim_buf_del_keymap(win.bufnr, "n", "<Down>")
    vim.api.nvim_buf_del_keymap(win.bufnr, "n", "<CR>")
    vim.api.nvim_buf_del_keymap(win.bufnr, "n", "<Esc>")
  end
  
  vim.api.nvim_buf_set_keymap(win.bufnr, "n", "<Left>", "", {
    callback = function()
      resize(-5, 0)
    end,
  })
  
  vim.api.nvim_buf_set_keymap(win.bufnr, "n", "<Right>", "", {
    callback = function()
      resize(5, 0)
    end,
  })
  
  vim.api.nvim_buf_set_keymap(win.bufnr, "n", "<Up>", "", {
    callback = function()
      resize(0, -3)
    end,
  })
  
  vim.api.nvim_buf_set_keymap(win.bufnr, "n", "<Down>", "", {
    callback = function()
      resize(0, 3)
    end,
  })
  
  vim.api.nvim_buf_set_keymap(win.bufnr, "n", "<CR>", "", {
    callback = function()
      cleanup()
      vim.notify("Resize confirmed", vim.log.levels.INFO)
    end,
  })
  
  vim.api.nvim_buf_set_keymap(win.bufnr, "n", "<Esc>", "", {
    callback = function()
      win.width = original_width
      win.height = original_height
      vim.api.nvim_win_set_width(winid, original_width)
    vim.api.nvim_win_set_height(winid, original_height)
      cleanup()
      vim.notify("Resize cancelled", vim.log.levels.INFO)
    end,
  })
end

function M.close_window(winid)
  if windows[winid] then
    windows[winid] = nil
  end
end

return M

