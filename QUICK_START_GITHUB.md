# Quick Start: Push to GitHub

## ✅ Files are already staged and committed!

## Next Steps:

### 1. Create Repository on GitHub

1. Go to https://github.com/new
2. Repository name: `luca.nvim` (or `luca-ai-nvim`)
3. Description: `AI-powered coding assistant for Neovim - Cursor-like chat interface`
4. Choose Public or Private
5. **DO NOT** check any boxes (README, .gitignore, license)
6. Click **"Create repository"**

### 2. Connect and Push

After creating the repository, GitHub will show you commands. Use these:

```bash
# Add your GitHub repository as remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/luca.nvim.git

# Rename branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main
```

### 3. Alternative: Using GitHub CLI (if installed)

```bash
# Create repo and push in one command
gh repo create luca.nvim --public --source=. --remote=origin --push
```

## That's it! 🎉

Your repository will be live on GitHub with all the code!

## After Pushing:

1. **Add Topics**: On your repo page, click the gear icon next to "About" and add:
   - `neovim`
   - `lua`
   - `ai`
   - `chat`
   - `coding-assistant`
   - `vim-plugin`

2. **Create Release** (optional):
   - Go to Releases → Create a new release
   - Tag: `v0.1.0`
   - Title: `v0.1.0 - Initial Release`
   - Description: See CHANGELOG.md

3. **Share**: People can install with:
   ```lua
   {
     "YOUR_USERNAME/luca.nvim",
     dependencies = { "nvim-lua/plenary.nvim" },
     config = function()
       require("luca").setup({})
     end,
   }
   ```

