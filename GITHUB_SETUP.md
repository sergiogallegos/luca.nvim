# GitHub Repository Setup Guide

## Step 1: Create Repository on GitHub

1. Go to [GitHub.com](https://github.com) and sign in
2. Click the **"+"** icon in the top right corner
3. Select **"New repository"**
4. Fill in the details:
   - **Repository name**: `luca.nvim` (or `luca-ai-nvim`)
   - **Description**: "AI-powered coding assistant for Neovim - Cursor-like chat interface"
   - **Visibility**: Choose Public (recommended for open source) or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click **"Create repository"**

## Step 2: Prepare Your Local Repository

Run these commands in your project directory:

```bash
# Add all files to git
git add .

# Create initial commit
git commit -m "Initial commit: Complete luca.nvim plugin with all features"

# Add GitHub remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/luca.nvim.git

# Or if you prefer SSH:
# git remote add origin git@github.com:YOUR_USERNAME/luca.nvim.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 3: Verify

1. Go to your repository on GitHub
2. You should see all your files
3. The README.md should display automatically

## Optional: Add Repository Topics

On your GitHub repository page:
1. Click the gear icon (⚙️) next to "About"
2. Add topics: `neovim`, `lua`, `ai`, `chat`, `coding-assistant`, `cursor`, `vim-plugin`

## Optional: Create a Release

1. Go to "Releases" → "Create a new release"
2. Tag version: `v0.1.0`
3. Release title: `v0.1.0 - Initial Release`
4. Description: Copy from CHANGELOG.md
5. Publish release

## Quick Command Reference

```bash
# Check status
git status

# Add files
git add .

# Commit
git commit -m "Your commit message"

# Push
git push

# Pull (if working from multiple machines)
git pull
```

## For lazy.nvim Users

If someone wants to install your plugin, they can add to their config:

```lua
{
  "YOUR_USERNAME/luca.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("luca").setup({
      -- their config
    })
  end,
}
```

