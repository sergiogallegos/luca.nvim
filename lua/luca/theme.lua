local M = {}

-- Theme adaptation - match user's colorscheme

local function get_colorscheme_colors()
  local colors = {}
  
  -- Try to get colors from highlight groups
  local function get_hl(name)
    local hl = vim.api.nvim_get_hl_by_name(name, true)
    if hl and hl.foreground then
      return string.format("#%06x", hl.foreground)
    end
    return nil
  end
  
  -- Get common colors
  colors.bg = get_hl("Normal") or "#000000"
  colors.fg = get_hl("Normal") or "#ffffff"
  colors.border = get_hl("FloatBorder") or get_hl("Normal") or "#444444"
  colors.title = get_hl("Title") or get_hl("Normal") or "#ffffff"
  colors.comment = get_hl("Comment") or "#888888"
  colors.keyword = get_hl("Keyword") or "#ff6b6b"
  colors.string = get_hl("String") or "#51cf66"
  colors.function_color = get_hl("Function") or "#339af0"
  
  -- Detect if dark or light theme
  local bg_hex = colors.bg:match("#(%x%x%x%x%x%x)")
  if bg_hex then
    local r = tonumber(bg_hex:sub(1, 2), 16)
    local g = tonumber(bg_hex:sub(3, 4), 16)
    local b = tonumber(bg_hex:sub(5, 6), 16)
    local brightness = (r + g + b) / 3
    colors.is_dark = brightness < 128
  else
    colors.is_dark = vim.o.background == "dark"
  end
  
  return colors
end

function M.adapt_border(config)
  local colors = get_colorscheme_colors()
  
  -- If border is a string, use it as-is
  if type(config.border) == "string" then
    return config.border
  end
  
  -- Otherwise, adapt based on theme
  if colors.is_dark then
    return config.border or "rounded"
  else
    return config.border or "single"
  end
end

function M.get_theme_colors()
  return get_colorscheme_colors()
end

function M.setup_highlights()
  local colors = get_colorscheme_colors()
  
  -- Define custom highlight groups for luca
  vim.api.nvim_set_hl(0, "LucaChatUser", {
    fg = colors.fg,
    bold = true,
  })
  
  vim.api.nvim_set_hl(0, "LucaChatAssistant", {
    fg = colors.function_color or colors.fg,
  })
  
  vim.api.nvim_set_hl(0, "LucaChatSystem", {
    fg = colors.comment,
    italic = true,
  })
  
  vim.api.nvim_set_hl(0, "LucaBorder", {
    fg = colors.border,
  })
end

function M.setup()
  M.setup_highlights()
end

return M

