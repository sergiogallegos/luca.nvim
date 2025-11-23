# luca.nvim

A powerful AI assistant plugin for Neovim that brings Cursor-like chat functionality directly into your editor. Named after my son, luca provides an intelligent, context-aware coding assistant with a beautiful floating chat interface.

## Features

### Core Features
- 🎨 **Floating Chat Window** - Resizable, clean, non-intrusive chat interface
- 🤖 **Multiple Agents** - Choose from different AI models/agents with per-agent settings
- ⚡ **Streaming Output** - Real-time response streaming with smooth updates
- 📜 **History Navigation** - Browse and manage conversation history
- 🎯 **Context Awareness** - Understands your project structure and codebase

### Code Editing
- ✏️ **Edit Suggestions** - AI-powered code suggestions with patch application
- 🔍 **Diff Preview** - Review and accept/reject changes hunk-by-hunk
- 📁 **Multi-File Support** - Work across multiple files with context awareness
- 🔧 **File Operations** - Create, edit, refactor files directly from chat
- 🔄 **Edit by Instruction** - Natural language code editing

### Developer Workflow
- ⌨️ **Commands Palette** - Cursor-style "/" commands (/refactor, /explain, /test, /review, /doc)
- 🔍 **Code Review Mode** - AI reviews code with inline comments
- 💬 **Inline Chat (Hover)** - Highlight code and get instant explanations
- 🧪 **Test Generation** - AI generates unit tests, detects test framework
- 📝 **Documentation Generation** - Generate docstrings, README sections, comments

### Advanced Features
- 🌳 **LSP Integration** - AST info, symbols, type definitions, diagnostics
- 🔀 **Git Integration** - Commit changes, view diffs, review commits
- 🎨 **Theme Adaptation** - Automatic colorscheme matching (dark/light)
- 📊 **Statusline Integration** - Show current agent, model, and status
- 💾 **Caching** - Response and context caching for performance
- 🔢 **Token Management** - Smart context trimming and token limits
- 🔧 **Tooling API** - Function calling support for agents
- 📚 **Project Embeddings** - Vector store for large codebases

### UI Modes
- 🪟 **Floating Mode** - Default floating window
- 📑 **Sidebar Mode** - Persistent right-side panel
- 🔲 **Minimal Mode** - Tiny window for quick prompts

### Customization
- ⚙️ **Highly Customizable** - Configure everything to match your workflow
- 🎨 **Multiple Themes** - Support for rose-pine, tokyonight, catppuccin, nord
- ⌨️ **Custom Keymaps** - All actions are customizable

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/luca.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("luca").setup({
      -- Your configuration here
    })
  end,
}
```

## Configuration

```lua
require("luca").setup({
  -- Agent configuration
  agents = {
    default = "openai",
    providers = {
      openai = {
        api_key = os.getenv("OPENAI_API_KEY"), -- or set directly
        model = "gpt-4",
        base_url = "https://api.openai.com/v1",
        temperature = 0.7,        -- Optional: 0.0 to 2.0
        max_tokens = nil,        -- Optional: nil uses provider default
        top_p = 1.0,             -- Optional
        frequency_penalty = 0.0, -- Optional
        presence_penalty = 0.0,  -- Optional
      },
      -- Example: Local Ollama (no API key needed)
      ollama = {
        api_key = nil, -- Not needed for local Ollama
        model = "llama2", -- or "mistral", "codellama", "deepseek-coder", etc.
        base_url = "http://localhost:11434", -- Ollama default port
        requires_api_key = false,
        temperature = 0.7,
        num_predict = 2048, -- Ollama uses num_predict instead of max_tokens
      },
    },
  },
  
  -- UI configuration
  ui = {
    width = 0.6,
    height = 0.7,
    border = "rounded",
    position = "center",
    winblend = 10,
    title = " Luca ",
  },
  
  -- History configuration
  history = {
    enabled = true,
    max_entries = 100,
    storage_path = vim.fn.stdpath("data") .. "/luca_history.json",
  },
  
  -- Context configuration
  context = {
    include_buffer = true,
    include_tree = true,
    max_files = 10,
    auto_attach = true,
  },
  
  -- Keymaps
  keymaps = {
    open = "<leader>lc",
    close = "<Esc>",
    send = "<CR>",
    history_prev = "<C-p>",
    history_next = "<C-n>",
    apply_suggestion = "<C-a>",
    reject_suggestion = "<C-r>",
  },
})
```

See `lua/luca/config.example.lua` for a complete example configuration.

## Usage

### Commands

- `:LucaChat` - Open the chat window
- `:LucaHistory` - View chat history
- `:LucaAgent [name]` - Switch agent (or show selector if no name provided)
- `:LucaApply` - Apply the last code suggestion
- `:LucaPreview` - Preview the last code suggestion
- `:LucaCommand` - Show commands palette
- `:LucaReview` - Start code review of current file
- `:LucaHover` - Show inline explanation
- `:LucaMode [mode]` - Set UI mode (floating/sidebar/minimal)
- `:LucaIndex` - Index project for embeddings

### Command Palette (Cursor-style)

Type `/` followed by a command in the chat input:
- `/refactor` - Refactor selected code or current function
- `/explain` - Explain what the code does
- `/fix` - Fix bugs in the code
- `/optimize` - Optimize performance
- `/test` - Generate unit tests
- `/review` - Review code for best practices
- `/doc` - Generate documentation

### Keybindings

- `<leader>lc` - Open chat window
- `<C-a>` - Switch agent (in chat window) or apply suggestion (in preview)
- `<C-p>` / `<C-n>` - Navigate history
- `<C-r>` - Reject suggestion (in preview)
- `<Esc>` - Close chat window

### Features in Action

1. **Chat with AI**: Open chat, type your question, press Enter
2. **Streaming Responses**: See responses appear in real-time
3. **Apply Code**: When AI suggests code, use `:LucaApply` or `<C-a>` in preview
4. **Multi-file Support**: AI understands your project context automatically
5. **Agent Switching**: Press `<C-a>` in chat to switch between configured agents

## Requirements

- Neovim 0.9.0 or higher
- Lua 5.1 or higher
- `curl` command (for HTTP requests, or install `plenary.nvim` for better async support)
- API key for your chosen AI provider (OpenAI, Anthropic, etc.)

## Dependencies

The plugin works with minimal dependencies, but for better performance:

- `nvim-lua/plenary.nvim` (recommended) - Better async HTTP support
- `nvim-treesitter/nvim-treesitter` (optional) - Enhanced context understanding

## Supported AI Providers

Any OpenAI-compatible API endpoint:
- OpenAI
- Anthropic (Claude) - with compatible wrapper
- Local models via Ollama
- Any other OpenAI-compatible API

## Contributing

Contributions are welcome! This is an open-source project named after my son, and I'd love to see it grow.

## License

MIT