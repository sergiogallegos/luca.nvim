# Quick Ollama Configuration

## For Your Model: `deepseek-r1:8b`

Since you have `deepseek-r1:8b` installed, here's your ready-to-use config:

```lua
require("luca").setup({
  agents = {
    default = "ollama", -- Use Ollama by default
    providers = {
      ollama = {
        api_key = nil,
        model = "deepseek-r1:8b", -- Your installed model
        base_url = "http://localhost:11434",
        requires_api_key = false,
        temperature = 0.7,
        num_predict = 2048,
      },
    },
  },
})
```

## Quick Start

1. **Add the config above** to your Neovim config
2. **Restart Neovim** or run `:lua require("luca").setup({...})`
3. **Open chat**: `:LucaChat` or `<leader>lc`
4. **Start chatting** - It will use your `deepseek-r1:8b` model!

## Switch Between Models

If you install more models, you can add them:

```lua
require("luca").setup({
  agents = {
    default = "deepseek",
    providers = {
      deepseek = {
        api_key = nil,
        model = "deepseek-r1:8b",
        base_url = "http://localhost:11434",
        requires_api_key = false,
        temperature = 0.7,
        num_predict = 2048,
      },
      codellama = {
        api_key = nil,
        model = "codellama",
        base_url = "http://localhost:11434",
        requires_api_key = false,
        temperature = 0.5, -- Lower for code
        num_predict = 4096,
      },
    },
  },
})
```

Then switch with: `:LucaAgent deepseek` or `:LucaAgent codellama`

## Verify It's Working

1. Make sure Ollama is running: `ollama list` should show your models
2. Test in chat: Ask "Hello, what model are you?"
3. Check statusline: Should show "ollama" or your agent name

## Troubleshooting

**Model not found?**
- Verify exact name: `ollama list`
- Use the exact name including tags (e.g., `:8b`)

**Connection error?**
- Check Ollama is running: `ollama serve`
- Verify port: Default is `11434`

**Slow responses?**
- `deepseek-r1:8b` is a good size, but you can:
  - Reduce `num_predict` for faster responses
  - Lower `temperature` for more focused answers

