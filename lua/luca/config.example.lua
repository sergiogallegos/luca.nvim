-- Example configuration for luca.nvim
-- Copy this to your Neovim config and customize as needed

return {
  -- Agent configuration
  agents = {
    default = "openai",
    providers = {
      openai = {
        api_key = os.getenv("OPENAI_API_KEY"), -- or set directly: "sk-..."
        model = "gpt-4",
        base_url = "https://api.openai.com/v1",
      },
      -- Example: Anthropic Claude
      -- claude = {
      --   api_key = os.getenv("ANTHROPIC_API_KEY"),
      --   model = "claude-3-opus-20240229",
      --   base_url = "https://api.anthropic.com/v1",
      -- },
      -- Example: Local Ollama
      ollama = {
        api_key = nil, -- Not needed for local Ollama
        model = "llama2", -- or "mistral", "codellama", "deepseek-coder", etc.
        base_url = "http://localhost:11434", -- Ollama default port
        requires_api_key = false, -- Ollama doesn't need API key
        temperature = 0.7,
        num_predict = 2048, -- Ollama uses num_predict instead of max_tokens
      },
    },
  },
  
  -- UI configuration
  ui = {
    width = 0.6,        -- Width as fraction of screen (0.0 to 1.0)
    height = 0.7,       -- Height as fraction of screen (0.0 to 1.0)
    border = "rounded", -- Border style: "single", "double", "rounded", "solid", "shadow", or table
    position = "center", -- Window position: "center", "top", "bottom"
    winblend = 10,      -- Window transparency (0-100)
    title = " Luca ",   -- Window title
  },
  
  -- History configuration
  history = {
    enabled = true,
    max_entries = 100,
    storage_path = vim.fn.stdpath("data") .. "/luca_history.json",
  },
  
  -- Context configuration
  context = {
    include_buffer = true,  -- Include current buffer content
    include_tree = true,    -- Include project files
    max_files = 10,         -- Maximum number of project files to include
    auto_attach = true,     -- Automatically attach context to messages
  },
  
  -- Keymaps
  keymaps = {
    open = "<leader>lc",        -- Open chat window
    close = "<Esc>",            -- Close chat window
    send = "<CR>",              -- Send message (in input buffer)
    history_prev = "<C-p>",     -- Navigate to previous history entry
    history_next = "<C-n>",     -- Navigate to next history entry
    apply_suggestion = "<C-a>", -- Apply code suggestion
    reject_suggestion = "<C-r>", -- Reject code suggestion
  },
}

