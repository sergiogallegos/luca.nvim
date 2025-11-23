# How to Update luca.nvim Plugin

## The Issue
The error is from an old cached version. You need to update the plugin.

## Solution: Update the Plugin

### Option 1: Using Lazy.nvim (Recommended)

In Neovim, run:
```vim
:Lazy update luca.nvim
```

Or update all plugins:
```vim
:Lazy update
```

### Option 2: Force Reinstall

If the update doesn't work, force a clean reinstall:

```vim
:Lazy clean luca.nvim
:Lazy install luca.nvim
```

### Option 3: Manual Delete and Reinstall

1. Close Neovim
2. Delete the plugin directory:
   - Windows: `C:\Users\YourName\AppData\Local\nvim-data\lazy\luca.nvim`
   - Linux/Mac: `~/.local/share/nvim/lazy/luca.nvim`
3. Restart Neovim - it will reinstall automatically

### Option 4: Check Your Plugin Source

Make sure your config points to the correct repository:

```lua
{
  "sergiogallegos/luca.nvim",  -- Make sure this is correct
  -- ...
}
```

## Verify the Fix

After updating, the error should be gone. The fix replaces bitwise operators with Lua 5.1 compatible code.

## If Still Having Issues

1. Check the plugin version: `:Lazy logs luca.nvim`
2. Verify the file: The embeddings.lua should NOT have `<<` or `&` operators
3. Restart Neovim completely

