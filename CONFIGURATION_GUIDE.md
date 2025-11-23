# Configuration Guide

## Where to Put Your Configuration

**The configuration goes in YOUR Neovim config, NOT in the plugin files!**

### Plugin Files (Don't Edit These)
- `lua/luca/config.example.lua` - This is just an example
- All files in `lua/luca/` - These are plugin code, not your config

### Your Neovim Config (Edit This)
- `~/.config/nvim/init.lua` - Main config file
- `~/.config/nvim/lua/plugins/` - If using lazy.nvim
- `~/.config/nvim/lua/config/` - If organizing by category

## Setup Examples

### For lazy.nvim Users

Create or edit: `~/.config/nvim/lua/plugins/luca.lua`

```lua
return {
  "sergiogallegos/luca.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("luca").setup({
      agents = {
        default = "ollama",
        providers = {
          ollama = {
            api_key = nil,
            model = "deepseek-r1:8b",
            base_url = "http://localhost:11434",
            requires_api_key = false,
            temperature = 0.7,
            num_predict = 2048,
          },
        },
      },
    })
  end,
}
```

### For packer.nvim Users

In your `plugins.lua`:

```lua
use {
  "sergiogallegos/luca.nvim",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    require("luca").setup({
      -- your config here
    })
  end,
}
```

### For vim-plug Users

In your `init.vim` or `init.lua`:

```vim
Plug 'sergiogallegos/luca.nvim'
Plug 'nvim-lua/plenary.nvim'

lua << EOF
require("luca").setup({
  -- your config here
})
EOF
```

### Minimal Config (Just Works)

If you want to use defaults, you can just do:

```lua
require("luca").setup({})
```

But you'll need to configure at least one agent:

```lua
require("luca").setup({
  agents = {
    default = "ollama",
    providers = {
      ollama = {
        model = "deepseek-r1:8b",
        base_url = "http://localhost:11434",
        requires_api_key = false,
      },
    },
  },
})
```

## Quick Reference

### Your Config Location
- **Windows**: `C:\Users\YourName\AppData\Local\nvim\init.lua`
- **Linux/Mac**: `~/.config/nvim/init.lua`

### Plugin Location (Don't Edit)
- Installed by plugin manager to: `~/.local/share/nvim/lazy/luca.nvim/` (lazy.nvim)
- Or: `~/.local/share/nvim/plugged/luca.nvim/` (vim-plug)

## Summary

✅ **DO**: Edit your Neovim config file  
❌ **DON'T**: Edit files in the plugin directory

The plugin files are examples and documentation. Your actual configuration lives in your Neovim config directory.

