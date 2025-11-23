-- Test helper for luca.nvim

local M = {}

function M.setup()
  -- Setup test environment
  _G.luca_test_mode = true
end

function M.teardown()
  _G.luca_test_mode = nil
end

function M.mock_vim()
  -- Mock vim API for testing
  local mock_vim = {
    api = {
      nvim_create_buf = function() return 1 end,
      nvim_open_win = function() return 1 end,
      nvim_buf_set_lines = function() end,
      nvim_buf_get_lines = function() return {} end,
      nvim_win_close = function() end,
      nvim_get_current_buf = function() return 1 end,
      nvim_get_current_win = function() return 1 end,
      nvim_win_is_valid = function() return true end,
      nvim_buf_is_valid = function() return true end,
      nvim_buf_set_option = function() end,
      nvim_win_set_option = function() end,
      nvim_buf_set_keymap = function() end,
      nvim_notify = function() end,
    },
    fn = {
      getcwd = function() return "/test" end,
      line = function() return 1 end,
      col = function() return 1 end,
      globpath = function() return {} end,
      filereadable = function() return false end,
      mkdir = function() end,
    },
    o = {
      columns = 80,
      lines = 24,
    },
    json = {
      encode = function(t) return vim.inspect(t) end,
      decode = function(s) return {} end,
    },
  }
  return mock_vim
end

return M

