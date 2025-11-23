# Ollama Setup Guide for luca.nvim

## Prerequisites

1. Install Ollama from https://ollama.ai
2. Pull a model (e.g., `ollama pull llama2` or `ollama pull codellama`)

## Configuration

Add Ollama to your luca.nvim configuration:

```lua
require("luca").setup({
  agents = {
    default = "ollama", -- Set Ollama as default
    providers = {
      ollama = {
        api_key = nil, -- Not needed for local Ollama
        model = "deepseek-r1:8b", -- Use exact model name from 'ollama list'
        base_url = "http://localhost:11434", -- Default Ollama port
        requires_api_key = false, -- Important: set to false
        temperature = 0.7,
        num_predict = 2048, -- Ollama uses num_predict instead of max_tokens
      },
    },
  },
})
```

**Note**: Use the exact model name as shown in `ollama list`. For example:
- `deepseek-r1:8b` (your current model)
- `llama2`
- `codellama`
- `mistral`
- Include the tag/version if present (e.g., `:8b`, `:7b`, `:13b`)

## Available Models

Popular coding models for Ollama:
- `deepseek-r1:8b` - DeepSeek R1 model (8B parameters) - **You have this!**
- `codellama` - Code-focused Llama model
- `deepseek-coder` - Strong coding capabilities
- `mistral` - General purpose, good for code
- `llama2` - General purpose
- `phi` - Small, fast model

Check your installed models:
```bash
ollama list
```

Pull a new model:
```bash
ollama pull codellama
```

**Important**: Use the exact model name from `ollama list`, including any tags (like `:8b`, `:7b`, etc.)

## Usage

1. Make sure Ollama is running: `ollama serve` (usually runs automatically)
2. Open luca chat: `:LucaChat` or `<leader>lc`
3. Switch to Ollama agent: `:LucaAgent ollama` or press `<C-a>` in chat

## Troubleshooting

### Connection Issues
- Ensure Ollama is running: `ollama list` should show your models
- Check the port: Default is `11434`, change `base_url` if different
- Test connection: `curl http://localhost:11434/api/tags`

### Model Not Found
- Pull the model: `ollama pull MODEL_NAME`
- Check available models: `ollama list`
- Verify model name matches exactly in config

### Slow Responses
- Try a smaller model (e.g., `phi` instead of `llama2`)
- Reduce `num_predict` value
- Ensure Ollama has enough resources allocated

## Example Configuration with Multiple Models

```lua
require("luca").setup({
  agents = {
    default = "codellama",
    providers = {
      codellama = {
        api_key = nil,
        model = "codellama",
        base_url = "http://localhost:11434",
        requires_api_key = false,
        temperature = 0.3, -- Lower for more focused code
        num_predict = 4096,
      },
      mistral = {
        api_key = nil,
        model = "mistral",
        base_url = "http://localhost:11434",
        requires_api_key = false,
        temperature = 0.7,
        num_predict = 2048,
      },
    },
  },
})
```

## Benefits of Using Ollama

- ✅ **Free** - No API costs
- ✅ **Private** - All data stays local
- ✅ **Fast** - No network latency
- ✅ **Offline** - Works without internet
- ✅ **Customizable** - Full control over models and parameters

