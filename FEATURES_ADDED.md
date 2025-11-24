# New Features Added - Cursor-like Chat Experience

This document summarizes the new features added to luca-ai-nvim, inspired by the best features from:
- [ChatGPT.nvim](https://github.com/jackMort/ChatGPT.nvim)
- [Avante.nvim](https://github.com/yetone/avante.nvim)
- [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim)

## ✅ Implemented Features

### 1. Session Management
**Inspired by ChatGPT.nvim**

- Multiple chat sessions support
- Create new sessions with `<C-n>`
- Switch between sessions with `<C-p>`
- Each session maintains its own message history
- Session list shows message count and creation time

**Files:**
- `lua/luca/sessions.lua` - Session management module
- Integrated into `lua/luca/ui.lua` and `lua/luca/agent.lua`

### 2. Settings Window
**Inspired by ChatGPT.nvim**

- Toggle settings window with `<C-o>`
- Adjust temperature, max_tokens, top_p, model, and agent on the fly
- Settings persist during the session
- Interactive editing of all parameters

**Files:**
- `lua/luca/settings.lua` - Settings window module

### 3. Help Window
**Inspired by ChatGPT.nvim**

- Toggle help window with `<C-h>`
- Shows all available keybindings
- Context-aware help based on current mode

**Files:**
- `lua/luca/help.lua` - Help window module

### 4. Memory Files Support
**Inspired by CodeCompanion.nvim**

- Automatic loading of memory files:
  - `.cursor/rules`
  - `CLAUDE.md`
  - `.claude.md`
  - `.cursorrules`
- Memory files are automatically included in system context
- Provides project-specific rules and context to AI

**Files:**
- `lua/luca/memory.lua` - Memory files module
- Integrated into `lua/luca/agent.lua`

### 5. Quick Actions Menu
**Inspired by ChatGPT.nvim**

- Access via `:LucaActions` command
- Pre-built actions:
  - Grammar correction
  - Translation
  - Keyword extraction
  - Docstring generation
  - Unit test generation
  - Code optimization
  - Summarization
  - Bug fixing
  - Code explanation
  - Code readability analysis

**Files:**
- `lua/luca/quick_actions.lua` - Quick actions module

### 6. Enhanced AI Provider Support
**Inspired by CodeCompanion.nvim and Avante.nvim**

- **Anthropic Claude** support
  - Proper API format handling
  - Custom headers (x-api-key, anthropic-version)
- **Google Gemini** support (basic)
- **DeepSeek** support (OpenAI-compatible)
- **Ollama** support (already existed, improved)
- **OpenAI** support (already existed)

**Files:**
- Updated `lua/luca/agent.lua` with multi-provider support
- Updated `lua/luca/config.example.lua` with provider examples

## 🎯 Keybindings Summary

### Chat Window Keybindings
- `<C-Enter>` - Submit message
- `<C-y>` - Copy/yank last answer
- `<C-o>` - Toggle settings window
- `<C-h>` - Toggle help window
- `<C-c>` - Close chat window
- `<C-p>` - Toggle sessions list
- `<C-n>` - Start new session
- `<C-a>` - Switch agent
- `<Esc>` - Close window

## 📝 Usage Examples

### Using Sessions
```lua
-- In chat window, press <C-p> to see sessions list
-- Press <C-n> to create a new session
```

### Using Settings
```lua
-- In chat window, press <C-o> to open settings
-- Press Enter on any setting to edit it
```

### Using Quick Actions
```vim
:LucaActions
-- Select an action from the menu
```

### Memory Files
Create a `.cursor/rules` or `CLAUDE.md` file in your project root:
```markdown
# Project Rules

- Always use TypeScript strict mode
- Prefer functional programming
- Use descriptive variable names
```

The AI will automatically use these rules in all conversations.

## 🔄 Integration Points

All new features are integrated into the existing luca-ai-nvim architecture:

1. **Sessions** - Messages are stored per session, integrated with history system
2. **Settings** - Settings modify agent config on the fly
3. **Memory** - Memory files are loaded and added to system context automatically
4. **Quick Actions** - Actions use the existing agent.send_message API
5. **Providers** - New providers use the existing HTTP streaming infrastructure

## 🚀 Next Steps (Optional Future Enhancements)

- [ ] Edit window with side-by-side diff view (like ChatGPT.nvim)
- [ ] Better context management with file attachments
- [ ] ACP (Agent Client Protocol) support (from Avante.nvim)
- [ ] More provider-specific optimizations
- [ ] Session persistence across Neovim restarts

