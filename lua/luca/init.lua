local M = {}

local config = {}
local default_config = {
  agents = {
    default = "openai",
    providers = {
      openai = {
        api_key = nil,
        model = "gpt-4",
        base_url = "https://api.openai.com/v1",
        temperature = 0.7,
        max_tokens = nil, -- nil means use provider default
        top_p = 1.0,
        frequency_penalty = 0.0,
        presence_penalty = 0.0,
      },
    },
  },
  ui = {
    width = 0.35,  -- Width as fraction of screen (0.0 to 1.0) - smaller like Cursor
    height = 0.35,  -- Height as fraction of screen (0.0 to 1.0) - much smaller so code is visible
    border = "rounded", -- Border style: "single", "double", "rounded", "solid", "shadow"
    position = "right",  -- Position: "right", "left", "center", "top", "bottom"
    winblend = 10,  -- Window transparency (0-100)
    title = " Luca ",  -- Window title
  },
  history = {
    enabled = true,
    max_entries = 100,
    storage_path = vim.fn.stdpath("data") .. "/luca_history",
  },
  context = {
    include_buffer = true,
    include_tree = true,
    max_files = 10,
    auto_attach = true,
    use_lsp = true,
  },
  cache = {
    enabled = true,
    max_size = 100,
    ttl = 3600,
  },
  tokens = {
    max_context_tokens = 4000,
    enable_trimming = true,
  },
  ui_mode = "floating", -- floating, sidebar, minimal
  keymaps = {
    open = "<leader>lc",
    close = "<Esc>",
    send = "<CR>",
    history_prev = "<C-p>",
    history_next = "<C-n>",
    apply_suggestion = "<C-a>",
    reject_suggestion = "<C-r>",
    hover = "<leader>lh",
  },
}

function M.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config or {})
  
  -- Validate API keys (skip for providers that don't need them)
  for name, provider in pairs(config.agents.providers) do
    local requires_key = provider.requires_api_key ~= false
    if requires_key and not provider.api_key then
      provider.api_key = os.getenv(string.upper(name) .. "_API_KEY")
    end
  end
  
  -- Setup modules
  require("luca.ui").setup(config.ui)
  require("luca.agent").setup(config.agents)
  require("luca.history").setup(config.history)
  require("luca.context").setup(config.context)
  require("luca.statusline").setup()
  require("luca.theme").setup()
  require("luca.tools").setup()
  require("luca.cache").setup(config.cache or {})
  require("luca.embeddings").setup()
  require("luca.sessions").setup()
  
  -- Setup commands
  vim.api.nvim_create_user_command("LucaChat", function()
    require("luca.ui").open()
  end, { desc = "Open Luca chat window" })
  
  vim.api.nvim_create_user_command("LucaToggle", function()
    require("luca.ui").toggle()
  end, { desc = "Toggle Luca chat window" })
  
  vim.api.nvim_create_user_command("LucaHistory", function()
    require("luca.history").show()
  end, { desc = "Show Luca chat history" })
  
  vim.api.nvim_create_user_command("LucaAgent", function(opts)
    if opts.args and opts.args ~= "" then
      require("luca.agent").set_agent(opts.args)
    else
      require("luca.ui").show_agent_selector()
    end
  end, { desc = "Switch agent", nargs = "?" })
  
  vim.api.nvim_create_user_command("LucaApply", function(opts)
    local inline_diff = require("luca.inline_diff")
    local bufnr = vim.api.nvim_get_current_buf()
    
    -- Try to accept inline changes first
    inline_diff.accept_all_changes(bufnr)
    
    -- Fallback to old method if no inline changes
    local patch = require("luca.patch")
    local history = require("luca.history").get_current()
    if history and #history > 0 then
      local last_entry = history[#history]
      if last_entry.assistant then
        patch.apply_suggestion(last_entry.assistant, { open_files = true })
      end
    end
  end, { desc = "Accept and apply changes" })
  
  vim.api.nvim_create_user_command("LucaReject", function(opts)
    local inline_diff = require("luca.inline_diff")
    local bufnr = vim.api.nvim_get_current_buf()
    inline_diff.reject_all_changes(bufnr)
  end, { desc = "Reject all pending changes" })
  
  vim.api.nvim_create_user_command("LucaPreview", function()
    local patch = require("luca.patch")
    local history = require("luca.history").get_current()
    if history and #history > 0 then
      local last_entry = history[#history]
      if last_entry.assistant then
        patch.show_preview(last_entry.assistant)
      else
        vim.notify("No suggestion to preview", vim.log.levels.WARN)
      end
    else
      vim.notify("No history available", vim.log.levels.WARN)
    end
  end, { desc = "Preview last suggestion" })
  
  vim.api.nvim_create_user_command("LucaCommand", function()
    require("luca.commands").show_palette()
  end, { desc = "Show commands palette" })
  
  vim.api.nvim_create_user_command("LucaActions", function()
    require("luca.quick_actions").show_menu()
  end, { desc = "Show quick actions menu" })
  
  vim.api.nvim_create_user_command("LucaReview", function()
    require("luca.review").start_review()
  end, { desc = "Start code review" })
  
  vim.api.nvim_create_user_command("LucaHover", function()
    require("luca.inline").show_hover()
  end, { desc = "Show inline explanation" })
  
  vim.api.nvim_create_user_command("LucaMode", function(opts)
    if opts.args and opts.args ~= "" then
      require("luca.modes").set_mode(opts.args)
    else
      vim.notify("Current mode: " .. require("luca.modes").get_mode(), vim.log.levels.INFO)
    end
  end, { desc = "Set UI mode (floating/sidebar/minimal)", nargs = "?" })
  
  vim.api.nvim_create_user_command("LucaIndex", function()
    require("luca.embeddings").index_project()
  end, { desc = "Index project for embeddings" })
  
  -- Keymap for inline hover
  if config.keymaps.hover then
    vim.keymap.set("n", config.keymaps.hover, function()
      require("luca.inline").show_hover()
    end, { desc = "Show inline explanation" })
  end
  
  -- Visual mode keymap for inline chat
  vim.keymap.set("v", config.keymaps.hover or "<leader>lh", function()
    require("luca.inline").show_hover()
  end, { desc = "Explain selected code" })
  
  -- Setup keymaps
  if config.keymaps.open then
    vim.keymap.set("n", config.keymaps.open, function()
      require("luca.ui").toggle()  -- Toggle instead of just open
    end, { desc = "Toggle Luca chat" })
  end
end

function M.config()
  return config
end

return M

