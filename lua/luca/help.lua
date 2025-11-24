local M = {}

-- Help Window - Show keybindings like ChatGPT.nvim

local help_winid = nil
local help_bufnr = nil

local keybindings = {
  {
    key = "<C-Enter>",
    description = "Submit message",
    mode = "Both",
  },
  {
    key = "<C-y>",
    description = "Copy/yank last answer",
    mode = "Both",
  },
  {
    key = "<C-o>",
    description = "Toggle settings window",
    mode = "Both",
  },
  {
    key = "<C-h>",
    description = "Toggle help window",
    mode = "Both",
  },
  {
    key = "<C-c>",
    description = "Close chat window",
    mode = "Both",
  },
  {
    key = "<C-p>",
    description = "Toggle sessions list",
    mode = "Chat",
  },
  {
    key = "<C-n>",
    description = "Start new session",
    mode = "Chat",
  },
  {
    key = "<C-a>",
    description = "Switch agent",
    mode = "Chat",
  },
  {
    key = "<Esc>",
    description = "Close window",
    mode = "Both",
  },
}

function M.toggle()
  if help_winid and vim.api.nvim_win_is_valid(help_winid) then
    M.close()
  else
    M.open()
  end
end

function M.open()
  -- Get chat window from ui module
  local chat_winid = nil
  local ok, ui = pcall(require, "luca.ui")
  if ok then
    chat_winid = ui.get_chat_winid()
  end
  
  if not chat_winid or not vim.api.nvim_win_is_valid(chat_winid) then
    -- Fallback: try to find chat window by buffer name
    local chat_bufnr = vim.fn.bufnr("luca-chat")
    if chat_bufnr ~= -1 then
      local wins = vim.fn.win_findbuf(chat_bufnr)
      if #wins > 0 then
        chat_winid = wins[1]
      end
    end
  end
  
  if not chat_winid or not vim.api.nvim_win_is_valid(chat_winid) then
    vim.notify("Chat window must be open to show help", vim.log.levels.WARN)
    return
  end
  
  local chat_config = vim.api.nvim_win_get_config(chat_winid)
  local width = 50
  local height = #keybindings + 4
  local col = chat_config.col[false] + chat_config.width - width - 2
  local row = chat_config.row[false] + 2
  
  help_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(help_bufnr, "luca-help")
  
  local lines = { "Keybindings:", "" }
  for _, binding in ipairs(keybindings) do
    table.insert(lines, string.format("%-15s %s [%s]", binding.key, binding.description, binding.mode))
  end
  table.insert(lines, "")
  table.insert(lines, "Press q or <Esc> to close")
  
  vim.api.nvim_buf_set_lines(help_bufnr, 0, -1, false, lines)
  
  help_winid = vim.api.nvim_open_win(help_bufnr, false, {
    relative = "win",
    win = chat_winid,
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    title = " Help ",
    style = "minimal",
  })
  
  vim.api.nvim_win_set_option(help_winid, "wrap", true)
  
  -- Add keymaps
  vim.api.nvim_buf_set_keymap(help_bufnr, "n", "q", "", {
    callback = function()
      M.close()
    end,
  })
  
  vim.api.nvim_buf_set_keymap(help_bufnr, "n", "<Esc>", "", {
    callback = function()
      M.close()
    end,
  })
end

function M.close()
  if help_winid and vim.api.nvim_win_is_valid(help_winid) then
    vim.api.nvim_win_close(help_winid, true)
  end
  help_winid = nil
  help_bufnr = nil
end

return M

